import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/controller/export_controller.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:elira/services/export_service.dart';
import 'package:elira/values/text_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

/// Records what the photo library was asked to do, and can decline.
class _FakeGallery implements GallerySaver {
  _FakeGallery({this.access = true, this.grant = true, this.throwOnPut = false});

  bool access;
  bool grant;
  bool throwOnPut;

  final List<String> saved = [];
  int requests = 0;

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<bool> requestAccess() async {
    requests++;
    return grant;
  }

  @override
  Future<void> putImage(String path, {String? album}) async {
    if (throwOnPut) throw Exception('denied');
    saved.add(path);
  }
}

Uint8List _photo({int width = 240, int height = 180}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 120, 120));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TextFonts.allowDownloadableFonts = false;

  late Directory tmp;
  late File source;
  late EditorController editor;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('elira_export_ctrl');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
    await source.writeAsBytes(_photo());

    final now = DateTime.now();
    editor = EditorController(renderDelay: Duration.zero);
    editor.setProject(EditProject(
      id: 'p1',
      name: 'Trip',
      originalPath: source.path,
      width: 240,
      height: 180,
      createdAt: now,
      updatedAt: now,
    ));
    await editor.load();
    Get.put<EditorController>(editor);
  });

  tearDown(() async {
    Get.reset();
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  group('settings', () {
    test('quality is only adjustable for JPEG', () {
      final ctrl = ExportController(gallery: _FakeGallery());

      expect(ctrl.isQualityAdjustable, isTrue);
      ctrl.toggleFormat();
      expect(ctrl.isQualityAdjustable, isFalse,
          reason: 'PNG is lossless, so the slider would do nothing');
    });

    test('the resolution label follows the real crop, not the original size',
        () async {
      final ctrl = ExportController(gallery: _FakeGallery());
      expect(ctrl.resolutionLabel, '240 × 180');

      editor.setCropRect(left: 0, top: 0, right: 0.5, bottom: 1);
      await editor.applyCrop();

      expect(ctrl.resolutionLabel, '120 × 180');
    });

    test('a rotation swaps the label', () async {
      final ctrl = ExportController(gallery: _FakeGallery());
      await editor.rotate();

      expect(ctrl.resolutionLabel, '180 × 240');
    });

    test('a size cap shows in the label', () {
      final ctrl = ExportController(gallery: _FakeGallery());
      ctrl.setSize(ExportSize.medium);

      expect(ctrl.resolutionLabel, '240 × 180',
          reason: 'already below the cap, so nothing changes');
    });
  });

  group('exporting', () {
    test('writes a file and saves it to the gallery', () async {
      final gallery = _FakeGallery();
      final ctrl = ExportController(gallery: gallery);

      await ctrl.exportPhoto();

      expect(ctrl.result.value, isNotNull);
      expect(await ctrl.result.value!.file.exists(), isTrue);
      expect(gallery.saved.single, ctrl.result.value!.file.path);
      expect(ctrl.savedToGallery.value, isTrue);
      expect(ctrl.errorMessage.value, isNull);
      expect(ctrl.isExporting.value, isFalse);
    });

    test('asks for access only when it does not already have it', () async {
      final gallery = _FakeGallery(access: false);
      await ExportController(gallery: gallery).exportPhoto();
      expect(gallery.requests, 1);

      final allowed = _FakeGallery();
      await ExportController(gallery: allowed).exportPhoto();
      expect(allowed.requests, 0);
    });

    test('a declined permission still leaves a shareable file', () async {
      final gallery = _FakeGallery(access: false, grant: false);
      final ctrl = ExportController(gallery: gallery);

      await ctrl.exportPhoto();

      expect(ctrl.result.value, isNotNull,
          reason: 'the render succeeded; only the library step was refused');
      expect(await ctrl.result.value!.file.exists(), isTrue);
      expect(ctrl.savedToGallery.value, isFalse);
      expect(ctrl.errorMessage.value, contains('gallery'));
    });

    test('a failing gallery write does not fail the export', () async {
      final ctrl = ExportController(gallery: _FakeGallery(throwOnPut: true));

      await ctrl.exportPhoto();

      expect(ctrl.result.value, isNotNull);
      expect(ctrl.savedToGallery.value, isFalse);
    });

    test('the export carries the editor edits', () async {
      editor.setAdjust(brightness: 60);
      await editor.commitAdjust('Brightness');

      final ctrl = ExportController(gallery: _FakeGallery());
      await ctrl.exportPhoto();

      final exported = img.decodeImage(ctrl.result.value!.bytes)!;
      final plainCtrl = ExportController(gallery: _FakeGallery());
      await editor.undo();
      await plainCtrl.exportPhoto();
      final plain = img.decodeImage(plainCtrl.result.value!.bytes)!;

      double mean(img.Image image) {
        var total = 0.0;
        for (final pixel in image) {
          total += img.getLuminance(pixel);
        }
        return total / (image.width * image.height);
      }

      expect(mean(exported), greaterThan(mean(plain) + 5));
    });

    test('a crop is reflected in the exported dimensions', () async {
      editor.setCropRect(left: 0, top: 0, right: 0.5, bottom: 1);
      await editor.applyCrop();

      final ctrl = ExportController(gallery: _FakeGallery());
      await ctrl.exportPhoto();

      expect(ctrl.result.value!.width, 120);
      expect(ctrl.result.value!.height, 180);
    });

    test('PNG output is written as PNG', () async {
      final ctrl = ExportController(gallery: _FakeGallery())..toggleFormat();
      await ctrl.exportPhoto();

      expect(ctrl.result.value!.file.path, endsWith('.png'));
    });

    test('a missing photo reports instead of throwing', () async {
      await source.delete();
      final ctrl = ExportController(gallery: _FakeGallery());

      await ctrl.exportPhoto();

      expect(ctrl.result.value, isNull);
      expect(ctrl.errorMessage.value, isNotNull);
      expect(ctrl.isExporting.value, isFalse);
    });

    test('reset clears the finished state', () async {
      final ctrl = ExportController(gallery: _FakeGallery());
      await ctrl.exportPhoto();

      ctrl.reset();

      expect(ctrl.result.value, isNull);
      expect(ctrl.savedToGallery.value, isFalse);
    });
  });
}
