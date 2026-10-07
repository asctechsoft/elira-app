import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../values/ai_config.dart';
import '../auth/auth_service.dart';
import 'ai_failure.dart';
import 'ai_job.dart';
import 'ai_service.dart';

/// Talks to our own backend, which in turn talks to Replicate and remove.bg.
///
/// This file is the contract the server has to satisfy:
///
/// ```
/// POST   {base}/v1/jobs              multipart: tool, prompt?, image
///        -> 202 {"jobId","status","credits"}
/// GET    {base}/v1/jobs/{jobId}
///        -> 200 {"status","progress"?,"resultUrl"?,"error"?,"credits"?}
/// POST   {base}/v1/jobs/{jobId}/cancel
///        -> 204
/// ```
///
/// Every call carries `Authorization: Bearer <firebase id token>`. The server
/// charges credits inside the same transaction that accepts the job, and
/// returns the finished image as a **short-lived signed URL** (spec 25) rather
/// than a permanent public one.
class EliraAiService implements AiService {
  EliraAiService({
    required AuthService auth,
    http.Client? client,
    String endpoint = AiConfig.endpoint,
  })  : _auth = auth,
        _client = client ?? http.Client(),
        _endpoint = endpoint;

  final AuthService _auth;
  final http.Client _client;
  final String _endpoint;

  final Set<String> _cancelled = {};

  @override
  bool get isConfigured => _endpoint.isNotEmpty;

  @override
  Stream<AiJob> run(AiRunRequest request) async* {
    final tool = request.tool;
    final placeholder = AiJob(
      id: 'pending',
      tool: tool,
      status: AiJobStatus.uploading,
    );

    if (!isConfigured) {
      yield placeholder.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.notConfigured),
      );
      return;
    }

    if (tool.needsPrompt && (request.prompt?.trim().isEmpty ?? true)) {
      yield placeholder.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.promptRequired),
      );
      return;
    }

    yield placeholder;

    try {
      final file = File(request.imagePath);
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > AiConfig.maxUploadBytes) {
        yield placeholder.copyWith(
          status: AiJobStatus.failed,
          failure: const AiFailure(AiFailureCode.tooLarge),
        );
        return;
      }

      final token = await _auth.idToken();
      if (token == null) {
        yield placeholder.copyWith(
          status: AiJobStatus.failed,
          failure: const AiFailure(AiFailureCode.unauthorized),
        );
        return;
      }

      final submitted = await _submit(request, bytes, token);
      // The real id only exists once the server has accepted and charged, so
      // the job gets its identity here rather than at the placeholder.
      var job = AiJob(
        id: submitted.jobId,
        tool: tool,
        status: AiJobStatus.queued,
        creditsCharged: submitted.credits,
      );
      yield job;

      final deadline = DateTime.now().add(AiConfig.jobTimeout);
      while (DateTime.now().isBefore(deadline)) {
        if (_cancelled.remove(job.id)) {
          yield job.copyWith(status: AiJobStatus.cancelled);
          return;
        }

        await Future<void>.delayed(AiConfig.pollInterval);
        final snapshot = await _status(job.id, token);

        if (snapshot.error != null) {
          yield job.copyWith(
            status: AiJobStatus.failed,
            failure: AiFailure(AiFailure.codeFromString(snapshot.error)),
          );
          return;
        }

        job = job.copyWith(
          status: snapshot.status,
          progress: snapshot.progress,
          creditsCharged: snapshot.credits ?? job.creditsCharged,
        );

        if (snapshot.status == AiJobStatus.succeeded) {
          final url = snapshot.resultUrl;
          if (url == null) {
            yield job.copyWith(
              status: AiJobStatus.failed,
              failure: const AiFailure(
                AiFailureCode.serverError,
                detail: 'succeeded without a resultUrl',
              ),
            );
            return;
          }
          yield job.copyWith(status: AiJobStatus.downloading);
          final result = await _download(url);
          yield job.copyWith(status: AiJobStatus.succeeded, result: result);
          return;
        }

        if (job.isTerminal) {
          yield job;
          return;
        }
        yield job;
      }

      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.timeout),
      );
    } on AiFailure catch (failure) {
      yield placeholder.copyWith(status: AiJobStatus.failed, failure: failure);
    } on SocketException catch (error) {
      yield placeholder.copyWith(
        status: AiJobStatus.failed,
        failure: AiFailure(AiFailureCode.network, detail: '$error'),
      );
    } on TimeoutException {
      yield placeholder.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.timeout),
      );
    } catch (error) {
      debugPrint('[ai] run failed: $error');
      yield placeholder.copyWith(
        status: AiJobStatus.failed,
        failure: AiFailure(AiFailureCode.unknown, detail: '$error'),
      );
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    _cancelled.add(jobId);
    if (!isConfigured || jobId == 'pending') return;
    try {
      final token = await _auth.idToken();
      if (token == null) return;
      await _client
          .post(
            Uri.parse('$_endpoint/v1/jobs/$jobId/cancel'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AiConfig.requestTimeout);
    } catch (error) {
      // Cancelling is best-effort: the local flag above already stops us
      // waiting, and the server will reconcile its own charge.
      debugPrint('[ai] cancel failed: $error');
    }
  }

  Future<_Submitted> _submit(
    AiRunRequest request,
    Uint8List bytes,
    String token,
  ) async {
    final multipart = http.MultipartRequest(
      'POST',
      Uri.parse('$_endpoint/v1/jobs'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['tool'] = request.tool.id
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'source.jpg',
      ));
    if (request.prompt != null) multipart.fields['prompt'] = request.prompt!;

    final streamed =
        await _client.send(multipart).timeout(AiConfig.requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      throw AiFailure(
        _codeFor(response),
        detail: 'POST /v1/jobs -> ${response.statusCode}',
      );
    }

    final body = _json(response.body);
    final jobId = body['jobId']?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw const AiFailure(AiFailureCode.serverError, detail: 'no jobId');
    }
    return _Submitted(jobId: jobId, credits: _asInt(body['credits']));
  }

  Future<_Snapshot> _status(String jobId, String token) async {
    final response = await _client
        .get(
          Uri.parse('$_endpoint/v1/jobs/$jobId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(AiConfig.requestTimeout);

    if (response.statusCode >= 400) {
      throw AiFailure(
        _codeFor(response),
        detail: 'GET /v1/jobs/$jobId -> ${response.statusCode}',
      );
    }

    final body = _json(response.body);
    return _Snapshot(
      status: _statusFrom(body['status']?.toString()),
      progress: body['progress'] is num
          ? (body['progress'] as num).toDouble().clamp(0.0, 1.0)
          : null,
      resultUrl: body['resultUrl']?.toString(),
      error: body['error']?.toString(),
      credits: body['credits'] is num ? (body['credits'] as num).toInt() : null,
    );
  }

  Future<Uint8List> _download(String url) async {
    final response =
        await _client.get(Uri.parse(url)).timeout(AiConfig.jobTimeout);
    if (response.statusCode >= 400) {
      throw AiFailure(
        _codeFor(response),
        detail: 'result download -> ${response.statusCode}',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw const AiFailure(AiFailureCode.serverError, detail: 'empty result');
    }
    return response.bodyBytes;
  }

  /// Prefers the body's own error string, which is more specific than the
  /// status code alone, and falls back to the status.
  static AiFailureCode _codeFor(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) {
        return AiFailure.codeFromString(body['error'] as String);
      }
    } catch (_) {
      // Not JSON; the status code is all we have.
    }
    return AiFailure.codeFromStatus(response.statusCode);
  }

  static Map<String, dynamic> _json(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      // Fall through to the failure below.
    }
    throw const AiFailure(AiFailureCode.serverError, detail: 'malformed body');
  }

  static AiJobStatus _statusFrom(String? value) => switch (value) {
        'queued' => AiJobStatus.queued,
        'running' || 'processing' => AiJobStatus.running,
        'succeeded' || 'completed' => AiJobStatus.succeeded,
        'cancelled' || 'canceled' => AiJobStatus.cancelled,
        'failed' || 'error' => AiJobStatus.failed,
        _ => AiJobStatus.running,
      };

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;
}

class _Submitted {
  const _Submitted({required this.jobId, required this.credits});

  final String jobId;
  final int credits;
}

class _Snapshot {
  const _Snapshot({
    required this.status,
    this.progress,
    this.resultUrl,
    this.error,
    this.credits,
  });

  final AiJobStatus status;
  final double? progress;
  final String? resultUrl;
  final String? error;
  final int? credits;
}
