import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/splash_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SplashController>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/png/bg_splash.png', fit: BoxFit.cover),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/png/img_splash.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          const Positioned(
            top: 100,
            right: 28,
            child: Text(
              'Better\nPhotos\nBrighter\nYou ♡',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.splashScript,
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Positioned(
            bottom: 160,
            left: 28,
            child: Text(
              'Turn your\nmoments into\nmagic ✨',
              style: TextStyle(
                color: AppColors.splashScript,
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/images/png/img_logo_video.png'),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ASC ',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'Photo AI',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.tagline,
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Obx(() => ctrl.failure.value == null
                      ? _BootProgress(
                          progress: ctrl.progress.value,
                          label: ctrl.statusLabel.value,
                        )
                      : _BootFailure(
                          onRetry: ctrl.retry,
                          onContinueOffline: ctrl.continueOffline,
                        )),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BootProgress extends StatelessWidget {
  const _BootProgress({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          // Animates between real step completions instead of faking a timer,
          // so the bar reflects actual boot work and grows naturally when more
          // steps (remote config, entitlement restore) are appended.
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surface.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BootFailure extends StatelessWidget {
  const _BootFailure({required this.onRetry, required this.onContinueOffline});

  final VoidCallback onRetry;
  final VoidCallback onContinueOffline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.cloud_off_outlined, color: AppColors.textSecondary, size: 28),
        const SizedBox(height: 10),
        const Text(
          AppStrings.splashFailedTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          AppStrings.splashFailedBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: const Text(AppStrings.retry),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onContinueOffline,
              child: const Text(
                AppStrings.continueOffline,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
