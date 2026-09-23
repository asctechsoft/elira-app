import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/onboarding_controller.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import '../common_components/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'ASC ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: 'Photo AI',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.primary),
                            ),
                          ]),
                        ),
                        const Text(
                          'Turn your moments into magic ✨',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(RouteName.main),
                      child: const Text('Skip',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
                    ),
                  ],
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: ctrl.pageController,
                  onPageChanged: ctrl.onPageChanged,
                  children: const [
                    _OnboardingPage(
                      headline: 'Create stunning\nphotos in seconds',
                      body: 'Powerful AI tools to make your photos\nbrighter, cleaner and more beautiful.',
                      features: [
                        _Feature(icon: Icons.auto_fix_high, label: 'Enhance', sub: 'Sharper & clearer', color: Color(0xFFDCFAF0)),
                        _Feature(icon: Icons.cleaning_services, label: 'Remove', sub: 'Objects & people', color: Color(0xFFFFECEC)),
                        _Feature(icon: Icons.face_retouching_natural, label: 'Retouch', sub: 'Natural beauty', color: Color(0xFFEEEAFF)),
                      ],
                    ),
                    _OnboardingPage(
                      headline: 'AI that understands\nyour vision',
                      body: 'Instantly enhance, relight, and transform\nphotos with a single tap.',
                      features: [
                        _Feature(icon: Icons.brightness_high, label: 'Relight', sub: 'Perfect lighting', color: Color(0xFFFFF3DC)),
                        _Feature(icon: Icons.layers, label: 'Filters', sub: 'Stylish looks', color: Color(0xFFE8F0FF)),
                        _Feature(icon: Icons.image_outlined, label: 'Background', sub: 'Change with AI', color: Color(0xFFE0F7E0)),
                      ],
                    ),
                    _OnboardingPage(
                      headline: 'Create content\nthe world loves',
                      body: 'Turn your photos into collages, stories,\nposters and more — in minutes.',
                      features: [
                        _Feature(icon: Icons.grid_view, label: 'Collage', sub: 'Combine photos', color: Color(0xFFFFECEC)),
                        _Feature(icon: Icons.movie, label: 'Story', sub: 'For social media', color: Color(0xFFDCFAF0)),
                        _Feature(icon: Icons.auto_awesome, label: 'AI Magic', sub: 'Turn ideas to art', color: Color(0xFFEEEAFF)),
                      ],
                    ),
                  ],
                ),
              ),
              // Dot indicator
              Obx(() => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: ctrl.currentPage.value == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ctrl.currentPage.value == i
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  )),
              // Get Started button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: PrimaryButton(
                  label: 'Get Started',
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onTap: () => Get.offAllNamed(RouteName.main),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _Feature({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final String headline;
  final String body;
  final List<_Feature> features;

  const _OnboardingPage({
    required this.headline,
    required this.body,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('Preview image', style: TextStyle(color: AppColors.textHint)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: features
                .map((f) => _FeatureCard(icon: f.icon, label: f.label, sub: f.sub, color: f.color))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _FeatureCard({required this.icon, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
