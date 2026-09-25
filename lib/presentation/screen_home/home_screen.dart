import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../models/data_models/edit_project.dart';
import '../../services/color_matrix.dart';
import '../../services/photo_filters.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import '../common_components/section_header.dart';
import '../screen_projects/project_list_screen.dart';

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
    final ctrl = Get.find<HomeController>();
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
                child: SectionHeader(
                  title: 'Quick Actions',
                  onSeeAll: () => ctrl.changeTab(2),
                ),
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
                child: SectionHeader(
                  title: 'Continue Editing',
                  onSeeAll: () => Get.toNamed(RouteName.projects),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _ContinueEditing(ctrl: ctrl)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Popular Presets
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Popular Presets',
                  onSeeAll: () => Get.toNamed(
                    RouteName.photoPicker,
                    arguments: const {'tool': 'filters'},
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _PresetStrip(ctrl: ctrl)),
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

/// Real drafts, newest first. Empty is a first-class state here: a new install
/// has nothing to continue, and two invented cards were the old placeholder.
class _ContinueEditing extends StatelessWidget {
  const _ContinueEditing({required this.ctrl});

  final HomeController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    if (ctrl.isLoadingProjects.value && ctrl.recentProjects.isEmpty) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (ctrl.recentProjects.isEmpty) {
      return const _NoProjectsYet();
    }

    final projects = ctrl.recentProjects.toList();
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ProjectCard(
          project: projects[i],
          onReturn: ctrl.loadProjects,
        ),
      ),
    );
  }
}

class _NoProjectsYet extends StatelessWidget {
  const _NoProjectsYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.toNamed(RouteName.photoPicker),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.disabled),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 30, color: AppColors.primary),
              SizedBox(height: 8),
              Text(
                'Nothing in progress',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pick a photo to start your first edit.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onReturn});

  final EditProject project;
  final Future<void> Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Passing the project itself, not just a path, so the editor restores
      // the saved edit stack rather than reopening the original. Reloading on
      // the way back is what keeps "Edited 2 minutes ago" honest.
      onTap: () async {
        await Get.toNamed(RouteName.editor, arguments: project);
        await onReturn();
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProjectThumbnail(project: project),
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
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(
                      project.timeAgo,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The editor's real filters, previewed on the user's own most recent photo.
/// Each card is the same thumbnail under that filter's colour matrix, so the
/// whole strip costs one image decode and shows what the preset actually does.
class _PresetStrip extends StatelessWidget {
  const _PresetStrip({required this.ctrl});

  final HomeController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final presets = ctrl.presets;
    final thumbnail = ctrl.latestThumbnail;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _PresetCard(
          filter: presets[i],
          thumbnailPath: thumbnail,
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.filter, required this.thumbnailPath});

  final PhotoFilter filter;
  final String? thumbnailPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // There is no photo open yet, so a preset sends the user to the picker
      // and lands them on the Filters tab once they have chosen one.
      onTap: () => Get.toNamed(
        RouteName.photoPicker,
        arguments: const {'tool': 'filters'},
      ),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailPath != null)
              ColorFiltered(
                colorFilter: ColorFilter.matrix(filter.matrix),
                child: Image.file(
                  File(thumbnailPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PresetSwatch(),
                ),
              )
            else
              _PresetSwatch(matrix: filter.matrix),
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
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
                child: Text(
                  filter.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in for when there is no photo to preview on yet: a gradient put
/// through the same matrix, so the card still shows the look rather than a
/// grey box.
class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({this.matrix});

  final List<double>? matrix;

  @override
  Widget build(BuildContext context) {
    const gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8A87C), Color(0xFF6B7FB3), Color(0xFF2E3A59)],
        ),
      ),
      child: SizedBox.expand(),
    );

    final m = matrix;
    if (m == null || ColorMatrix.isIdentity(m)) return gradient;
    return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: gradient);
  }
}
