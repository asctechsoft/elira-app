import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/ai_studio_controller.dart';
import '../../values/app_colors.dart';
import '../common_components/section_header.dart';

class AiStudioScreen extends StatelessWidget {
  const AiStudioScreen({super.key});

  static const _tools = [
    _AiTool('ai_enhance', 'AI Enhance', 'Sharper & clearer', Icons.auto_fix_high, Color(0xFFDCFAF0), Color(0xFF00B37E)),
    _AiTool('remove_bg', 'Remove BG', 'Clean & precise', Icons.cleaning_services, Color(0xFFFFECEC), Color(0xFFE53E3E)),
    _AiTool('expand', 'Expand', 'Bigger horizons', Icons.open_in_full, Color(0xFFE8F0FF), Color(0xFF2B7EFB)),
    _AiTool('replace', 'Replace', 'Swap anything', Icons.find_replace, Color(0xFFFFF3DC), Color(0xFFF59E0B)),
    _AiTool('relight', 'Relight', 'Perfect lighting', Icons.wb_sunny_outlined, Color(0xFFFFF3DC), Color(0xFFF59E0B)),
    _AiTool('restore', 'Restore', 'Fix & revive', Icons.restore, Color(0xFFE0F7E0), Color(0xFF00875A)),
    _AiTool('headshot', 'Headshot', 'Studio quality', Icons.person_outline, Color(0xFFEEEAFF), Color(0xFF6B4FDB)),
    _AiTool('product', 'Product Studio', 'For business', Icons.storefront_outlined, Color(0xFFFFECEC), Color(0xFFE53E3E)),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AiStudioController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: 'AI ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.textPrimary)),
                            TextSpan(text: 'Studio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.primary)),
                            TextSpan(text: ' ✨', style: TextStyle(fontSize: 22)),
                          ]),
                        ),
                        const Text('More creativity. Less limits.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('${ctrl.credits.value} Credits',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(width: 6),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                child: const Icon(Icons.add, color: Colors.white, size: 12),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroBannerGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IDEAS • IMAGES • MAGIC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      const Text('Create More\nwith AI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Explore AI Tools', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // AI Tools Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'AI Tools', onSeeAll: () {}),
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
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _tools.length,
                  itemBuilder: (_, i) => _AiToolCard(tool: _tools[i], ctrl: ctrl),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent AI Results
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Recent AI Results', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _ResultCard(label: 'Enhanced'),
                    SizedBox(width: 10),
                    _ResultCard(label: 'Background Removed'),
                    SizedBox(width: 10),
                    _ResultCard(label: 'Expanded'),
                    SizedBox(width: 10),
                    _ResultCard(label: 'Restored'),
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

class _AiTool {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final Color bg;
  final Color iconColor;

  const _AiTool(this.id, this.label, this.sub, this.icon, this.bg, this.iconColor);
}

class _AiToolCard extends StatelessWidget {
  final _AiTool tool;
  final AiStudioController ctrl;

  const _AiToolCard({required this.tool, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ctrl.runTool(tool.id),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: tool.bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(tool.icon, color: tool.iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(tool.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary)),
          Text(tool.sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;

  const _ResultCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
        ),
      ),
    );
  }
}
