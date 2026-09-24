import 'ai_job.dart';

/// The app's whole view of cloud AI.
///
/// Note what is *not* here: no provider name, no API key, no model id. Spec 25
/// keeps the Replicate and remove.bg credentials server-side, so the app talks
/// only to our own backend and cannot leak a key even if the binary is pulled
/// apart. Swapping provider is then a server change, not an app release.
abstract class AiService {
  /// False when this build has no backend endpoint. The UI asks first and says
  /// so plainly, rather than letting every run fail the same way.
  bool get isConfigured;

  /// Runs one tool, emitting each status change and finally a terminal job.
  /// Always completes with a terminal [AiJob] rather than throwing, so a
  /// failure is a state the UI renders and not an exception it must catch in
  /// two places.
  Stream<AiJob> run(AiRunRequest request);

  /// Best-effort: the server may already have charged for a job that is too
  /// far along to stop.
  Future<void> cancel(String jobId);
}
