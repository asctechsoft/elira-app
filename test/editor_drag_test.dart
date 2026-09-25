// Drags on the editor overlays. A real touchscreen delivers several pointer
// events per frame, so these tests move the pointer repeatedly *without*
// pumping in between: an overlay that adds each delta to the value it saw at
// its last build drops all but one of those moves and lags behind the finger.

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/models/data_models/text_layer.dart';
import 'package:elira/models/ui_models/editor_tool.dart';
import 'package:elira/presentation/screen_editor/widgets/crop_overlay.dart';
import 'package:elira/presentation/screen_editor/widgets/text_overlay.dart';
import 'package:elira/values/text_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const double _side = 400;

Widget _host(Widget overlay) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: _side, height: _side, child: overlay),
        ),
      ),
    );

/// Several moves inside one frame, then a single pump.
Future<void> _dragWithoutPumping(
  WidgetTester tester,
  Offset from, {
  required Offset step,
  required int steps,
}) async {
  final gesture = await tester.startGesture(from);
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step);
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
    TextFonts.allowDownloadableFonts = false;
  });
  tearDown(Get.reset);

  testWidgets('a text layer follows every move within a frame', (tester) async {
    final ctrl = EditorController()..activeTool.value = EditorTool.text;
    ctrl.texts.add(const TextLayer(id: 't1', text: 'Hello'));
    ctrl.selectedTextId.value = 't1';

    await tester.pumpWidget(_host(TextOverlay(ctrl: ctrl)));
    await _dragWithoutPumping(
      tester,
      tester.getCenter(find.text('Hello')),
      step: const Offset(10, 5),
      steps: 10,
    );

    final layer = ctrl.texts.single;
    expect(layer.dx, closeTo(0.5 + 100 / _side, 0.005));
    expect(layer.dy, closeTo(0.5 + 50 / _side, 0.005));
  });

  testWidgets('the crop box follows every move within a frame', (tester) async {
    final ctrl = EditorController()..isCropping.value = true;
    ctrl.setCropRect(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75);

    await tester.pumpWidget(_host(CropOverlay(ctrl: ctrl)));
    await _dragWithoutPumping(
      tester,
      const Offset(_side / 2, _side / 2),
      step: const Offset(10, 0),
      steps: 5,
    );

    final g = ctrl.geometry.value;
    expect(g.left, closeTo(0.25 + 50 / _side, 0.005));
    expect(g.right, closeTo(0.75 + 50 / _side, 0.005));
    expect(g.top, closeTo(0.25, 0.005));
  });

  testWidgets('a crop corner follows every move within a frame', (tester) async {
    final ctrl = EditorController()..isCropping.value = true;
    ctrl.setCropRect(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75);

    await tester.pumpWidget(_host(CropOverlay(ctrl: ctrl)));
    await _dragWithoutPumping(
      tester,
      const Offset(_side * 0.75, _side * 0.75),
      step: const Offset(10, 10),
      steps: 5,
    );

    final g = ctrl.geometry.value;
    expect(g.right, closeTo(0.75 + 50 / _side, 0.005));
    expect(g.bottom, closeTo(0.75 + 50 / _side, 0.005));
    expect(g.left, closeTo(0.25, 0.005), reason: 'the opposite corner stays put');
  });

  testWidgets('dragging text or crop does not rebuild the photo canvas', (tester) async {
    final ctrl = EditorController();
    ctrl.texts.add(const TextLayer(id: 't1', text: 'x'));
    var builds = 0;
    // Subscribes exactly like the canvas does: by reading colorMatrix.
    await tester.pumpWidget(_host(Obx(() {
      ctrl.colorMatrix;
      builds++;
      return const SizedBox();
    })));
    expect(builds, 1);

    ctrl.updateText('t1', dx: 0.2);
    ctrl.setCropRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9);
    await tester.pump();
    expect(builds, 1, reason: 'text and crop are overlays, not colour inputs');

    ctrl.setAdjust(brightness: 20);
    await tester.pump();
    expect(builds, 2, reason: 'a colour input still repaints the canvas');
  });
}
