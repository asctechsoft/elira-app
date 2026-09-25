import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../models/data_models/edit_operation.dart';
import '../models/data_models/edit_project.dart';
import '../services/color_matrix.dart';
import '../services/export_service.dart';
import 'editor_controller.dart';

class ExportController extends GetxController {
  ExportController({this.gallery = const GalSaver()});

  /// Injected so the save step is testable without a real photo library.
  final GallerySaver gallery;

  final isJpeg = true.obs;
  final quality = 90.0.obs;
  final size = ExportSize.original.obs;
  final addWatermark = false.obs;

  final isExporting = false.obs;
  final stage = Rxn<ExportStage>();
  final result = Rxn<ExportResult>();
  final savedToGallery = false.obs;
  final errorMessage = RxnString();

  EditorController? get _editor =>
      Get.isRegistered<EditorController>() ? Get.find<EditorController>() : null;

  EditProject? get project => _editor?.project.value;

  /// What export will actually replay. Empty when the editor is not open.
  EditState get state => _editor?.currentState ?? EditState.initial;

  String? get sourcePath => _editor?.effectiveSourcePath;

  /// Live preview of the finished frame — the same bytes the canvas shows, so
  /// the export screen is not a mock-up of the result.
  Uint8List? get previewBytes => _editor?.previewBase.value;

  /// The colour stage the canvas applies on the GPU. The export screen draws
  /// the preview through the same matrix, so what is shown here is what the
  /// file will contain.
  List<double> get colorMatrix => _editor?.colorMatrix ?? ColorMatrix.identity;

  /// The size label is derived, not hardcoded: a crop or a rotate changes the
  /// exported dimensions, and the screen used to claim "3024 × 4032" whatever
  /// had been done to the photo.
  String get resolutionLabel {
    final p = project;
    if (p == null) return size.value.label;
    final geometry = state.geometry;
    var width = p.width;
    var height = p.height;
    if (geometry.swapsAxes) {
      final swap = width;
      width = height;
      height = swap;
    }
    width = (width * geometry.cropWidth).round();
    height = (height * geometry.cropHeight).round();

    final cap = size.value.maxEdge;
    if (cap != null) {
      final longest = width > height ? width : height;
      if (longest > cap) {
        final scale = cap / longest;
        width = (width * scale).round();
        height = (height * scale).round();
      }
    }
    return '$width × $height';
  }

  void toggleFormat() => isJpeg.value = !isJpeg.value;

  void setQuality(double v) => quality.value = v;

  void setSize(ExportSize value) => size.value = value;

  void toggleWatermark(bool v) => addWatermark.value = v;

  /// PNG is lossless, so the quality slider has nothing to act on there.
  bool get isQualityAdjustable => isJpeg.value;

  String get stageLabel => switch (stage.value) {
        ExportStage.rendering => 'Replaying your edits at full size',
        ExportStage.compositing => 'Drawing the text',
        ExportStage.encoding => 'Encoding',
        ExportStage.saving => 'Saving',
        ExportStage.done => 'Done',
        null => '',
      };

  Future<void> exportPhoto() async {
    final path = sourcePath;
    if (isExporting.value || path == null || path.isEmpty) {
      errorMessage.value = 'Open a photo first.';
      return;
    }

    isExporting.value = true;
    errorMessage.value = null;
    result.value = null;
    savedToGallery.value = false;

    try {
      final exported = await ExportService.export(
        ExportRequest(
          sourcePath: path,
          state: state,
          format: isJpeg.value ? ExportFormat.jpeg : ExportFormat.png,
          quality: quality.value.round(),
          size: size.value,
          watermark: addWatermark.value,
        ),
        onStage: (value) => stage.value = value,
      );
      result.value = exported;

      // Saving to the library is the step that needs a permission and can be
      // declined, so it is reported separately: the file exists either way and
      // can still be shared.
      savedToGallery.value = await _saveToGallery(exported.file);
      if (!savedToGallery.value) {
        errorMessage.value =
            'Saved to the app, but not to your gallery — permission was denied.';
      }
    } on ExportFailure catch (failure) {
      errorMessage.value = failure.message;
    } catch (error) {
      debugPrint('[export] failed: $error');
      errorMessage.value = 'Export failed. Please try again.';
    } finally {
      isExporting.value = false;
      stage.value = null;
    }
  }

  Future<bool> _saveToGallery(File file) async {
    try {
      if (!await gallery.hasAccess()) {
        final granted = await gallery.requestAccess();
        if (!granted) return false;
      }
      await gallery.putImage(file.path, album: 'Elira');
      return true;
    } catch (error) {
      debugPrint('[export] gallery save failed: $error');
      return false;
    }
  }

  Future<void> share() async {
    final exported = result.value;
    if (exported == null) {
      // Nothing to share until something has been rendered; exporting first is
      // the honest behaviour rather than a dead button.
      await exportPhoto();
    }
    final file = result.value?.file;
    if (file == null) return;

    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (error) {
      debugPrint('[export] share failed: $error');
      errorMessage.value = 'Could not open the share sheet.';
    }
  }

  void clearError() => errorMessage.value = null;

  void reset() {
    result.value = null;
    savedToGallery.value = false;
    errorMessage.value = null;
  }
}

/// Thin seam over the platform photo library, so the controller can be tested
/// without one.
abstract class GallerySaver {
  Future<bool> hasAccess();
  Future<bool> requestAccess();
  Future<void> putImage(String path, {String? album});
}

class GalSaver implements GallerySaver {
  const GalSaver();

  @override
  Future<bool> hasAccess() => Gal.hasAccess();

  @override
  Future<bool> requestAccess() => Gal.requestAccess();

  @override
  Future<void> putImage(String path, {String? album}) =>
      Gal.putImage(path, album: album);
}
