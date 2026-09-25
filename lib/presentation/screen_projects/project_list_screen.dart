import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../models/data_models/edit_project.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';

/// Everything the user has edited. Home shows the newest few; this is the
/// "See All" behind it.
class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Your Projects',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: ctrl.loadProjects,
        child: Obx(() {
          if (ctrl.isLoadingProjects.value && ctrl.recentProjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.recentProjects.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                _EmptyProjects(),
              ],
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: ctrl.recentProjects.length,
            itemBuilder: (_, i) => _ProjectTile(
              project: ctrl.recentProjects[i],
              onOpen: () async {
                await Get.toNamed(
                  RouteName.editor,
                  arguments: ctrl.recentProjects[i],
                );
                await ctrl.loadProjects();
              },
              onDelete: () => _confirmDelete(context, ctrl, ctrl.recentProjects[i]),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HomeController ctrl,
    EditProject project,
  ) async {
    // Deleting a project removes the working copy of a photo the user may have
    // spent a while on, so it asks first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this project?'),
        content: Text(
          '"${project.name}" and its edits will be removed. '
          'The photo in your gallery is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.deleteProject(project.id);
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onOpen,
    required this.onDelete,
  });

  final EditProject project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      onLongPress: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.disabled),
              ),
              clipBehavior: Clip.antiAlias,
              child: ProjectThumbnail(project: project),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            project.timeAgo,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The saved thumbnail, or a placeholder. Shared with Home so a project looks
/// the same in both places.
class ProjectThumbnail extends StatelessWidget {
  const ProjectThumbnail({super.key, required this.project, this.fit = BoxFit.cover});

  final EditProject project;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = project.thumbnailPath ?? project.originalPath;
    if (path.isEmpty) return const _ThumbPlaceholder();

    return Image.file(
      File(path),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      // The working copy lives in app storage, but a user can still clear it
      // from the OS settings, so a missing file is a state, not a crash.
      errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.cardBg,
        child: Center(
          child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 28),
        ),
      );
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.photo_library_outlined, size: 56, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text(
          'No projects yet',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a photo and your edits will show up here.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Get.toNamed(RouteName.photoPicker),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Choose a photo',
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
