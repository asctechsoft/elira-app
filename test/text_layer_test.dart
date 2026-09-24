import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:elira/models/data_models/text_layer.dart';
import 'package:elira/models/ui_models/editor_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

EditProject _project(String path) {
  final now = DateTime.now();
  return EditProject(
    id: 'p_1',
    name: 'Trip',
    originalPath: path,
    width: 400,
    height: 400,
    createdAt: now,
    updatedAt: now,
  );
}

Uint8List _jpeg() {
  final image = img.Image(width: 60, height: 60);
  img.fill(image, color: img.ColorRgb8(120, 130, 140));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  group('TextLayer model', () {
    const layer = TextLayer(
      id: 't1',
      text: 'Hello',
      fontId: 'serif',
      color: 0xFF2B7EFB,
      align: TextLayerAlign.right,
      dx: 0.25,
      dy: 0.8,
      size: 0.12,
    );

    test('round-trips through a map', () {
      expect(TextLayer.fromMap(layer.toMap()), layer);
    });

    test('a malformed map decodes to usable defaults', () {
      final decoded = TextLayer.fromMap(const {
        'id': 't2',
        'text': 'Hi',
        'align': 'diagonal',
        'dx': 'somewhere',
        'color': 'blue',
      });

      expect(decoded.align, TextLayerAlign.center);
      expect(decoded.dx, 0.5);
      expect(decoded.color, 0xFFFFFFFF);
      expect(decoded.fontId, TextLayer.defaultFontId);
    });

    test('copyWith keeps the id, because the id is the identity', () {
      expect(layer.copyWith(text: 'Bye').id, 't1');
    });

    test('blank text is detectable', () {
      expect(layer.copyWith(text: '   ').isBlank, isTrue);
      expect(layer.isBlank, isFalse);
    });
  });

  group('text in the edit state', () {
    test('a text operation replaces the whole layer list', () {
      const start = EditState(
        adjust: AdjustParams(brightness: 30),
        texts: [TextLayer(id: 'a', text: 'One')],
      );

      final next = start.apply(EditOperation(
        type: EditOperationType.text,
        label: 'Text',
        params: EditState.textsToMap(const [
          TextLayer(id: 'a', text: 'One'),
          TextLayer(id: 'b', text: 'Two'),
        ]),
      ));

      expect(next.texts.length, 2);
      expect(next.adjust.brightness, 30, reason: 'text owns only its own slice');
    });

    test('text is not spatial work, so it never triggers a render', () {
      const bare = EditState();
      const captioned = EditState(texts: [TextLayer(id: 'a', text: 'Hi')]);

      expect(captioned.spatialKey, bare.spatialKey);
      expect(captioned.isSpatialIdentity, isTrue);
      expect(captioned.isIdentity, isFalse, reason: 'it is still an edit');
    });

    test('states differing only by text are not equal', () {
      const a = EditState(texts: [TextLayer(id: 'a', text: 'Hi')]);
      const b = EditState(texts: [TextLayer(id: 'a', text: 'Bye')]);

      expect(a == b, isFalse);
      expect(a == const EditState(texts: [TextLayer(id: 'a', text: 'Hi')]), isTrue);
    });

    test('a full state with text round-trips', () {
      const state = EditState(
        filter: FilterParams(id: 'warm', strength: 70),
        texts: [
          TextLayer(id: 'a', text: 'One', fontId: 'mono'),
          TextLayer(id: 'b', text: 'Two', dy: 0.9),
        ],
      );

      expect(EditState.fromMap(state.toMap()), state);
    });

    test('a document with no text key decodes to no layers', () {
      expect(EditState.fromMap(const {'texts': 'nonsense'}).texts, isEmpty);
    });
  });

  group('editor controller', () {
    late Directory tmp;
    late File source;

    setUp(() async {
      Get.testMode = true;
      tmp = await Directory.systemTemp.createTemp('elira_text_test');
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

    test('adding text creates a selected, undoable layer', () async {
      final ctrl = await open();

      await ctrl.addText('Santorini');

      expect(ctrl.texts.single.text, 'Santorini');
      expect(ctrl.selectedTextId.value, ctrl.texts.single.id);
      expect(ctrl.history.map((o) => o.label), ['Text']);

      await ctrl.undo();
      expect(ctrl.texts, isEmpty);
    });

    test('adding text does not re-render the photo', () async {
      final ctrl = await open();
      final base = ctrl.previewBase.value;

      await ctrl.addText('Caption');

      expect(identical(ctrl.previewBase.value, base), isTrue,
          reason: 'text is drawn over the canvas, not baked into it');
    });

    test('dragging updates the layer and clamps it to the photo', () async {
      final ctrl = await open();
      await ctrl.addText('Caption');
      final id = ctrl.texts.single.id;

      ctrl.updateText(id, dx: 1.8, dy: -0.4);

      expect(ctrl.texts.single.dx, 1.0);
      expect(ctrl.texts.single.dy, 0.0);
    });

    test('size is clamped to something still readable', () async {
      final ctrl = await open();
      await ctrl.addText('Caption');
      final id = ctrl.texts.single.id;

      ctrl.updateText(id, size: 9);
      expect(ctrl.texts.single.size, 0.4);

      ctrl.updateText(id, size: 0);
      expect(ctrl.texts.single.size, 0.02);
    });

    test('successive edits of one layer collapse into a single entry', () async {
      final ctrl = await open();
      await ctrl.addText('Caption');
      final id = ctrl.texts.single.id;

      for (final colour in [0xFF111827, 0xFF2B7EFB, 0xFFEF4444]) {
        ctrl.updateText(id, color: colour);
        await ctrl.commitText('Text');
      }

      expect(ctrl.history.length, 1, reason: 'one caption, one history entry');
      expect(ctrl.texts.single.color, 0xFFEF4444);
    });

    test('clearing the text of a layer removes it rather than hiding it',
        () async {
      final ctrl = await open();
      await ctrl.addText('Caption');
      final id = ctrl.texts.single.id;

      ctrl.updateText(id, text: '   ');
      await ctrl.commitText('Text');

      expect(ctrl.texts, isEmpty,
          reason: 'an invisible layer could never be selected again');
    });

    test('deleting clears the selection', () async {
      final ctrl = await open();
      await ctrl.addText('One');
      final id = ctrl.texts.single.id;

      await ctrl.removeText(id);

      expect(ctrl.texts, isEmpty);
      expect(ctrl.selectedTextId.value, isNull);
    });

    test('text survives a filter and a crop', () async {
      final ctrl = await open();
      await ctrl.addText('Caption');
      await ctrl.selectFilter('bw');
      ctrl.setCropRect(left: 0, top: 0, right: 0.6, bottom: 1);
      await ctrl.applyCrop();

      expect(ctrl.texts.single.text, 'Caption');
      expect(ctrl.stack.state.texts.single.text, 'Caption');
    });

    test('leaving the Text tab drops the selection, not the layer', () async {
      final ctrl = await open();
      await ctrl.addText('Caption');

      ctrl.setTool(EditorTool.adjust);

      expect(ctrl.selectedTextId.value, isNull);
      expect(ctrl.texts.length, 1);
    });

    test('displayAspect follows the crop so a layer stays where it was put',
        () async {
      final ctrl = await open();
      expect(ctrl.displayAspect, closeTo(1, 0.001));

      ctrl.setCropRect(left: 0, top: 0, right: 0.5, bottom: 1);
      await ctrl.applyCrop();

      expect(ctrl.displayAspect, closeTo(0.5, 0.001));
    });
  });
}
