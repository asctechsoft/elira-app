import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:elira/data/ai/ai_failure.dart';
import 'package:elira/data/ai/ai_job.dart';
import 'package:elira/data/ai/elira_ai_service.dart';
import 'package:elira/data/ai/fake_ai_service.dart';
import 'package:elira/data/auth/auth_user.dart';
import 'package:elira/data/auth/fake_auth_service.dart';
import 'package:elira/models/data_models/ai_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

Uint8List _jpeg({int shade = 90}) {
  final image = img.Image(width: 40, height: 40);
  img.fill(image, color: img.ColorRgb8(shade, shade, shade));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

const _user = AuthUser(uid: 'u1', email: 'a@b.com', isAnonymous: false);

void main() {
  late Directory tmp;
  late File source;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('elira_ai_test');
    source = File('${tmp.path}${Platform.pathSeparator}src.jpg');
    await source.writeAsBytes(_jpeg());
  });

  tearDown(() async {
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  AiRunRequest request(AiTool tool, {String? prompt}) =>
      AiRunRequest(tool: tool, imagePath: source.path, prompt: prompt);

  group('AiFailure', () {
    test('maps the status codes that mean something specific', () {
      expect(AiFailure.codeFromStatus(401), AiFailureCode.unauthorized);
      expect(AiFailure.codeFromStatus(402), AiFailureCode.insufficientCredits);
      expect(AiFailure.codeFromStatus(413), AiFailureCode.tooLarge);
      expect(AiFailure.codeFromStatus(429), AiFailureCode.quotaExceeded);
      expect(AiFailure.codeFromStatus(503), AiFailureCode.serverError);
    });

    test('only offers retry where retrying could actually work', () {
      expect(const AiFailure(AiFailureCode.network).isRetryable, isTrue);
      expect(const AiFailure(AiFailureCode.serverError).isRetryable, isTrue);
      expect(const AiFailure(AiFailureCode.insufficientCredits).isRetryable, isFalse);
      expect(const AiFailure(AiFailureCode.unsupportedImage).isRetryable, isFalse);
      expect(const AiFailure(AiFailureCode.notConfigured).isRetryable, isFalse);
    });

    test('flags the one failure the user can fix by buying credits', () {
      expect(const AiFailure(AiFailureCode.insufficientCredits).needsCredits, isTrue);
      expect(const AiFailure(AiFailureCode.network).needsCredits, isFalse);
    });
  });

  group('tool catalogue', () {
    test('ids are unique, because they are sent to the server', () {
      final ids = AiTools.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every tool has a price', () {
      for (final tool in AiTools.all) {
        expect(tool.credits, greaterThan(0), reason: tool.id);
      }
    });

    test('an unknown id resolves to null rather than throwing', () {
      expect(AiTools.byId('nope'), isNull);
      expect(AiTools.byId('remove_bg'), AiTools.removeBackground);
    });

    test('only the generative tools ask for a prompt', () {
      expect(AiTools.expand.needsPrompt, isTrue);
      expect(AiTools.replace.needsPrompt, isTrue);
      expect(AiTools.enhance.needsPrompt, isFalse);
    });
  });

  group('FakeAiService', () {
    test('an unconfigured build fails every run, immediately and clearly',
        () async {
      final service = FakeAiService(configured: false);
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.notConfigured);
    });

    test('walks the full status sequence and returns an image', () async {
      final service = FakeAiService();
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(
        jobs.map((j) => j.status),
        containsAllInOrder([
          AiJobStatus.uploading,
          AiJobStatus.queued,
          AiJobStatus.running,
          AiJobStatus.succeeded,
        ]),
      );
      expect(jobs.last.result, isNotNull);
      expect(jobs.last.creditsCharged, AiTools.enhance.credits);
    });

    test('marks its results as simulated so the UI cannot pass them off',
        () async {
      final jobs = await FakeAiService().run(request(AiTools.enhance)).toList();
      expect(jobs.last.isSimulated, isTrue);
    });

    test('refuses a prompt tool with no prompt', () async {
      final jobs = await FakeAiService().run(request(AiTools.expand)).toList();

      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.promptRequired);
    });

    test('accepts a prompt tool with one', () async {
      final jobs = await FakeAiService()
          .run(request(AiTools.expand, prompt: 'a wide beach'))
          .toList();
      expect(jobs.last.status, AiJobStatus.succeeded);
    });

    test('a corrupt file fails as an unsupported image, not a crash', () async {
      await source.writeAsBytes(Uint8List.fromList([1, 2, 3]));
      final jobs = await FakeAiService().run(request(AiTools.enhance)).toList();

      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.unsupportedImage);
    });

    test('can be told to fail, for exercising the error paths', () async {
      final service = FakeAiService(failWith: AiFailureCode.quotaExceeded);
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.failure?.code, AiFailureCode.quotaExceeded);
    });
  });

  group('EliraAiService', () {
    FakeAuthService auth() => FakeAuthService(seededUser: _user);

    test('reports itself unconfigured when no endpoint was built in', () {
      final service = EliraAiService(auth: auth(), endpoint: '');
      expect(service.isConfigured, isFalse);
    });

    test('sends the bearer token and the tool id, never a provider key',
        () async {
      late http.BaseRequest captured;
      final client = MockClient.streaming((request, _) async {
        captured = request;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"jobId":"j1","credits":4}')),
          202,
        );
      });

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      // Only the first two events are needed: submit has happened by then.
      await service.run(request(AiTools.enhance)).take(2).toList();

      expect(captured.headers['Authorization'], 'Bearer fake-token-u1');
      expect(captured.url.toString(), 'https://api.test/v1/jobs');
      final body = captured.headers.toString() + captured.url.toString();
      expect(body.toLowerCase(), isNot(contains('replicate')));
      expect(body.toLowerCase(), isNot(contains('api-key')));
    });

    test('a 402 becomes insufficient credits', () async {
      final client = MockClient.streaming((request, _) async =>
          http.StreamedResponse(Stream.value(utf8.encode('{}')), 402));

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.insufficientCredits);
    });

    test("the body's own error wins over the status code", () async {
      final client = MockClient.streaming((request, _) async =>
          http.StreamedResponse(
              Stream.value(utf8.encode('{"error":"unsupported_image"}')), 400));

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.failure?.code, AiFailureCode.unsupportedImage);
    });

    test('refuses to run when signed out rather than calling the server',
        () async {
      var called = false;
      final client = MockClient.streaming((request, _) async {
        called = true;
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      });

      final service = EliraAiService(
        auth: FakeAuthService(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.failure?.code, AiFailureCode.unauthorized);
      expect(called, isFalse);
    });

    test('a succeeded job with no resultUrl is a server error, not a success',
        () async {
      var polls = 0;
      final client = MockClient.streaming((request, _) async {
        if (request.method == 'POST') {
          return http.StreamedResponse(
              Stream.value(utf8.encode('{"jobId":"j1","credits":4}')), 202);
        }
        polls++;
        return http.StreamedResponse(
            Stream.value(utf8.encode('{"status":"succeeded"}')), 200);
      });

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(polls, greaterThan(0));
      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.serverError);
    });

    test('downloads the result from the signed url the server hands back',
        () async {
      final resultBytes = _jpeg(shade: 200);
      final client = MockClient.streaming((request, _) async {
        if (request.method == 'POST') {
          return http.StreamedResponse(
              Stream.value(utf8.encode('{"jobId":"j1","credits":4}')), 202);
        }
        if (request.url.toString().contains('/v1/jobs/j1')) {
          return http.StreamedResponse(
            Stream.value(utf8.encode(
                '{"status":"succeeded","resultUrl":"https://signed.test/r.jpg"}')),
            200,
          );
        }
        return http.StreamedResponse(Stream.value(resultBytes), 200);
      });

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.status, AiJobStatus.succeeded);
      expect(jobs.last.result, resultBytes);
      expect(jobs.last.isSimulated, isFalse);
    });

    test('a malformed body fails cleanly instead of throwing', () async {
      final client = MockClient.streaming((request, _) async =>
          http.StreamedResponse(Stream.value(utf8.encode('not json')), 202));

      final service = EliraAiService(
        auth: auth(),
        client: client,
        endpoint: 'https://api.test',
      );
      final jobs = await service.run(request(AiTools.enhance)).toList();

      expect(jobs.last.status, AiJobStatus.failed);
      expect(jobs.last.failure?.code, AiFailureCode.serverError);
    });
  });
}
