import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:elira/models/ui_models/editor_tool.dart';
import 'package:elira/services/image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

EditProject _project({String? tool, required String path}) {
  final now = DateTime.now();
  return EditProject(
    id: 'p_1',
    name: 'Santorini Trip',
    originalPath: path,
    width: 3024,
    height: 4032,
    createdAt: now,
    updatedAt: now,
    initialTool: tool,
  );
}

Uint8List _jpeg({int width = 60, int height = 40}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 130, 140));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}


/// Luminance of what the canvas actually draws: the sharpness base with the
/// GPU colour matrix on top, reproduced here on the CPU.
double _shownLuminance(EditorController ctrl) {
  final base = img.decodeImage(ctrl.previewBase.value!)!;
  final shown = ImagePipeline.applyColorMatrix(base, ctrl.colorMatrix);
  var total = 0.0;
  for (final pixel in shown) {
    total += img.getLuminance(pixel);
  }
  return total / (shown.width * shown.height);
}

void main() {
  late Directory tmp;
  late File source;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('elira_editor_test');
    source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
    await source.writeAsBytes(_jpeg());
  });

  tearDown(() async {
    Get.reset();
    // Windows refuses to delete a directory while a background load still
    // holds a handle on it. The temp dir is OS-managed, so a failed cleanup is
    // not worth failing the test over.
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  EditorController build({String? tool}) {
    final ctrl = EditorController(renderDelay: Duration.zero);
    ctrl.setProject(_project(tool: tool, path: source.path));
    return ctrl;
  }

  group('project adoption', () {
    test('takes path, title and resolution from the project', () async {
      final ctrl = build();
      await ctrl.load();

      expect(ctrl.imagePath.value, source.path);
      expect(ctrl.title, 'Santorini Trip');
      expect(ctrl.project.value?.resolutionLabel, '3024 × 4032');
    });

    test('opens on the tool the Home quick action asked for', () {
      const cases = {
        'remove': EditorTool.remove,
        'retouch': EditorTool.retouch,
        'filters': EditorTool.filters,
        'background': EditorTool.background,
        'ai_magic': EditorTool.ai,
        'enhance': EditorTool.adjust,
      };
      cases.forEach((id, expected) {
        expect(build(tool: id).activeTool.value, expected, reason: 'quick action "$id"');
      });
    });

    test('falls back to Adjust for an unknown or absent tool id', () {
      expect(build(tool: 'something-else').activeTool.value, EditorTool.adjust);
      expect(build().activeTool.value, EditorTool.adjust);
    });
  });

  group('loading', () {
    test('produces a preview and starts with a clean history', () async {
      final ctrl = build();
      await ctrl.load();

      expect(ctrl.previewBase.value, isNotNull);
      expect(ctrl.canUndo.value, isFalse);
      expect(ctrl.canRedo.value, isFalse);
      expect(ctrl.isSaved.value, isTrue);
      expect(ctrl.errorMessage.value, isNull);
    });

    test('reports a corrupted file instead of throwing', () async {
      await source.writeAsBytes(Uint8List.fromList([9, 9, 9, 9]));
      final ctrl = build();
      await ctrl.load();

      expect(ctrl.errorMessage.value, isNotNull);
      expect(ctrl.isLoading.value, isFalse);
    });

    test('reports a missing file instead of throwing', () async {
      await source.delete();
      final ctrl = build();
      await ctrl.load();

      expect(ctrl.errorMessage.value, 'Could not open that photo.');
    });
  });

  group('adjust and history', () {
    test('committing brightness renders a lighter preview and enables undo', () async {
      final ctrl = build();
      await ctrl.load();
      final before = _shownLuminance(ctrl);

      ctrl.setAdjust(brightness: 70);
      await ctrl.commitAdjust('Brightness');

      expect(_shownLuminance(ctrl), greaterThan(before + 5));
      expect(ctrl.canUndo.value, isTrue);
      expect(ctrl.isSaved.value, isFalse);
      expect(ctrl.history.length, 1);
      expect(ctrl.history.first.label, 'Brightness');
      expect(ctrl.history.first.thumbnail, isNotNull,
          reason: 'the version strip renders its thumbnail once, at commit time');
    });

    test('undo restores both the pixels and the slider values', () async {
      final ctrl = build();
      await ctrl.load();
      final original = _shownLuminance(ctrl);

      ctrl.setAdjust(brightness: 70);
      await ctrl.commitAdjust('Brightness');
      await ctrl.undo();

      expect(ctrl.brightness.value, 0);
      expect((_shownLuminance(ctrl) - original).abs(), lessThan(3));
      expect(ctrl.canUndo.value, isFalse);
      expect(ctrl.canRedo.value, isTrue);
      expect(ctrl.isSaved.value, isTrue);
    });

    test('redo reapplies the undone edit', () async {
      final ctrl = build();
      await ctrl.load();

      ctrl.setAdjust(brightness: 70);
      await ctrl.commitAdjust('Brightness');
      final edited = _shownLuminance(ctrl);

      await ctrl.undo();
      await ctrl.redo();

      expect(ctrl.brightness.value, 70);
      expect((_shownLuminance(ctrl) - edited).abs(), lessThan(3));
      expect(ctrl.canRedo.value, isFalse);
    });

    test('successive tweaks of one control collapse into a single entry', () async {
      final ctrl = build();
      await ctrl.load();

      for (final v in [20.0, 45.0, 70.0]) {
        ctrl.setAdjust(brightness: v);
        await ctrl.commitAdjust('Brightness');
      }

      expect(ctrl.history.length, 1, reason: 'one control, one history entry');
      expect(ctrl.history.first.params['brightness'], 70);

      await ctrl.undo();
      expect(ctrl.brightness.value, 0, reason: 'one undo clears the whole run');
    });

    test('a different control starts a new entry', () async {
      final ctrl = build();
      await ctrl.load();

      ctrl.setAdjust(brightness: 40);
      await ctrl.commitAdjust('Brightness');
      ctrl.setAdjust(contrast: 30);
      await ctrl.commitAdjust('Contrast');

      expect(ctrl.history.length, 2);
      expect(ctrl.history.map((o) => o.label), ['Brightness', 'Contrast']);
    });

    test('committing an unchanged value adds nothing to history', () async {
      final ctrl = build();
      await ctrl.load();

      await ctrl.commitAdjust('Brightness');

      expect(ctrl.history, isEmpty);
      expect(ctrl.canUndo.value, isFalse);
    });

    test('a new edit after undo discards the redo tail', () async {
      final ctrl = build();
      await ctrl.load();

      ctrl.setAdjust(brightness: 40);
      await ctrl.commitAdjust('Brightness');
      ctrl.setAdjust(contrast: 30);
      await ctrl.commitAdjust('Contrast');
      await ctrl.undo();

      ctrl.setAdjust(saturation: 25);
      await ctrl.commitAdjust('Saturation');

      expect(ctrl.canRedo.value, isFalse);
      expect(ctrl.history.map((o) => o.label), ['Brightness', 'Saturation']);
    });

    test('jumpTo(0) returns to the untouched original', () async {
      final ctrl = build();
      await ctrl.load();
      final original = _shownLuminance(ctrl);

      ctrl.setAdjust(brightness: 70);
      await ctrl.commitAdjust('Brightness');
      await ctrl.jumpTo(0);

      expect(ctrl.historyCursor.value, 0);
      expect(ctrl.brightness.value, 0);
      expect((_shownLuminance(ctrl) - original).abs(), lessThan(3));
      expect(ctrl.history.length, 1, reason: 'the entry stays visible as redo tail');
    });

    test('the original file on disk is never modified', () async {
      final before = await source.readAsBytes();
      final ctrl = build();
      await ctrl.load();

      ctrl.setAdjust(brightness: 90, contrast: 50, saturation: -40, sharpness: 60);
      await ctrl.commitAdjust('Brightness');

      expect(await source.readAsBytes(), before,
          reason: 'editing is non-destructive: the stack is replayed, never written back');
    });

    test('resetAdjust returns every slider to zero as one entry', () async {
      final ctrl = build();
      await ctrl.load();

      ctrl.setAdjust(brightness: 60, contrast: 40);
      await ctrl.commitAdjust('Brightness');
      await ctrl.resetAdjust();

      expect(ctrl.brightness.value, 0);
      expect(ctrl.contrast.value, 0);
      expect(ctrl.history.last.label, 'Reset');
      expect(ctrl.canUndo.value, isTrue, reason: 'reset itself is undoable');
    });
  });

  group('render responsiveness', () {
    test('colour edits never re-render the base image', () async {
      final ctrl = build();
      await ctrl.load();
      final base = ctrl.previewBase.value;

      ctrl.setAdjust(brightness: 50, contrast: 20, saturation: -30);
      await ctrl.commitAdjust('Brightness');
      await ctrl.undo();
      await ctrl.redo();

      expect(identical(ctrl.previewBase.value, base), isTrue,
          reason: 'brightness/contrast/saturation are a GPU colour matrix');
      expect(ctrl.isRendering.value, isFalse);
    });

    test('a burst of version taps settles on the last one', () async {
      final ctrl = build();
      await ctrl.load();
      for (final (label, value) in [('Sharpness', 60.0), ('Brightness', 40.0)]) {
        if (label == 'Sharpness') ctrl.setAdjust(sharpness: value);
        if (label == 'Brightness') ctrl.setAdjust(brightness: value);
        await ctrl.commitAdjust(label);
      }
      final sharpened = ctrl.previewBase.value;

      // Tapped without waiting, like a user hopping along the strip.
      final taps = [ctrl.jumpTo(0), ctrl.jumpTo(2), ctrl.jumpTo(1), ctrl.jumpTo(0), ctrl.jumpTo(2)];
      await Future.wait(taps);

      expect(ctrl.historyCursor.value, 2);
      expect(ctrl.sharpness.value, 60);
      expect(ctrl.brightness.value, 40);
      expect(identical(ctrl.previewBase.value, sharpened), isTrue,
          reason: 'a sharpness already rendered comes from the cache');
    });

    test('jumping back to the original reuses the unsharpened source', () async {
      final ctrl = build();
      await ctrl.load();
      final source = ctrl.previewBase.value;

      ctrl.setAdjust(sharpness: 80);
      await ctrl.commitAdjust('Sharpness');
      expect(identical(ctrl.previewBase.value, source), isFalse);

      await ctrl.jumpTo(0);
      expect(identical(ctrl.previewBase.value, source), isTrue);
    });
  });
}
