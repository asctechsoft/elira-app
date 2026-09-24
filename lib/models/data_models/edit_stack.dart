import 'edit_operation.dart';

/// Undo/redo as a cursor over an operation list, not a list of rendered
/// images: history survives regardless of what has been rendered to disk, and
/// memory stays flat no matter how deep the stack goes (spec 18).
class EditStack {
  final List<EditOperation> _ops = [];

  /// Number of operations currently applied. Everything at or past this index
  /// is redoable but not active.
  int _cursor = 0;

  int get cursor => _cursor;

  /// Full list including the redoable tail, for rendering the history strip.
  List<EditOperation> get operations => List.unmodifiable(_ops);

  List<EditOperation> get applied => List.unmodifiable(_ops.take(_cursor));

  bool get canUndo => _cursor > 0;

  bool get canRedo => _cursor < _ops.length;

  bool get isEmpty => _ops.isEmpty;

  EditState get state =>
      _ops.take(_cursor).fold(EditState.initial, (s, op) => s.apply(op));

  /// Pushing after an undo discards the redo tail — the standard editor
  /// behaviour, and the reason redo cannot resurrect a branch.
  void push(EditOperation op) {
    if (_cursor < _ops.length) _ops.removeRange(_cursor, _ops.length);
    _ops.add(op);
    _cursor = _ops.length;
  }

  /// Replaces the most recent operation instead of stacking a new one. Used
  /// while a slider is still being dragged so one gesture produces one history
  /// entry rather than one per pixel of travel.
  void replaceLast(EditOperation op) {
    if (_cursor == 0) {
      push(op);
      return;
    }
    if (_cursor < _ops.length) _ops.removeRange(_cursor, _ops.length);
    _ops[_cursor - 1] = op;
  }

  EditOperation? get last => _cursor == 0 ? null : _ops[_cursor - 1];

  bool undo() {
    if (!canUndo) return false;
    _cursor--;
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _cursor++;
    return true;
  }

  /// Jumps the cursor straight to a point in history, for tapping an entry in
  /// the version strip. [index] is the number of operations to apply, so 0 is
  /// the untouched original.
  bool jumpTo(int index) {
    if (index < 0 || index > _ops.length || index == _cursor) return false;
    _cursor = index;
    return true;
  }

  void clear() {
    _ops.clear();
    _cursor = 0;
  }

  void replaceAt(int index, EditOperation op) {
    if (index < 0 || index >= _ops.length) return;
    _ops[index] = op;
  }
}
