import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:elira/models/ui_models/editor_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

EditProject _project(String path) {
  final now = DateTime.now();
  return EditProject(
    id: 'p_1',
    name: 'Santorini Trip',
    originalPath: path,
    width: 3024,
    height: 4032,
    createdAt: now,
    updatedAt: now,
  );
}

Uint8List _jpeg({int shade = 130, int width = 60, int height = 80}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(shade, shade, shade));
  img.fillRect(image,
      x1: 0,
      y1: 0,
      x2: width ~/ 2,
      y2: height ~/ 2,
      color: img.ColorRgb8(shade + 40, 60, 40));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

void main() {
  late Directory tmp;
  late File source;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('elira_tools_test');
    source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
    await source.writeAsBytes(_jpeg());
  });

  tearDown(() async {
    Get.reset();
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<EditorController> open() async {
    final ctrl = EditorController(renderDelay: Duration.zero);
    ctrl.setProject(_project(source.path));
    await ctrl.load();
    return ctrl;
  }

  group('filters', () {
    test('choosing a look adds one entry and keeps the sliders', () async {
      final ctrl = await open();
      ctrl.setAdjust(brightness: 40);
      await ctrl.commitAdjust('Brightness');

      await ctrl.selectFilter('bw');

      expect(ctrl.stack.state.filter.id, 'bw');
      expect(ctrl.brightness.value, 40,
          reason: 'a filter is a look, not a reset of the user corrections');
      expect(ctrl.history.map((o) => o.label), ['Brightness', 'B&W']);
    });

    test('choosing the same look twice changes nothing', () async {
      final ctrl = await open();
      await ctrl.selectFilter('warm');
      await ctrl.selectFilter('warm');

      expect(ctrl.history.length, 1);
    });

    test('strength tweaks collapse into the one filter entry', () async {
      final ctrl = await open();
      await ctrl.selectFilter('warm');

      for (final value in [80.0, 60.0, 35.0]) {
        ctrl.setFilterStrength(value);
        await ctrl.commitFilter();
      }

      expect(ctrl.history.length, 1, reason: 'one look, one history entry');
      expect(ctrl.stack.state.filter.strength, 35);
    });

    test('undo steps back to the previously chosen look', () async {
      final ctrl = await open();
      await ctrl.selectFilter('bw');
      await ctrl.selectFilter('warm');

      await ctrl.undo();

      expect(ctrl.filterId.value, 'bw');
      expect(ctrl.stack.state.filter.id, 'bw');
    });

    test('the filter strip gets a swatch to draw', () async {
      final ctrl = await open();

      // The swatch is rendered off the load path on purpose, so the photo
      // appears without waiting on it. Hence the poll rather than an await.
      for (var i = 0; i < 100 && ctrl.swatchBase.value == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(ctrl.swatchBase.value, isNotNull);
    });
  });

  group('colour work never costs a render', () {
    test('sliders and filters leave the cached CPU base untouched', () async {
      final ctrl = await open();
      final base = ctrl.previewBase.value;
      expect(base, isNotNull);

      ctrl.setAdjust(brightness: 70, contrast: 30, saturation: -40);
      await ctrl.commitAdjust('Brightness');
      await ctrl.selectFilter('cinematic');

      expect(identical(ctrl.previewBase.value, base), isTrue,
          reason: 'these are GPU-only; re-rendering pixels would be waste');
      // The change is real, it just lives in the matrix the canvas applies.
      expect(ctrl.colorMatrix, isNot(ctrl.adjustMatrix));
    });

    test('sharpness does re-render, because it is spatial', () async {
      final ctrl = await open();
      final base = ctrl.previewBase.value;

      ctrl.setAdjust(sharpness: 60);
      await ctrl.commitAdjust('Sharpness');

      expect(identical(ctrl.previewBase.value, base), isFalse);
    });
  });

  group('effects', () {
    test('each effect keeps its own value instead of replacing the last',
        () async {
      final ctrl = await open();

      ctrl.setEffect(vignette: 50);
      await ctrl.commitEffects('Vignette');
      ctrl.setEffect(grain: 30);
      await ctrl.commitEffects('Grain');

      expect(ctrl.stack.state.effects.vignette, 50);
      expect(ctrl.stack.state.effects.grain, 30);
      expect(ctrl.history.map((o) => o.label), ['Vignette', 'Grain']);
    });

    test('clear all resets every effect as one undoable step', () async {
      final ctrl = await open();
      ctrl.setEffect(vignette: 50, glow: 20);
      await ctrl.commitEffects('Vignette');

      await ctrl.clearEffects();

      expect(ctrl.stack.state.effects.isIdentity, isTrue);
      expect(ctrl.canUndo.value, isTrue);
      await ctrl.undo();
      expect(ctrl.vignette.value, 50);
    });

    test('an effect does not disturb the filter or the crop', () async {
      final ctrl = await open();
      await ctrl.selectFilter('fade');
      ctrl.setEffect(grain: 25);
      await ctrl.commitEffects('Grain');

      expect(ctrl.stack.state.filter.id, 'fade');
      expect(ctrl.filterId.value, 'fade');
    });
  });

  group('crop', () {
    test('opening the tool shows the frame without its crop', () async {
      final ctrl = await open();
      ctrl.setCropRect(left: 0, top: 0, right: 0.5, bottom: 1);
      await ctrl.applyCrop();

      ctrl.setTool(EditorTool.crop);

      expect(ctrl.isCropping.value, isTrue);
      expect(ctrl.previewState.geometry.hasCrop, isFalse,
          reason: 'the box is re-dragged over the whole frame');
      expect(ctrl.currentState.geometry.hasCrop, isTrue,
          reason: 'the crop itself is still part of the edit');
    });

    test('a ratio snaps the box to the largest centred rectangle', () async {
      final ctrl = await open();
      ctrl.setTool(EditorTool.crop);

      ctrl.setCropRatio(1);

      final g = ctrl.geometry.value;
      // The frame is 3024x4032, so a square crop is full width.
      expect(g.cropWidth, closeTo(1, 0.001));
      expect(g.cropHeight, closeTo(0.75, 0.001));
      expect(g.top, closeTo(0.125, 0.001));
    });

    test('applying commits the geometry and leaves crop mode', () async {
      final ctrl = await open();
      ctrl.setTool(EditorTool.crop);
      ctrl.setCropRatio(1);

      await ctrl.applyCrop();

      expect(ctrl.isCropping.value, isFalse);
      expect(ctrl.stack.state.geometry.hasCrop, isTrue);
      expect(ctrl.history.last.label, 'Crop');
    });

    test('leaving the tool without applying discards the box', () async {
      final ctrl = await open();
      ctrl.setTool(EditorTool.crop);
      ctrl.setCropRatio(1);
      expect(ctrl.geometry.value.hasCrop, isTrue);

      ctrl.setTool(EditorTool.adjust);

      expect(ctrl.geometry.value.hasCrop, isFalse);
      expect(ctrl.stack.state.geometry.hasCrop, isFalse);
      expect(ctrl.history, isEmpty);
    });

    test('rotating carries the committed crop instead of dropping it',
        () async {
      final ctrl = await open();
      ctrl.setCropRect(left: 0, top: 0, right: 0.5, bottom: 1);
      await ctrl.applyCrop();

      await ctrl.rotate();

      expect(ctrl.stack.state.geometry.quarterTurns, 1);
      expect(ctrl.stack.state.geometry.hasCrop, isTrue);
    });

    test('flips are undoable steps of their own', () async {
      final ctrl = await open();
      await ctrl.flipHorizontal();
      await ctrl.flipVertical();

      expect(ctrl.stack.state.geometry.flipH, isTrue);
      expect(ctrl.stack.state.geometry.flipV, isTrue);
      expect(ctrl.history.map((o) => o.label), ['Flip H', 'Flip V']);

      await ctrl.undo();
      expect(ctrl.geometry.value.flipV, isFalse);
      expect(ctrl.geometry.value.flipH, isTrue);
    });

    test('a crop keeps the colour work that came before it', () async {
      final ctrl = await open();
      ctrl.setAdjust(brightness: 35);
      await ctrl.commitAdjust('Brightness');
      await ctrl.selectFilter('cool');

      ctrl.setTool(EditorTool.crop);
      ctrl.setCropRatio(16 / 9);
      await ctrl.applyCrop();

      expect(ctrl.brightness.value, 35);
      expect(ctrl.filterId.value, 'cool');
      expect(ctrl.stack.state.geometry.hasCrop, isTrue);
    });
  });

  group('auto', () {
    test('moves the sliders and leaves them editable', () async {
      await source.writeAsBytes(_jpeg(shade: 30));
      final ctrl = await open();

      await ctrl.autoEnhance();

      expect(ctrl.brightness.value, greaterThan(0),
          reason: 'the photo is dark, so Auto should lift it');
      expect(ctrl.isAutoRunning.value, isFalse);
      expect(ctrl.history.map((o) => o.label), ['Auto']);

      // Still a normal history entry: it can be undone like anything else.
      await ctrl.undo();
      expect(ctrl.brightness.value, 0);
    });

    test('running auto twice does not stack a second entry', () async {
      await source.writeAsBytes(_jpeg(shade: 30));
      final ctrl = await open();

      await ctrl.autoEnhance();
      await ctrl.autoEnhance();

      expect(ctrl.history.length, 1, reason: 'the second run is a no-op');
    });
  });
}
