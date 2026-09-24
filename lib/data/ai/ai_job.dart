import 'dart:typed_data';

import '../../models/data_models/ai_tool.dart';
import 'ai_failure.dart';

enum AiJobStatus {
  /// Sending the photo up.
  uploading,

  /// Accepted, waiting for a worker.
  queued,

  /// The model is working.
  running,

  /// Pulling the finished image back down.
  downloading,

  succeeded,
  failed,
  cancelled,
}

/// One run of one tool. Immutable: each status change produces a new value, so
/// the controller can hold the latest and the UI rebuilds off it.
class AiJob {
  const AiJob({
    required this.id,
    required this.tool,
    required this.status,
    this.progress,
    this.result,
    this.failure,
    this.creditsCharged = 0,
    this.isSimulated = false,
  });

  final String id;
  final AiTool tool;
  final AiJobStatus status;

  /// 0..1 when the server reports it, null when it only reports a phase.
  final double? progress;

  /// The finished image. Only set on [AiJobStatus.succeeded].
  final Uint8List? result;

  final AiFailure? failure;

  /// What the server actually charged. Read back rather than assumed: the
  /// client never decides what a run costs.
  final int creditsCharged;

  /// True when this came from the local stand-in rather than a real model, so
  /// the UI can say so instead of passing it off as an AI result.
  final bool isSimulated;

  bool get isTerminal => switch (status) {
        AiJobStatus.succeeded || AiJobStatus.failed || AiJobStatus.cancelled => true,
        _ => false,
      };

  bool get isRunning => !isTerminal;

  /// What to show while it works. The server's queue position is not something
  /// a user can act on, so the phases are named for what is happening to their
  /// photo instead.
  String get statusLabel => switch (status) {
        AiJobStatus.uploading => 'Uploading your photo',
        AiJobStatus.queued => 'Waiting for a slot',
        AiJobStatus.running => 'Working on it',
        AiJobStatus.downloading => 'Bringing it back',
        AiJobStatus.succeeded => 'Done',
        AiJobStatus.failed => 'Failed',
        AiJobStatus.cancelled => 'Cancelled',
      };

  AiJob copyWith({
    AiJobStatus? status,
    double? progress,
    Uint8List? result,
    AiFailure? failure,
    int? creditsCharged,
    bool? isSimulated,
  }) =>
      AiJob(
        id: id,
        tool: tool,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        result: result ?? this.result,
        failure: failure ?? this.failure,
        creditsCharged: creditsCharged ?? this.creditsCharged,
        isSimulated: isSimulated ?? this.isSimulated,
      );

  @override
  String toString() => 'AiJob($id, ${tool.id}, ${status.name})';
}

/// Everything one run needs. Plain data so it is easy to log and to test.
class AiRunRequest {
  const AiRunRequest({
    required this.tool,
    required this.imagePath,
    this.prompt,
  });

  final AiTool tool;
  final String imagePath;
  final String? prompt;
}
