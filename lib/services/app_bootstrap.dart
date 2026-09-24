import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bootstrap_step.dart';

enum BootstrapOutcome { authenticated, unauthenticated, failed }

class BootstrapResult {
  const BootstrapResult(this.outcome, {this.error});

  final BootstrapOutcome outcome;
  final Object? error;

  bool get isFailure => outcome == BootstrapOutcome.failed;
}

/// Runs startup work as an ordered list of steps so that remote config and
/// subscription-entitlement restore (spec 5.1) can be appended later without
/// touching the splash screen, its progress bar or its failure handling.
class AppBootstrap {
  AppBootstrap(this.steps);

  final List<BootstrapStep> steps;

  Future<BootstrapResult> run({
    required BootstrapOutcome Function() resolveOutcome,
    void Function(BootstrapProgress)? onProgress,
  }) async {
    final total = steps.length;
    onProgress?.call(BootstrapProgress(
      completed: 0,
      total: total,
      label: steps.isEmpty ? '' : steps.first.label,
    ));

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      try {
        await step.run().timeout(step.timeout);
      } catch (error, stack) {
        if (step.isCritical) {
          debugPrint('[bootstrap] critical step "${step.id}" failed: $error\n$stack');
          return BootstrapResult(BootstrapOutcome.failed, error: error);
        }
        debugPrint('[bootstrap] optional step "${step.id}" skipped: $error');
      }
      onProgress?.call(BootstrapProgress(
        completed: i + 1,
        total: total,
        label: i + 1 < steps.length ? steps[i + 1].label : step.label,
      ));
    }

    return BootstrapResult(resolveOutcome());
  }
}

/// Convenience wrapper so a step can be declared inline.
class CallbackBootstrapStep extends BootstrapStep {
  CallbackBootstrapStep({
    required this.id,
    required this.label,
    required Future<void> Function() action,
    this.isCritical = true,
    this.timeout = const Duration(seconds: 10),
  }) : _action = action;

  @override
  final String id;

  @override
  final String label;

  @override
  final bool isCritical;

  @override
  final Duration timeout;

  final Future<void> Function() _action;

  @override
  Future<void> run() => _action();
}
