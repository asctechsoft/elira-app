import 'package:get/get.dart';

import '../controller/auth_controller.dart';
import '../services/app_bootstrap.dart';
import '../services/bootstrap_step.dart';
import '../services/service_locator.dart';
import '../values/app_strings.dart';
import '../values/route_name.dart';

class SplashController extends GetxController {
  final progress = 0.0.obs;
  final statusLabel = AppStrings.splashLoading.obs;
  final failure = Rxn<Object>();

  /// A floor, not a fake delay: a warm start finishes in ~200ms and a splash
  /// that flashes that briefly reads as a glitch. On a slow device it costs
  /// nothing because the bootstrap already takes longer.
  static const _minSplashDuration = Duration(milliseconds: 1600);

  @override
  void onReady() {
    super.onReady();
    boot();
  }

  Future<void> boot() async {
    failure.value = null;
    progress.value = 0;

    final startedAt = DateTime.now();
    final result = await AppBootstrap(_steps()).run(
      resolveOutcome: () => AuthController.to.isSignedIn
          ? BootstrapOutcome.authenticated
          : BootstrapOutcome.unauthenticated,
      onProgress: (p) {
        progress.value = p.value;
        statusLabel.value = p.label;
      },
    );

    if (result.isFailure) {
      failure.value = result.error ?? 'bootstrap failed';
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashDuration) {
      await Future<void>.delayed(_minSplashDuration - elapsed);
    }

    Get.offAllNamed(
      result.outcome == BootstrapOutcome.authenticated
          ? RouteName.main
          : RouteName.onboarding,
    );
  }

  List<BootstrapStep> _steps() => [
        CallbackBootstrapStep(
          id: 'firebase',
          label: AppStrings.splashLoading,
          action: ServiceLocator.initFirebase,
          timeout: const Duration(seconds: 15),
        ),
        CallbackBootstrapStep(
          id: 'services',
          label: AppStrings.splashLoading,
          action: () async {
            ServiceLocator.registerServices();
            if (!Get.isRegistered<AuthController>()) {
              Get.put<AuthController>(
                AuthController(Get.find(), Get.find()),
                permanent: true,
              );
            }
          },
        ),
        CallbackBootstrapStep(
          id: 'auth-restore',
          label: AppStrings.splashLoading,
          action: () => AuthController.to.restoreSession(),
          timeout: const Duration(seconds: 8),
        ),
        CallbackBootstrapStep(
          id: 'profile',
          label: AppStrings.splashLoading,
          action: () => AuthController.to.loadProfile(),
          isCritical: false,
          timeout: const Duration(seconds: 3),
        ),
        // Append here when they land; the splash UI needs no changes:
        // CallbackBootstrapStep(id: 'remote-config', ..., isCritical: false),
        // CallbackBootstrapStep(id: 'entitlement', ..., isCritical: false),
      ];

  Future<void> retry() => boot();

  /// Escape hatch for the "no network on first launch" state: the local editor
  /// works offline, so a failed bootstrap must not trap the user on splash.
  void continueOffline() => Get.offAllNamed(RouteName.onboarding);
}
