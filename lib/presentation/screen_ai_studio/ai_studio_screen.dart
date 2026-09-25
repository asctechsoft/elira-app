import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/ai_studio_controller.dart';
import '../../models/data_models/ai_tool.dart';
import '../../values/app_colors.dart';
import '../../values/feature_flags.dart';
import '../../values/route_name.dart';
import '../common_components/section_header.dart';

class AiStudioScreen extends StatelessWidget {
  const AiStudioScreen({super.key});

  /// Icons and tints only. The tools themselves, their ids and their prices
  /// come from [AiTools], so this screen and the editor cannot drift apart on
  /// what a run costs.
  static const _decor = <String, (IconData, Color, Color)>{
    'ai_enhance': (Icons.auto_fix_high, Color(0xFFDCFAF0), Color(0xFF00B37E)),
    'remove_bg': (Icons.cleaning_services, Color(0xFFFFECEC), Color(0xFFE53E3E)),
    'expand': (Icons.open_in_full, Color(0xFFE8F0FF), Color(0xFF2B7EFB)),
    'replace': (Icons.find_replace, Color(0xFFFFF3DC), Color(0xFFF59E0B)),
    'relight': (Icons.wb_sunny_outlined, Color(0xFFFFF3DC), Color(0xFFF59E0B)),
    'restore': (Icons.restore, Color(0xFFE0F7E0), Color(0xFF00875A)),
    'headshot': (Icons.person_outline, Color(0xFFEEEAFF), Color(0xFF6B4FDB)),
    'product': (Icons.storefront_outlined, Color(0xFFFFECEC), Color(0xFFE53E3E)),
  };

  static List<AiTool> get _tools =>
      AiTools.all.where((t) => _decor.containsKey(t.id)).toList();

  /// A tool needs a photo before it can do anything, so choosing one here
  /// sends the user to the picker carrying the tool id — the picker already
  /// forwards it, and the editor already opens on the matching tab.
  static void _startTool(AiTool tool) =>
      Get.toNamed(RouteName.photoPicker, arguments: {'tool': tool.id});

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
                    if (FeatureFlags.creditsEnabled)
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
                                Text('${ctrl.credits} Credits',
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
                  constraints: const BoxConstraints(minHeight: 140),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroBannerGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IDEAS • IMAGES • MAGIC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      const Text('Create More\nwith AI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Get.toNamed(RouteName.photoPicker),
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
                child: _ToolGrid(tools: _tools, ctrl: ctrl),
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

/// Rows of Expanded cells instead of a GridView: a fixed childAspectRatio
/// can't grow with the text, so the cards overflowed at larger font scales.
class _ToolGrid extends StatelessWidget {
  static const _columns = 4;
  static const _gap = 12.0;

  final List<AiTool> tools;
  final AiStudioController ctrl;

  const _ToolGrid({required this.tools, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r < tools.length; r += _columns) ...[
          if (r > 0) const SizedBox(height: _gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = r; i < r + _columns; i++) ...[
                if (i > r) const SizedBox(width: _gap),
                Expanded(
                  child: i < tools.length
                      ? _AiToolCard(
                          tool: tools[i],
                          ctrl: ctrl,
                          onTap: () => AiStudioScreen._startTool(tools[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _AiToolCard extends StatelessWidget {
  final AiTool tool;
  final AiStudioController ctrl;
  final VoidCallback onTap;

  const _AiToolCard({required this.tool, required this.ctrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final decor = AiStudioScreen._decor[tool.id]!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: decor.$2, borderRadius: BorderRadius.circular(14)),
                child: Icon(decor.$1, color: decor.$3, size: 26),
              ),
              // The price belongs on the tool, not buried a screen later.
              if (FeatureFlags.creditsEnabled)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${tool.credits}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tool.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary)),
          Text(tool.tagline, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
