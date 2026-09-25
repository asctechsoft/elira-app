import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/projects/project_repository.dart';
import '../models/data_models/edit_project.dart';
import '../models/data_models/photo_template.dart';

/// Turns a picked photo into a draft project on disk.
///
/// The originals are copied rather than referenced. Two reasons, both from
/// spec 6: the gallery file must never be modified, and `AssetEntity.file`
/// hands back a path inside an OS-managed cache that can be evicted while the
/// user is still editing.
class ProjectDraftService {
  ProjectDraftService({Directory? rootOverride, ProjectRepository? repository})
      : _rootOverride = rootOverride,
        _repository = repository;

  final Directory? _rootOverride;

  /// Saved here rather than by the caller, so a draft cannot exist on disk
  /// without a row pointing at it — that is how orphaned folders accumulate.
  final ProjectRepository? _repository;

  /// Below this, AI upscale/enhance produces visibly poor results, so the
  /// picker warns before the user invests time in an edit (spec 6).
  static const int minPixelsForAi = 640 * 640;

  static const int _thumbnailEdge = 400;

  Future<Directory> _projectsRoot() async {
    final base = _rootOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}projects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<EditProject> createFromAsset(
    AssetEntity asset, {
    String? tool,
    PhotoTemplate? template,
  }) async {
    final source = await asset.originFile ?? await asset.file;
    if (source == null) {
      throw const ProjectDraftFailure('Could not read that photo from your library.');
    }
    return _create(
      source: source,
      name: await _nameForAsset(asset),
      sourceAssetId: asset.id,
      width: asset.width,
      height: asset.height,
      tool: tool,
      template: template,
    );
  }

  Future<EditProject> createFromFile(
    File source, {
    String? tool,
    String? name,
    PhotoTemplate? template,
  }) async {
    final size = await _readDimensions(source);
    return _create(
      source: source,
      name: name ?? 'Camera ${_stamp(DateTime.now())}',
      width: size?.width.round() ?? 0,
      height: size?.height.round() ?? 0,
      tool: tool,
      template: template,
    );
  }

  Future<EditProject> _create({
    required File source,
    required String name,
    required int width,
    required int height,
    String? sourceAssetId,
    String? tool,
    PhotoTemplate? template,
  }) async {
    final now = DateTime.now();
    final id = 'p_${now.microsecondsSinceEpoch}';
    final root = await _projectsRoot();
    final dir = Directory('${root.path}${Platform.pathSeparator}$id');
    await dir.create(recursive: true);

    final ext = _extensionOf(source.path);
    final originalPath = '${dir.path}${Platform.pathSeparator}original$ext';
    await source.copy(originalPath);

    final thumbnailPath = await _writeThumbnail(originalPath, dir.path);

    final project = EditProject(
      id: id,
      name: name,
      originalPath: originalPath,
      sourceAssetId: sourceAssetId,
      thumbnailPath: thumbnailPath,
      width: width,
      height: height,
      createdAt: now,
      updatedAt: now,
      initialTool: tool,
      // A template is just a pre-filled edit stack, so the editor restores it
      // with exactly the code that reopens a saved project — and every step of
      // it is undoable.
      adjustments: template?.toAdjustments(
            sourceWidth: width,
            sourceHeight: height,
          ) ??
          const {},
    );

    await _repository?.save(project);
    return project;
  }

  /// Non-fatal: a project without a thumbnail still opens, it just shows a
  /// placeholder in the drafts list.
  Future<String?> _writeThumbnail(String originalPath, String dirPath) async {
    try {
      final target = '$dirPath${Platform.pathSeparator}thumb.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        target,
        minWidth: _thumbnailEdge,
        minHeight: _thumbnailEdge,
        quality: 80,
      );
      return result?.path;
    } catch (error) {
      debugPrint('[draft] thumbnail failed: $error');
      return null;
    }
  }

  Future<ui.Size?> _readDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final descriptor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(bytes),
      );
      final size = ui.Size(descriptor.width.toDouble(), descriptor.height.toDouble());
      descriptor.dispose();
      return size;
    } catch (error) {
      debugPrint('[draft] could not read dimensions: $error');
      return null;
    }
  }

  Future<String> _nameForAsset(AssetEntity asset) async {
    final title = await asset.titleAsync;
    final base = title.isNotEmpty ? title : asset.title ?? '';
    if (base.isEmpty) return 'Photo ${_stamp(asset.createDateTime)}';
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || path.length - dot > 6) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  String _stamp(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';

  String _two(int v) => v.toString().padLeft(2, '0');
}

class ProjectDraftFailure implements Exception {
  const ProjectDraftFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
