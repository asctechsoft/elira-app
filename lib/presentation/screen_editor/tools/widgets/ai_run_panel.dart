import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controller/ai_studio_controller.dart';
import '../../../../controller/editor_controller.dart';
import '../../../../data/ai/ai_failure.dart';
import '../../../../data/ai/ai_job.dart';
import '../../../../models/data_models/ai_tool.dart';
import '../../../../values/app_colors.dart';
import '../../../../values/app_strings.dart';
import '../../../../values/feature_flags.dart';
import '../../../../values/route_name.dart';
import 'ai_gate.dart';

/// One tool, end to end: cost, whether it can run, progress while it does, and
/// Apply / Discard on the result.
///
/// Shared by the Remove, Background, Retouch and AI tabs so all four behave the
/// same — each of them used to draw its own controls that did nothing.
class AiRunPanel extends StatefulWidget {
  const AiRunPanel({
    super.key,
    required this.ctrl,
    required this.tool,
    required this.description,
    required this.bullets,
  });

  final EditorController ctrl;
  final AiTool tool;
  final String description;
  final List<String> bullets;

  @override
  State<AiRunPanel> createState() => _AiRunPanelState();
}

class _AiRunPanelState extends State<AiRunPanel> {
  final TextEditingController _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  AiStudioController? get _ai =>
      Get.isRegistered<AiStudioController>() ? Get.find<AiStudioController>() : null;

  @override
  Widget build(BuildContext context) {
    final ai = _ai;
    if (ai == null || !ai.isConfigured) {
      return AiGate(
        title: widget.tool.name,
        credits: FeatureFlags.creditsEnabled ? widget.tool.credits : null,
        description: widget.description,
        bullets: widget.bullets,
      );
    }
    return Obx(() => _build(context, ai));
  }

  Widget _build(BuildContext context, AiStudioController ai) {
    final tool = widget.tool;
    final result = ai.pendingResult.value;
    final job = ai.activeJob.value;
    final failure = ai.lastFailure.value;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(tool: tool, balance: ai.credits),
          const SizedBox(height: 10),
          if (result != null)
            _ResultActions(
              job: result,
              onApply: () => _apply(ai),
              onDiscard: ai.discardResult,
            )
          else if (job != null && job.isRunning)
            _Progress(job: job, onCancel: ai.cancel)
          else ...[
            Text(
              widget.description,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            if (tool.needsPrompt) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _prompt,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Describe what you want',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _RunButton(
              tool: tool,
              blocker: ai.blockerFor(tool),
              onRun: () => _run(ai),
              onFixBlocker: (code) => _resolve(code),
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: 10),
            _Failure(
              failure: failure,
              onRetry: failure.isRetryable ? () => _run(ai) : null,
              onDismiss: ai.clearFailure,
              onFix: failure.needsCredits || failure.code == AiFailureCode.unauthorized
                  ? () => _resolve(failure.code)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _run(AiStudioController ai) async {
    final path = widget.ctrl.imagePath.value;
    if (path.isEmpty) return;
    await ai.run(
      widget.tool,
      imagePath: path,
      prompt: widget.tool.needsPrompt ? _prompt.text : null,
    );
  }

  Future<void> _apply(AiStudioController ai) async {
    final job = ai.takeResult();
    final bytes = job?.result;
    if (job == null || bytes == null) return;
    await widget.ctrl.applyAiResult(
      tool: job.tool,
      bytes: bytes,
      simulated: job.isSimulated,
    );
  }

  void _resolve(AiFailureCode code) {
    if (code == AiFailureCode.unauthorized) {
      Get.toNamed(RouteName.login);
    }
    // Buying credits is the store flow, which does not exist yet; until then
    // the message alone is the honest answer.
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tool, required this.balance});

  final AiTool tool;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.surface, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (FeatureFlags.creditsEnabled)
                Text(
                  '${tool.credits} credits · you have $balance',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.tool,
    required this.blocker,
    required this.onRun,
    required this.onFixBlocker,
  });

  final AiTool tool;
  final AiFailureCode? blocker;
  final VoidCallback onRun;
  final ValueChanged<AiFailureCode> onFixBlocker;

  @override
  Widget build(BuildContext context) {
    final blocked = blocker != null;
    final label = switch (blocker) {
      AiFailureCode.unauthorized => 'Create a free account',
      AiFailureCode.insufficientCredits => 'Not enough credits',
      AiFailureCode.notConfigured => 'Not connected yet',
      _ => FeatureFlags.creditsEnabled ? 'Run · ${tool.credits} credits' : 'Run',
    };

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: blocked
            ? (blocker == AiFailureCode.unauthorized
                ? () => onFixBlocker(blocker!)
                : null)
            : onRun,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: blocked ? null : AppColors.primaryGradient,
            color: blocked ? AppColors.disabled : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: blocked ? AppColors.textSecondary : AppColors.surface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.job, required this.onCancel});

  final AiJob job;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                job.statusLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            // Null while the server reports only a phase: a fake percentage
            // that stalls is worse than an honest indeterminate bar.
            value: job.progress,
            minHeight: 6,
            backgroundColor: AppColors.cardBg,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can keep editing — this runs in the background.',
          style: TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.job,
    required this.onApply,
    required this.onDiscard,
  });

  final AiJob job;
  final VoidCallback onApply;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (job.result != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  job.result!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Result ready',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    job.isSimulated
                        // Never let the stand-in pass for the real model.
                        ? 'Simulated locally — no AI service is connected.'
                        : 'Applying adds one undoable step.',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onDiscard,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.disabled),
                  ),
                  child: const Center(
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onApply,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.failure,
    required this.onRetry,
    required this.onDismiss,
    required this.onFix,
  });

  final AiFailure failure;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.aiError(failure.code),
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('Retry',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            )
          else if (onFix != null)
            GestureDetector(
              onTap: onFix,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('Fix',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
