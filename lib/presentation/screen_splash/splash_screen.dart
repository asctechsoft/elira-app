import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    Future.delayed(const Duration(milliseconds: 3000), () {
      Get.offNamed(RouteName.onboarding);
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset('assets/images/png/bg_splash.png', fit: BoxFit.cover),
          // Bottom landscape scene
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/png/img_splash.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          // Decorative top-right handwriting
          const Positioned(
            top: 100,
            right: 28,
            child: Text(
              'Better\nPhotos\nBrighter\nYou ♡',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8BB8F0),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Decorative bottom-left
          const Positioned(
            bottom: 160,
            left: 28,
            child: Text(
              'Turn your\nmoments into\nmagic ✨',
              style: TextStyle(
                color: Color(0xFF8BB8F0),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Center content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Logo with glow
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
                  'Edit. Enhance. Create.',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const Spacer(),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (context2, child2) => LinearProgressIndicator(
                          value: _progressCtrl.value,
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'LOADING MAGIC...',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
