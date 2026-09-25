import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/projects/project_repository.dart';
import '../models/data_models/edit_project.dart';
import '../services/photo_filters.dart';

class HomeController extends GetxController {
  HomeController({ProjectRepository? projects}) : _projects = projects;

  final ProjectRepository? _projects;

  final currentTabIndex = 0.obs;

  final recentProjects = <EditProject>[].obs;
  final isLoadingProjects = false.obs;
  final projectsFailed = false.obs;

  /// How many drafts Home shows before "See All" is the only way to the rest.
  static const int recentLimit = 10;

  /// The presets on Home are the editor's real filters, so tapping one lands
  /// on the look it advertises instead of a name that matches nothing.
  List<PhotoFilter> get presets =>
      PhotoFilters.all.where((f) => !f.isNeutral).take(6).toList();

  bool get hasProjects => recentProjects.isNotEmpty;

  /// The newest thumbnail, used to preview the presets on the user's own
  /// photo rather than on a stock sample.
  String? get latestThumbnail {
    for (final project in recentProjects) {
      final path = project.thumbnailPath;
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  /// Called on init and whenever Home becomes visible again, because a project
  /// edited on another tab must not leave a stale card behind.
  Future<void> loadProjects() async {
    final repository = _projects;
    if (repository == null) return;

    isLoadingProjects.value = true;
    projectsFailed.value = false;
    try {
      recentProjects.value = await repository.recent(limit: recentLimit);
    } catch (error) {
      debugPrint('[home] loading projects failed: $error');
      projectsFailed.value = true;
    } finally {
      isLoadingProjects.value = false;
    }
  }

  Future<void> deleteProject(String id) async {
    final repository = _projects;
    if (repository == null) return;
    // Optimistic: the row is gone from the list before the disk agrees, so the
    // card does not sit there looking undeleted.
    recentProjects.removeWhere((p) => p.id == id);
    try {
      await repository.delete(id);
    } catch (error) {
      debugPrint('[home] delete failed: $error');
      await loadProjects();
    }
  }

  /// Coming back to Home is the moment a draft created or edited on another
  /// tab has to appear. The shell keeps all tabs alive in an IndexedStack, so
  /// nothing rebuilds on its own.
  void changeTab(int index) {
    final wasElsewhere = currentTabIndex.value != 0;
    currentTabIndex.value = index;
    if (index == 0 && wasElsewhere) unawaited(loadProjects());
  }
}
