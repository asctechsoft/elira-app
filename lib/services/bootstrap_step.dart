abstract class BootstrapStep {
  String get id;

  /// Shown under the splash progress bar while this step runs.
  String get label;

  /// A non-critical step that fails is logged and skipped; the app still boots.
  bool get isCritical => true;

  Duration get timeout => const Duration(seconds: 10);

  Future<void> run();
}

class BootstrapProgress {
  const BootstrapProgress({
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;
  final int total;
  final String label;

  double get value => total == 0 ? 1 : completed / total;
}
