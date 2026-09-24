import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/models/data_models/edit_stack.dart';
import 'package:flutter_test/flutter_test.dart';

EditOperation _adjust(String label, {double brightness = 0, double contrast = 0}) =>
    EditOperation(
      type: EditOperationType.adjust,
      label: label,
      params: AdjustParams(brightness: brightness, contrast: contrast).toMap(),
    );

void main() {
  late EditStack stack;

  setUp(() => stack = EditStack());

  test('starts empty with nothing to undo or redo', () {
    expect(stack.canUndo, isFalse);
    expect(stack.canRedo, isFalse);
    expect(stack.cursor, 0);
    expect(stack.state.isIdentity, isTrue);
  });

  test('push makes the operation undoable and folds into state', () {
    stack.push(_adjust('Brightness', brightness: 30));

    expect(stack.canUndo, isTrue);
    expect(stack.canRedo, isFalse);
    expect(stack.state.adjust.brightness, 30);
  });

  test('undo walks back to the previous state, redo walks forward', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.push(_adjust('Contrast', brightness: 30, contrast: 20));

    expect(stack.state.adjust.contrast, 20);

    expect(stack.undo(), isTrue);
    expect(stack.state.adjust.contrast, 0);
    expect(stack.state.adjust.brightness, 30);
    expect(stack.canRedo, isTrue);

    expect(stack.undo(), isTrue);
    expect(stack.state.isIdentity, isTrue);
    expect(stack.canUndo, isFalse);

    expect(stack.redo(), isTrue);
    expect(stack.state.adjust.brightness, 30);
    expect(stack.redo(), isTrue);
    expect(stack.state.adjust.contrast, 20);
    expect(stack.canRedo, isFalse);
  });

  test('undo and redo report false when there is nowhere to go', () {
    expect(stack.undo(), isFalse);
    expect(stack.redo(), isFalse);
  });

  test('pushing after an undo discards the redo tail', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.push(_adjust('Contrast', brightness: 30, contrast: 20));
    stack.undo();
    expect(stack.canRedo, isTrue);

    stack.push(_adjust('Saturation', brightness: 30));

    expect(stack.canRedo, isFalse, reason: 'the discarded branch cannot come back');
    expect(stack.operations.length, 2);
    expect(stack.state.adjust.contrast, 0);
  });

  test('replaceLast collapses a drag into one entry', () {
    stack.push(_adjust('Brightness', brightness: 10));
    stack.replaceLast(_adjust('Brightness', brightness: 40));
    stack.replaceLast(_adjust('Brightness', brightness: 65));

    expect(stack.operations.length, 1);
    expect(stack.state.adjust.brightness, 65);
    expect(stack.canUndo, isTrue);

    stack.undo();
    expect(stack.state.isIdentity, isTrue, reason: 'one undo clears the whole drag');
  });

  test('replaceLast on an empty stack behaves like push', () {
    stack.replaceLast(_adjust('Brightness', brightness: 15));
    expect(stack.operations.length, 1);
    expect(stack.state.adjust.brightness, 15);
  });

  test('jumpTo moves straight to a point in history', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.push(_adjust('Contrast', brightness: 30, contrast: 20));
    stack.push(_adjust('Saturation', brightness: 30, contrast: 20));

    expect(stack.jumpTo(0), isTrue);
    expect(stack.state.isIdentity, isTrue);
    expect(stack.canUndo, isFalse);
    expect(stack.canRedo, isTrue);

    expect(stack.jumpTo(2), isTrue);
    expect(stack.state.adjust.contrast, 20);

    expect(stack.jumpTo(2), isFalse, reason: 'already there');
    expect(stack.jumpTo(-1), isFalse);
    expect(stack.jumpTo(99), isFalse);
  });

  test('redo tail stays visible for the version strip after an undo', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.push(_adjust('Contrast', brightness: 30, contrast: 20));
    stack.undo();

    expect(stack.operations.length, 2, reason: 'strip shows the dimmed redo tail');
    expect(stack.applied.length, 1);
  });

  test('adjust operations are last-wins, not cumulative', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.push(_adjust('Brightness', brightness: 10));

    expect(stack.state.adjust.brightness, 10,
        reason: 'each operation carries the full parameter set');
  });

  test('clear resets everything', () {
    stack.push(_adjust('Brightness', brightness: 30));
    stack.clear();

    expect(stack.isEmpty, isTrue);
    expect(stack.canUndo, isFalse);
    expect(stack.state.isIdentity, isTrue);
  });

  group('AdjustParams', () {
    test('identity detection', () {
      expect(AdjustParams.identity.isIdentity, isTrue);
      expect(const AdjustParams(brightness: 1).isIdentity, isFalse);
    });

    test('round-trips through a map, defaulting missing keys', () {
      const params = AdjustParams(brightness: 12, contrast: -4, saturation: 8, sharpness: 30);
      expect(AdjustParams.fromMap(params.toMap()), params);
      expect(AdjustParams.fromMap(const {'brightness': 5}),
          const AdjustParams(brightness: 5));
      expect(AdjustParams.fromMap(const {'brightness': 'nope'}), AdjustParams.identity);
    });
  });
}
