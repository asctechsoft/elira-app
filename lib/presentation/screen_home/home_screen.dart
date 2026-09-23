import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import '../common_components/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _quickActions = [
    _QA(id: 'enhance', label: 'Enhance', sub: 'Sharper & clearer', icon: Icons.auto_fix_high, color: AppColors.actionEnhance, iconColor: Color(0xFF00B37E)),
    _QA(id: 'remove', label: 'Remove', sub: 'Objects & people', icon: Icons.cleaning_services, color: AppColors.actionRemove, iconColor: Color(0xFFE53E3E)),
    _QA(id: 'retouch', label: 'Retouch', sub: 'Natural beauty', icon: Icons.face_retouching_natural, color: AppColors.actionRetouch, iconColor: Color(0xFF6B4FDB)),
    _QA(id: 'filters', label: 'Filters', sub: 'Stylish looks', icon: Icons.tune, color: AppColors.actionFilters, iconColor: Color(0xFF2B7EFB)),
    _QA(id: 'background', label: 'Background', sub: 'Change with AI', icon: Icons.image_outlined, color: AppColors.actionBackground, iconColor: Color(0xFF00875A)),
    _QA(id: 'ai_magic', label: 'AI Magic', sub: 'Turn ideas to art', icon: Icons.auto_awesome, color: AppColors.actionAiMagic, iconColor: Color(0xFF6B4FDB)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: 'ASC ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textPrimary)),
                            TextSpan(text: 'Photo AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.primary)),
                          ]),
                        ),
                        const Text('Turn your moments into magic ✨',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroBannerGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 20,
                        top: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CREATE • EDIT • BEYOND',
                                style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                            SizedBox(height: 6),
                            Text('Edit Photo',
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('Transform your photos\nwith the power of AI',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(RouteName.photoPicker),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text('Get Started', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Quick Actions', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _quickActions.length,
                  itemBuilder: (_, i) => _QuickActionCard(qa: _quickActions[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Continue Editing
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Continue Editing', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _ProjectCard(name: 'Santorini Trip', timeAgo: 'Edited 2 hours ago'),
                    SizedBox(width: 12),
                    _ProjectCard(name: 'My Puppy', timeAgo: 'Edited 1 day ago'),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Popular Presets
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Popular Presets', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _PresetCard(name: 'Cinematic', sub: 'Moody & Epic'),
                    SizedBox(width: 12),
                    _PresetCard(name: 'Vibrant', sub: 'Bright & Lively'),
                    SizedBox(width: 12),
                    _PresetCard(name: 'Aesthetic', sub: 'Soft & Dreamy'),
                    SizedBox(width: 12),
                    _PresetCard(name: 'Golden Hour', sub: 'Warm & Rich'),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _QA {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _QA({required this.id, required this.label, required this.sub, required this.icon, required this.color, required this.iconColor});
}

class _QuickActionCard extends StatelessWidget {
  final _QA qa;

  const _QuickActionCard({required this.qa});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteName.photoPicker, arguments: {'tool': qa.id}),
      child: Container(
        decoration: BoxDecoration(color: qa.color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(qa.icon, color: qa.iconColor, size: 32),
            const SizedBox(height: 6),
            Text(qa.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            Text(qa.sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String name;
  final String timeAgo;

  const _ProjectCard({required this.name, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(timeAgo, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String name;
  final String sub;

  const _PresetCard({required this.name, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
