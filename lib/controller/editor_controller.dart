import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/data_models/edit_operation.dart';
import '../models/data_models/edit_project.dart';
import '../data/presets/preset_repository.dart';
import '../data/projects/project_repository.dart';
import '../data/projects/project_sync.dart';
import '../models/data_models/ai_tool.dart';
import '../models/data_models/edit_stack.dart';
import '../models/data_models/photo_template.dart';
import '../models/data_models/user_preset.dart';
import '../models/data_models/text_layer.dart';
import '../models/ui_models/editor_tool.dart';
import '../services/image_pipeline.dart';
import '../services/photo_filters.dart';

class EditorController extends GetxController {
  EditorController({
    this.renderDelay = const Duration(milliseconds: 150),
    ProjectRepository? projects,
    PresetRepository? presets,
    BackgroundProjectSync? sync,
    this.saveDelay = const Duration(milliseconds: 600),
  })  : _projects = projects,
        _presets = presets,
        _sync = sync;

  /// Where the edit stack is written back to. Null in tests that do not care.
  final ProjectRepository? _projects;

  /// The user's saved looks.
  final PresetRepository? _presets;

  /// Cloud backup of the recipe. Never awaited on an edit path.
  final BackgroundProjectSync? _sync;

  /// Debounce before the stack is written to the database. A drag can produce
  /// many commits; the disk only needs the last one.
  final Duration saveDelay;

  /// Debounce before a spatial drag (sharpness, effects) triggers a CPU
  /// render. Colour sliders and filters never render on the CPU: the canvas
  /// applies [colorMatrix] on the GPU.
  final Duration renderDelay;

  final project = Rxn<EditProject>();
  final imagePath = ''.obs;
  final activeTool = EditorTool.adjust.obs;

  final canUndo = false.obs;
  final canRedo = false.obs;
  final isSaved = true.obs;
  final isLoading = false.obs;
  final isRendering = false.obs;
  final isAutoRunning = false.obs;
  final errorMessage = RxnString();

  /// Preview-sized source with geometry and every spatial effect applied. The
  /// canvas draws it through [colorMatrix], so colour edits and filters cost
  /// no pixel work at all. Null until the photo has loaded.
  final previewBase = Rxn<Uint8List>();

  /// A small copy of [previewBase] shared by every filter swatch. One render
  /// serves the whole strip: each swatch only differs by a GPU colour matrix.
  final swatchBase = Rxn<Uint8List>();

  /// History entries for the version strip, index 0 being the original.
  final history = <EditOperation>[].obs;
  final historyCursor = 0.obs;

  // Live values. These track the finger; the stack only learns about them
  // when the gesture ends.
  final brightness = 0.0.obs;
  final contrast = 0.0.obs;
  final saturation = 0.0.obs;
  final sharpness = 0.0.obs;

  final filterId = FilterParams.none.obs;
  final filterStrength = 100.0.obs;

  final vignette = 0.0.obs;
  final grain = 0.0.obs;
  final blur = 0.0.obs;
  final glow = 0.0.obs;

  final geometry = GeometryParams.identity.obs;

  /// Text layers drawn over the photo, plus which one the panel is editing.
  final texts = <TextLayer>[].obs;
  final selectedTextId = RxnString();

  /// While true the canvas shows the frame *without* its crop, so the crop
  /// box can be re-dragged over the whole image the way every editor does.
  final isCropping = false.obs;

  /// Looks the user saved, newest used first.
  final presets = <UserPreset>[].obs;

  /// Locked crop aspect (width / height), or null for a free-form box. Both
  /// the panel and the drag handles read this, so a preset stays enforced
  /// while a corner is dragged instead of only at the moment it is tapped.
  final cropRatio = Rxn<double>();

  final EditStack _stack = EditStack();

  /// Downscaled copy of the untouched original, decoded once and reused for
  /// every preview render.
  Uint8List? _previewSource;

  Timer? _debounce;
  Timer? _saveDebounce;
  int _loadToken = 0;
  int _swatchToken = 0;

  /// The file [_previewSource] was decoded from. An AI result changes this,
  /// and undoing past that step changes it back.
  String? _loadedPath;

  /// Spatial key [previewBase] was rendered at.
  String _baseKey = EditState.initial.spatialKey;

  /// Rendered bases by spatial key, so hopping between versions that differ
  /// only in colour does not re-render. Small: each entry is one
  /// preview-sized JPEG.
  final Map<String, Uint8List> _baseCache = {};
  static const int _baseCacheSize = 6;
  static final String _identityKey = EditState.initial.spatialKey;

  /// The single in-flight base render. Renders never run in parallel: a burst
  /// of taps waits on this and then renders only the latest value, instead of
  /// several isolates fighting over the CPU for results that get thrown away.
  Future<void>? _baseInFlight;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is EditProject) {
      _adopt(arg);
    } else if (arg is String && arg.isNotEmpty) {
      // Still accepted so a bare path (deep link, older call site) opens.
      imagePath.value = arg;
      unawaited(load());
    }
  }

  void _adopt(EditProject value) {
    unawaited(loadPresets());
    project.value = value;
    imagePath.value = value.originalPath;
    final tool = _toolFromId(value.initialTool);
    if (tool != null) activeTool.value = tool;
    _restoreSavedStack(value);
    unawaited(load());
  }

  /// Rebuilds the edit stack saved with the project, so reopening a draft from
  /// Home lands exactly where it was left — including its undo history.
  void _restoreSavedStack(EditProject value) {
    _stack.clear();
    final saved = value.adjustments['operations'];
    if (saved is! List || saved.isEmpty) {
      _restoreFromStack();
      _syncStackFlags();
      return;
    }
    try {
      _stack.restore(
        saved
            .whereType<Map>()
            .map((m) =>
                EditOperation.fromMap(m.map((k, v) => MapEntry(k.toString(), v))))
            .toList(),
      );
    } catch (error) {
      // A draft written by a newer build must not make the editor refuse to
      // open; losing the history is the lesser failure.
      debugPrint('[editor] could not restore the saved stack: $error');
      _stack.clear();
    }
    _restoreFromStack();
    _syncStackFlags();
  }

  /// Maps the Home quick-action ids onto editor tabs. The picker forwards the
  /// id it received from Home, so tapping "Remove" lands on Remove.
  EditorTool? _toolFromId(String? id) => switch (id) {
        'enhance' => EditorTool.adjust,
        'remove' => EditorTool.remove,
        'retouch' => EditorTool.retouch,
        'filters' => EditorTool.filters,
        'background' => EditorTool.background,
        'ai_magic' => EditorTool.ai,
        _ => null,
      };

  String get title => project.value?.name ?? 'Untitled';

  bool get hasEdits => _stack.cursor > 0;

  // ------------------------------------------------------------ live state

  AdjustParams get currentAdjust => AdjustParams(
        brightness: brightness.value,
        contrast: contrast.value,
        saturation: saturation.value,
        sharpness: sharpness.value,
      );

  FilterParams get currentFilter =>
      FilterParams(id: filterId.value, strength: filterStrength.value);

  EffectParams get currentEffects => EffectParams(
        vignette: vignette.value,
        grain: grain.value,
        blur: blur.value,
        glow: glow.value,
      );

  EditState get currentState => EditState(
        adjust: currentAdjust,
        filter: currentFilter,
        effects: currentEffects,
        geometry: geometry.value,
        texts: texts.toList(growable: false),
      );

  /// What the canvas is actually showing, which differs from [currentState]
  /// only while the crop box is open.
  EditState get previewState => isCropping.value
      ? currentState.copyWith(geometry: geometry.value.withoutCrop())
      : currentState;

  /// Read inside the canvas's Obx, so it subscribes to every colour input.
  List<double> get colorMatrix => ImagePipeline.colorMatrixFor(currentState);

  /// The adjust half only, for composing filter-strip swatches.
  List<double> get adjustMatrix => ImagePipeline.colorMatrix(currentAdjust);

  // ------------------------------------------------------------------ load

  /// The pixels the stack replays against: an applied AI result if there is
  /// one, otherwise the user's untouched original.
  String get effectiveSourcePath =>
      _stack.state.sourcePath ?? project.value?.originalPath ?? imagePath.value;

  Future<void> load() async {
    final path = effectiveSourcePath;
    if (path.isEmpty) return;

    final token = ++_loadToken;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final bytes = await File(path).readAsBytes();
      final source = await ImagePipeline.buildPreviewSource(bytes);
      // A later load (new project, retry) superseded this one.
      if (token != _loadToken) return;
      _previewSource = source;
      _baseCache
        ..clear()
        ..[_identityKey] = source;
      _baseKey = _identityKey;
      _loadedPath = path;
      previewBase.value = source;
      unawaited(_syncSwatch());
      await _syncBase();
      _syncStackFlags();
    } on ImagePipelineFailure catch (failure) {
      errorMessage.value = failure.message;
    } catch (error) {
      debugPrint('[editor] load failed: $error');
      errorMessage.value = 'Could not open that photo.';
    } finally {
      if (token == _loadToken) isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------- adjust

  /// Called continuously while a slider moves. Colour changes show on the next
  /// frame via [colorMatrix]; only a sharpness change schedules a CPU render.
  void setAdjust({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
  }) {
    if (brightness != null) this.brightness.value = brightness;
    if (contrast != null) this.contrast.value = contrast;
    if (saturation != null) this.saturation.value = saturation;
    if (sharpness != null) this.sharpness.value = sharpness;

    isSaved.value = false;
    if (sharpness != null) _scheduleBase();
  }

  Future<void> commitAdjust(String label) =>
      _commit(EditOperationType.adjust, label, currentAdjust.toMap());

  Future<void> resetAdjust() async {
    brightness.value = 0;
    contrast.value = 0;
    saturation.value = 0;
    sharpness.value = 0;
    await commitAdjust('Reset');
  }

  /// Analyses the photo and moves the Brightness/Contrast/Saturation sliders
  /// to the values it derives. The result stays editable: Auto is a starting
  /// point, not a mode.
  Future<void> autoEnhance() async {
    final source = _previewSource;
    if (source == null || isAutoRunning.value) return;

    isAutoRunning.value = true;
    try {
      final suggestion = await ImagePipeline.autoAdjust(source);
      brightness.value = suggestion.brightness;
      contrast.value = suggestion.contrast;
      saturation.value = suggestion.saturation;
      await commitAdjust('Auto');
    } on ImagePipelineFailure catch (failure) {
      errorMessage.value = failure.message;
    } catch (error) {
      debugPrint('[editor] auto failed: $error');
      errorMessage.value = 'Could not analyse this photo.';
    } finally {
      isAutoRunning.value = false;
    }
  }

  // ---------------------------------------------------------------- filter

  /// Selecting a look is instant and free — it only changes the matrix the
  /// canvas already applies every frame.
  Future<void> selectFilter(String id) async {
    if (filterId.value == id) return;
    filterId.value = id;
    if (filterStrength.value == 0) filterStrength.value = 100;
    isSaved.value = false;
    await commitFilter();
  }

  void setFilterStrength(double value) {
    filterStrength.value = value;
    isSaved.value = false;
  }

  Future<void> commitFilter() => _commit(
        EditOperationType.filter,
        PhotoFilters.byId(filterId.value).name,
        currentFilter.toMap(),
      );

  // --------------------------------------------------------------- effects

  void setEffect({double? vignette, double? grain, double? blur, double? glow}) {
    if (vignette != null) this.vignette.value = vignette;
    if (grain != null) this.grain.value = grain;
    if (blur != null) this.blur.value = blur;
    if (glow != null) this.glow.value = glow;

    isSaved.value = false;
    _scheduleBase();
  }

  Future<void> commitEffects(String label) =>
      _commit(EditOperationType.effects, label, currentEffects.toMap());

  Future<void> clearEffects() async {
    vignette.value = 0;
    grain.value = 0;
    blur.value = 0;
    glow.value = 0;
    await commitEffects('No Effect');
  }

  // ------------------------------------------------------------------ crop

  /// Width / height of the frame the crop box sits on, i.e. the original with
  /// its rotation applied but not its crop. Falls back to square when the
  /// project carries no dimensions, so the overlay can still lay itself out.
  double get frameAspect {
    final p = project.value;
    if (p == null || p.width <= 0 || p.height <= 0) return 1;
    final w = p.width.toDouble();
    final h = p.height.toDouble();
    return geometry.value.swapsAxes ? h / w : w / h;
  }

  void enterCrop() {
    if (isCropping.value) return;
    isCropping.value = true;
    unawaited(_syncBase());
  }

  void exitCrop() {
    if (!isCropping.value) return;
    isCropping.value = false;
    // Drop an uncommitted box: leaving the tool is not the same as confirming.
    geometry.value = _stack.state.geometry;
    unawaited(_syncBase());
  }

  /// Live update of the crop box while a handle is dragged. Nothing is
  /// rendered — the box is an overlay, and the pixels only change on confirm.
  void setCropRect({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    geometry.value = geometry.value
        .copyWith(left: left, top: top, right: right, bottom: bottom)
        .normalised();
    isSaved.value = false;
  }

  /// Snaps the box to the largest centred rectangle of [ratio] that fits the
  /// frame. Null means free-form and clears the box back to the full frame.
  void setCropRatio(double? ratio) {
    cropRatio.value = ratio;
    if (ratio == null) {
      geometry.value = geometry.value.withoutCrop();
      isSaved.value = false;
      return;
    }
    // Same maths a template uses to fit a ratio, kept in one place so a 1:1
    // crop from the panel and a 1:1 template cannot disagree.
    final box = PhotoTemplate.centeredCrop(
      frameAspect: frameAspect,
      ratio: ratio,
    );
    setCropRect(
      left: box.left,
      top: box.top,
      right: box.right,
      bottom: box.bottom,
    );
  }

  Future<void> rotate() async {
    geometry.value = geometry.value.rotatedCw();
    // The box was snapped to the old orientation, so a locked ratio has to be
    // re-fitted against the frame's new aspect rather than left skewed.
    if (cropRatio.value != null) setCropRatio(cropRatio.value);
    await _commitGeometry('Rotate');
  }

  Future<void> flipHorizontal() async {
    geometry.value = geometry.value.flippedH();
    await _commitGeometry('Flip H');
  }

  Future<void> flipVertical() async {
    geometry.value = geometry.value.flippedV();
    await _commitGeometry('Flip V');
  }

  /// Confirms the crop box and leaves crop mode.
  Future<void> applyCrop() async {
    isCropping.value = false;
    await _commitGeometry('Crop');
  }

  Future<void> resetCrop() async {
    cropRatio.value = null;
    geometry.value = geometry.value.withoutCrop();
    await _commitGeometry('Crop');
  }

  Future<void> _commitGeometry(String label) =>
      _commit(EditOperationType.crop, label, geometry.value.toMap());

  // ------------------------------------------------------------------ text

  /// Aspect of what the canvas is actually showing, crop included. Both the
  /// text overlay and the crop box lay themselves out against this, so a
  /// layer stays where it was put after the photo is cropped.
  double get displayAspect {
    final g = previewState.geometry;
    final base = frameAspect;
    if (!g.hasCrop || g.cropHeight <= 0) return base;
    return base * (g.cropWidth / g.cropHeight);
  }

  TextLayer? get selectedText {
    final id = selectedTextId.value;
    if (id == null) return null;
    for (final layer in texts) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  Future<void> addText(String value) async {
    final layer = TextLayer(
      id: 't_${DateTime.now().microsecondsSinceEpoch}',
      text: value,
    );
    texts.add(layer);
    selectedTextId.value = layer.id;
    await commitText('Text');
  }

  void selectText(String? id) => selectedTextId.value = id;

  /// Live edit while a layer is dragged or a control is held. Nothing is
  /// committed until [commitText], so one gesture is one history entry.
  void updateText(
    String id, {
    String? text,
    String? fontId,
    int? color,
    TextLayerAlign? align,
    double? dx,
    double? dy,
    double? size,
  }) {
    final index = texts.indexWhere((l) => l.id == id);
    if (index < 0) return;
    texts[index] = texts[index].copyWith(
      text: text,
      fontId: fontId,
      color: color,
      align: align,
      dx: dx?.clamp(0.0, 1.0),
      dy: dy?.clamp(0.0, 1.0),
      size: size?.clamp(0.02, 0.4),
    );
    texts.refresh();
    isSaved.value = false;
  }

  Future<void> removeText(String id) async {
    texts.removeWhere((l) => l.id == id);
    if (selectedTextId.value == id) selectedTextId.value = null;
    await commitText('Text');
  }

  /// Drops layers whose text was cleared, so an empty box never survives as an
  /// invisible layer the user cannot select again.
  Future<void> commitText(String label) async {
    texts.removeWhere((l) => l.isBlank);
    await _commit(
      EditOperationType.text,
      label,
      EditState.textsToMap(texts.toList(growable: false)),
    );
  }

  // ---------------------------------------------------------------- presets

  Future<void> loadPresets() async {
    final repository = _presets;
    if (repository == null) return;
    try {
      presets.value = await repository.all();
    } catch (error) {
      debugPrint('[editor] loading presets failed: $error');
    }
  }

  /// Saves the current colour and effect settings as a reusable look. The
  /// crop, the text and any AI result are left out on purpose: those belong to
  /// this photo, and a preset that carried them would do something different
  /// on the next one.
  Future<UserPreset?> saveAsPreset(String name) async {
    final repository = _presets;
    final trimmed = name.trim();
    if (repository == null || trimmed.isEmpty) return null;

    final preset = UserPreset.fromState(
      id: 'preset_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      state: currentState,
    );
    if (preset.isEmpty) {
      errorMessage.value = 'There is nothing to save yet.';
      return null;
    }

    try {
      await repository.save(preset);
      await loadPresets();
      return preset;
    } catch (error) {
      debugPrint('[editor] saving a preset failed: $error');
      errorMessage.value = 'Could not save that look.';
      return null;
    }
  }

  /// Applying a preset is ordinary editing: it pushes the same operations a
  /// hand-made edit would, so it is undoable step by step.
  Future<void> applyPreset(UserPreset preset) async {
    for (final op in preset.toOperations()) {
      _stack.push(op);
    }
    _restoreFromStack();
    _syncStackFlags();
    await _syncBase();
    unawaited(_syncSwatch());
    await _attachThumbnail();
    _scheduleSave();

    try {
      await _presets?.markUsed(preset.id);
      await loadPresets();
    } catch (error) {
      debugPrint('[editor] marking a preset used failed: $error');
    }
  }

  Future<void> deletePreset(String id) async {
    try {
      await _presets?.delete(id);
      await loadPresets();
    } catch (error) {
      debugPrint('[editor] deleting a preset failed: $error');
    }
  }

  // -------------------------------------------------------------------- ai

  /// Folds a finished AI result into the stack as an ordinary operation.
  ///
  /// The bytes are written to a new file beside the project rather than over
  /// the original, and the operation records that path. Everything already in
  /// the stack keeps replaying on top, and one undo returns to the photo as it
  /// was — an AI run is a step, not a point of no return.
  Future<void> applyAiResult({
    required AiTool tool,
    required Uint8List bytes,
    bool simulated = false,
  }) async {
    final project = this.project.value;
    if (project == null) return;

    try {
      final dir = Directory(project.originalPath).parent;
      final file = File(
        '${dir.path}${Platform.pathSeparator}ai_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);

      await _commit(EditOperationType.ai, tool.name, {
        'toolId': tool.id,
        'path': file.path,
        'simulated': simulated,
      });
      // _commit only refreshes the caches; the underlying file changed, so the
      // preview source itself has to be rebuilt.
      await load();
    } catch (error) {
      debugPrint('[editor] applying AI result failed: $error');
      errorMessage.value = 'Could not save the AI result.';
    }
  }

  // ------------------------------------------------------------ undo/redo

  Future<void> undo() async {
    if (!_stack.undo()) return;
    await _afterCursorMove();
  }

  Future<void> redo() async {
    if (!_stack.redo()) return;
    await _afterCursorMove();
  }

  /// Tapping an entry in the version strip. Index 0 is the untouched original.
  Future<void> jumpTo(int index) async {
    if (!_stack.jumpTo(index)) return;
    await _afterCursorMove();
  }

  Future<void> _afterCursorMove() async {
    _restoreFromStack();
    _syncStackFlags();
    _scheduleSave();
    // Undoing past an applied AI result puts a different file underneath the
    // whole stack, so the decoded source has to be rebuilt, not just the
    // spatial cache.
    if (effectiveSourcePath != _loadedPath) {
      await load();
      return;
    }
    await _syncBase();
    unawaited(_syncSwatch());
  }

  void _restoreFromStack() {
    final state = _stack.state;
    brightness.value = state.adjust.brightness;
    contrast.value = state.adjust.contrast;
    saturation.value = state.adjust.saturation;
    sharpness.value = state.adjust.sharpness;

    filterId.value = state.filter.id;
    filterStrength.value = state.filter.strength;

    vignette.value = state.effects.vignette;
    grain.value = state.effects.grain;
    blur.value = state.effects.blur;
    glow.value = state.effects.glow;

    geometry.value = state.geometry;

    texts.value = state.texts.toList();
    if (selectedText == null) selectedTextId.value = null;
  }

  void _syncStackFlags() {
    canUndo.value = _stack.canUndo;
    canRedo.value = _stack.canRedo;
    historyCursor.value = _stack.cursor;
    history.value = _stack.operations;
    isSaved.value = !_stack.canUndo;
  }

  // ---------------------------------------------------------------- commit

  /// Every panel funnels through here. One gesture becomes one history entry:
  /// consecutive edits carrying the same label collapse, so a slider drag or a
  /// run of strength tweaks reads as a single step rather than as noise.
  Future<void> _commit(
    EditOperationType type,
    String label,
    Map<String, dynamic> params,
  ) async {
    _debounce?.cancel();

    final op = EditOperation(type: type, label: label, params: params);
    if (_stack.state.apply(op) == _stack.state) return;

    if (_stack.last?.label == label && _stack.canUndo) {
      _stack.replaceLast(op);
    } else {
      _stack.push(op);
    }

    await _syncBase();
    unawaited(_syncSwatch());
    await _attachThumbnail();
    _syncStackFlags();
    _scheduleSave();
  }

  // -------------------------------------------------------------- render

  /// Writes the stack back to the project row. Debounced, and fire-and-forget:
  /// a slow disk must never make the canvas wait.
  void _scheduleSave() {
    final repository = _projects;
    final current = project.value;
    if (repository == null || current == null) return;

    _saveDebounce?.cancel();
    _saveDebounce = Timer(saveDelay, () => unawaited(saveNow()));
  }

  Future<void> saveNow() async {
    final repository = _projects;
    final current = project.value;
    if (repository == null || current == null) return;

    _saveDebounce?.cancel();
    try {
      final adjustments = {
        'v': 1,
        'operations': _stack.applied.map((op) => op.toMap()).toList(),
      };
      await repository.touch(current.id, adjustments: adjustments);

      // The local database is the source of truth and has just been written;
      // the cloud copy is a best-effort backup that must not block anything.
      final saved = await repository.byId(current.id);
      if (saved != null) _sync?.pushLater(saved);
    } catch (error) {
      debugPrint('[editor] save failed: $error');
    }
  }

  void _scheduleBase() {
    _debounce?.cancel();
    _debounce = Timer(renderDelay, () => unawaited(_syncBase()));
  }

  /// Brings [previewBase] in line with the current spatial parameters.
  /// Returns once the base matches whatever is current at that moment, not
  /// what was current at call time: intermediate values of a fast burst are
  /// skipped rather than each being rendered and thrown away.
  Future<void> _syncBase() async {
    final source = _previewSource;
    if (source == null) return;

    while (true) {
      final target = previewState;
      final key = target.spatialKey;
      if (key == _baseKey) return;

      final cached = _baseCache[key];
      if (cached != null) {
        _setBase(key, cached);
        return;
      }

      final inFlight = _baseInFlight;
      if (inFlight != null) {
        await inFlight;
        continue;
      }

      final run = _renderBase(source, target, key);
      _baseInFlight = run;
      try {
        await run;
      } finally {
        _baseInFlight = null;
      }
    }
  }

  Future<void> _renderBase(
    Uint8List source,
    EditState target,
    String key,
  ) async {
    isRendering.value = true;
    try {
      final bytes = await ImagePipeline.renderSpatial(source, target);
      _baseCache.remove(key);
      _baseCache[key] = bytes;
      while (_baseCache.length > _baseCacheSize) {
        // Never evict the untouched source: it is the reset/original state.
        final victim = _baseCache.keys.firstWhere(
          (k) => k != _identityKey,
          orElse: () => _baseCache.keys.first,
        );
        _baseCache.remove(victim);
      }
      // Only show it if the user has not moved on meanwhile; otherwise the
      // loop in _syncBase picks the newer value.
      if (previewState.spatialKey == key) _setBase(key, bytes);
    } on ImagePipelineFailure catch (failure) {
      errorMessage.value = failure.message;
      _baseKey = key;
    } catch (error) {
      debugPrint('[editor] render failed: $error');
      errorMessage.value = 'Could not apply that edit.';
      _baseKey = key;
    } finally {
      isRendering.value = false;
    }
  }

  void _setBase(String key, Uint8List bytes) {
    _baseKey = key;
    previewBase.value = bytes;
  }

  /// One small render backing the whole filter strip. Each swatch differs only
  /// by a colour matrix, which the strip applies on the GPU, so nine presets
  /// cost one render rather than nine.
  Future<void> _syncSwatch() async {
    final source = _previewSource;
    if (source == null) return;

    final token = ++_swatchToken;
    final state = EditState(
      adjust: AdjustParams(sharpness: sharpness.value),
      effects: currentEffects,
      geometry: geometry.value,
    );
    try {
      final bytes = await ImagePipeline.render(RenderRequest(
        bytes: source,
        state: state,
        maxEdge: ImagePipeline.swatchMaxEdge,
        quality: 80,
      ));
      if (token == _swatchToken) swatchBase.value = bytes;
    } catch (error) {
      debugPrint('[editor] swatch failed: $error');
    }
  }

  /// History thumbnails are rendered once, at commit time, so scrolling the
  /// strip never triggers image work.
  Future<void> _attachThumbnail() async {
    final source = _previewSource;
    final index = _stack.cursor - 1;
    if (source == null || index < 0) return;
    try {
      final bytes = await ImagePipeline.render(RenderRequest(
        bytes: source,
        state: _stack.state,
        maxEdge: ImagePipeline.thumbnailMaxEdge,
        quality: 70,
      ));
      _stack.replaceAt(index, _stack.operations[index].withThumbnail(bytes));
      history.value = _stack.operations;
    } catch (error) {
      debugPrint('[editor] thumbnail failed: $error');
    }
  }

  // ---------------------------------------------------------------- misc

  void setProject(EditProject value) => _adopt(value);

  void setImage(String path) => imagePath.value = path;

  void setTool(EditorTool tool) {
    if (tool == EditorTool.crop) {
      enterCrop();
    } else if (isCropping.value) {
      exitCrop();
    }
    if (tool != EditorTool.text) selectedTextId.value = null;
    activeTool.value = tool;
  }

  void clearError() => errorMessage.value = null;

  @visibleForTesting
  EditStack get stack => _stack;

  @visibleForTesting
  set previewSource(Uint8List? bytes) => _previewSource = bytes;

  @override
  void onClose() {
    _debounce?.cancel();
    _saveDebounce?.cancel();
    // Leaving the editor is exactly when an in-flight debounce would be lost.
    unawaited(saveNow());
    super.onClose();
  }
}
