import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/create_controller.dart';
import '../../models/data_models/photo_template.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import '../common_components/section_header.dart';
import '../screen_templates/template_list_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  /// Story and Post start a real template. Collage, Poster and Product Card
  /// need things the single-photo engine does not have, so they say so when
  /// tapped instead of doing nothing (see CreateController.unavailable).
  static const _quickCreate = [
    _QC('story_clean', 'Story', 'For social media', Icons.movie_outlined, Color(0xFFDCFAF0)),
    _QC('post_vivid', 'Post', 'Square and punchy', Icons.crop_square, Color(0xFFE8F0FF)),
    _QC('collage', 'Collage', 'Combine photos', Icons.grid_view, Color(0xFFFFECEC)),
    _QC('poster', 'Poster', 'Stunning designs', Icons.article_outlined, Color(0xFFEEEAFF)),
    _QC('product_card', 'Product Card', 'For business', Icons.storefront_outlined, Color(0xFFE0F7E0)),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CreateController>();
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
                        const Text('Sample', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.textPrimary)),
                        const Text('Make stylish content in minutes', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(gradient: AppColors.heroBannerGradient, borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IDEAS • TEMPLATES • AI MAGIC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                      SizedBox(height: 6),
                      Text('Create\nSomething\nBeautiful', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick Create
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Quick Create',
                  onSeeAll: () => Get.toNamed(RouteName.templates),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _quickCreate
                      .map((qc) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _QCCard(qc: qc, ctrl: ctrl),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Templates
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Templates',
                  onSeeAll: () => Get.toNamed(RouteName.templates),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: PhotoTemplates.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TemplateCard(
                    width: 150,
                    template: PhotoTemplates.all[i],
                    onTap: () => ctrl.startTemplate(PhotoTemplates.all[i]),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent styles: what this user actually reaches for.
            SliverToBoxAdapter(child: _RecentStyles(ctrl: ctrl)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _QC {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;

  const _QC(this.id, this.label, this.sub, this.icon, this.color);
}

class _QCCard extends StatelessWidget {
  final _QC qc;
  final CreateController ctrl;

  const _QCCard({required this.qc, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final blockedReason = CreateController.unavailable[qc.id];
    final blocked = blockedReason != null;

    return GestureDetector(
      onTap: () {
        if (blocked) {
          _explain(context, qc.label, blockedReason);
          return;
        }
        final template = PhotoTemplates.byId(qc.id);
        if (template != null) ctrl.startTemplate(template);
      },
      child: Opacity(
        opacity: blocked ? 0.45 : 1,
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: qc.color, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(qc.icon, size: 24, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                qc.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Says what is missing rather than failing silently. A tile that looks
  /// tappable and does nothing is the thing this whole pass is removing.
  void _explain(BuildContext context, String name, String reason) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$name is not ready yet'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _RecentStyles extends StatelessWidget {
  const _RecentStyles({required this.ctrl});

  final CreateController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    if (!ctrl.hasRecents) return const SizedBox.shrink();
    final recents = ctrl.recentTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Styles',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => TemplateCard(
              width: 120,
              template: recents[i],
              onTap: () => ctrl.startTemplate(recents[i]),
            ),
          ),
        ),
      ],
    );
  }
}
