import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../models/data_models/ai_tool.dart';
import '../../models/data_models/edit_operation.dart';
import '../../services/image_pipeline.dart';
import 'ai_failure.dart';
import 'ai_job.dart';
import 'ai_service.dart';

/// Stands in for the backend.
///
/// Two jobs, and it is worth being clear which is which:
///
/// * With `configured: false` — the default the app falls back to when no
///   endpoint was built in — every run fails with [AiFailureCode.notConfigured].
///   That is the honest state for a build that has no backend, and it is what
///   makes the UI say so rather than spin and then fail obscurely.
///
/// * With `configured: true` it walks the full status sequence and returns a
///   locally processed image, so the whole flow — gating, progress, apply,
///   discard, undo — is testable and clickable without a server. Results are
///   flagged [AiJob.isSimulated] and the UI labels them: a stand-in that
///   passed itself off as a real model would be worse than no stand-in.
class FakeAiService implements AiService {
  FakeAiService({
    bool configured = true,
    this.step = const Duration(milliseconds: 10),
    this.failWith,
  }) : _configured = configured;

  final bool _configured;

  /// Time spent in each status, so tests can run instantly.
  final Duration step;

  /// Forces every run to fail this way, for exercising the error paths.
  final AiFailureCode? failWith;

  final List<AiRunRequest> requests = [];
  final Set<String> _cancelled = {};

  int _counter = 0;

  @override
  bool get isConfigured => _configured;

  @override
  Stream<AiJob> run(AiRunRequest request) async* {
    requests.add(request);
    final tool = request.tool;
    final id = 'fake_${++_counter}';

    var job = AiJob(id: id, tool: tool, status: AiJobStatus.uploading);

    if (!_configured) {
      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.notConfigured),
      );
      return;
    }
    if (failWith != null) {
      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: AiFailure(failWith!),
      );
      return;
    }
    if (tool.needsPrompt && (request.prompt?.trim().isEmpty ?? true)) {
      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.promptRequired),
      );
      return;
    }

    yield job;

    for (final status in [
      AiJobStatus.queued,
      AiJobStatus.running,
      AiJobStatus.downloading,
    ]) {
      await Future<void>.delayed(step);
      if (_cancelled.remove(id)) {
        yield job.copyWith(status: AiJobStatus.cancelled);
        return;
      }
      job = job.copyWith(status: status);
      yield job;
    }

    try {
      final bytes = await File(request.imagePath).readAsBytes();
      yield job.copyWith(
        status: AiJobStatus.succeeded,
        result: await _simulate(tool, bytes),
        creditsCharged: tool.credits,
        isSimulated: true,
      );
    } on ImagePipelineFailure {
      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: const AiFailure(AiFailureCode.unsupportedImage),
      );
    } catch (error) {
      yield job.copyWith(
        status: AiJobStatus.failed,
        failure: AiFailure(AiFailureCode.unknown, detail: '$error'),
      );
    }
  }

  /// A visibly different image, produced locally. It is not what the real
  /// model would return and does not pretend to be — it exists so the rest of
  /// the flow has something real to carry.
  Future<Uint8List> _simulate(AiTool tool, Uint8List bytes) async {
    final auto = await ImagePipeline.autoAdjust(bytes);
    return ImagePipeline.render(RenderRequest(
      bytes: bytes,
      state: EditState(
        adjust: auto.copyWith(sharpness: tool.id == AiTools.enhance.id ? 40 : 15),
      ),
    ));
  }

  @override
  Future<void> cancel(String jobId) async => _cancelled.add(jobId);
}
