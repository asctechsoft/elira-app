import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/ai/ai_failure.dart';
import '../data/ai/ai_job.dart';
import '../data/ai/ai_service.dart';
import '../models/data_models/ai_tool.dart';
import '../values/feature_flags.dart';
import 'auth_controller.dart';

/// Owns AI runs and the credit balance they spend.
///
/// The balance is **read** from the user's Firestore profile and never written
/// here. `firestore.rules` makes `credits` server-write-only on purpose: a
/// client that can decrement its own balance can also decline to, so the
/// charge happens server-side in the same transaction that accepts the job and
/// the app just re-reads the result. That is a deliberate departure from
/// TODO's "trừ credits sau mỗi lần dùng".
class AiStudioController extends GetxController {
  AiStudioController({required AiService service, AuthController? auth})
      : _service = service,
        _auth = auth;

  final AiService _service;
  final AuthController? _auth;

  final activeJob = Rxn<AiJob>();
  final lastFailure = Rxn<AiFailure>();

  /// The finished image, held back until the user says Apply or Discard.
  final pendingResult = Rxn<AiJob>();

  StreamSubscription<AiJob>? _subscription;

  AuthController? get _authController {
    if (_auth != null) return _auth;
    return Get.isRegistered<AuthController>() ? AuthController.to : null;
  }

  bool get isConfigured => _service.isConfigured;

  /// Real balance from the profile document. Zero when signed out or before
  /// the profile has loaded — never a placeholder that suggests spendable
  /// credits the account does not have.
  int get credits => _authController?.profile.value?.credits.balance ?? 0;

  bool get isProcessing => activeJob.value?.isRunning ?? false;

  /// Guests get the whole editor; paid cloud work is where the line sits, so
  /// there is something concrete to convert on rather than a wall at launch.
  bool get requiresAccount => _authController?.isGuest ?? false;

  bool canAfford(AiTool tool) => credits >= tool.credits;

  /// Why this tool cannot run right now, or null when it can.
  ///
  /// The account and credit gates are switched off while [FeatureFlags.creditsEnabled]
  /// is false: every tool stays reachable for the current demo/dev phase.
  AiFailureCode? blockerFor(AiTool tool) {
    if (!isConfigured) return AiFailureCode.notConfigured;
    if (!FeatureFlags.creditsEnabled) return null;
    if (requiresAccount) return AiFailureCode.unauthorized;
    if (!canAfford(tool)) return AiFailureCode.insufficientCredits;
    return null;
  }

  Future<void> run(
    AiTool tool, {
    required String imagePath,
    String? prompt,
  }) async {
    if (isProcessing) return;

    final blocker = blockerFor(tool);
    if (blocker != null) {
      lastFailure.value = AiFailure(blocker);
      return;
    }
    if (tool.needsPrompt && (prompt?.trim().isEmpty ?? true)) {
      lastFailure.value = const AiFailure(AiFailureCode.promptRequired);
      return;
    }

    lastFailure.value = null;
    pendingResult.value = null;

    final completer = Completer<void>();
    await _subscription?.cancel();
    _subscription = _service
        .run(AiRunRequest(tool: tool, imagePath: imagePath, prompt: prompt))
        .listen(
      (job) {
        activeJob.value = job;
        if (!job.isTerminal) return;

        if (job.status == AiJobStatus.succeeded && job.result != null) {
          pendingResult.value = job;
        } else if (job.failure != null) {
          lastFailure.value = job.failure;
        }
        // The server has charged by now, so pull the balance back down rather
        // than guessing at it locally.
        unawaited(_refreshCredits());
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('[ai] stream failed: $error');
        lastFailure.value = AiFailure(AiFailureCode.unknown, detail: '$error');
        activeJob.value = activeJob.value?.copyWith(status: AiJobStatus.failed);
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> cancel() async {
    final job = activeJob.value;
    if (job == null || job.isTerminal) return;
    await _service.cancel(job.id);
    await _subscription?.cancel();
    _subscription = null;
    activeJob.value = job.copyWith(status: AiJobStatus.cancelled);
  }

  /// Hands the result to the caller and clears it. The editor decides where it
  /// goes, so this controller never has to know about the edit stack.
  AiJob? takeResult() {
    final job = pendingResult.value;
    pendingResult.value = null;
    activeJob.value = null;
    return job;
  }

  void discardResult() {
    pendingResult.value = null;
    activeJob.value = null;
  }

  void clearFailure() => lastFailure.value = null;

  Future<void> _refreshCredits() async {
    try {
      await _authController?.loadProfile();
    } catch (error) {
      debugPrint('[ai] credit refresh failed: $error');
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
