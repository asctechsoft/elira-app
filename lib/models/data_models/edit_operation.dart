import 'dart:typed_data';

import 'text_layer.dart';

/// Light/colour parameters. Slider space is -100..100 with 0 meaning
/// "untouched", which keeps the UI honest; the mapping to the imaging
/// library's multipliers lives in the pipeline, not here.
class AdjustParams {
  const AdjustParams({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.sharpness = 0,
  });

  static const identity = AdjustParams();

  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;

  bool get isIdentity =>
      brightness == 0 && contrast == 0 && saturation == 0 && sharpness == 0;

  AdjustParams copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
  }) =>
      AdjustParams(
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        sharpness: sharpness ?? this.sharpness,
      );

  Map<String, dynamic> toMap() => {
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'sharpness': sharpness,
      };

  factory AdjustParams.fromMap(Map<String, dynamic> map) => AdjustParams(
        brightness: readNum(map, 'brightness'),
        contrast: readNum(map, 'contrast'),
        saturation: readNum(map, 'saturation'),
        sharpness: readNum(map, 'sharpness'),
      );

  @override
  bool operator ==(Object other) =>
      other is AdjustParams &&
      other.brightness == brightness &&
      other.contrast == contrast &&
      other.saturation == saturation &&
      other.sharpness == sharpness;

  @override
  int get hashCode => Object.hash(brightness, contrast, saturation, sharpness);

  @override
  String toString() =>
      'AdjustParams(b:$brightness c:$contrast s:$saturation sh:$sharpness)';
}

/// Which look is applied and how far. The matrix that implements [id] lives in
/// the filter catalogue; an operation only ever stores the id, so a project
/// saved today still opens after a look has been retuned.
class FilterParams {
  const FilterParams({this.id = none, this.strength = 100});

  static const none = 'original';
  static const identity = FilterParams();

  final String id;

  /// 0..100. Blends between the untouched image and the full look, which is
  /// what makes a preset usable rather than all-or-nothing.
  final double strength;

  bool get isIdentity => id == none || strength == 0;

  FilterParams copyWith({String? id, double? strength}) =>
      FilterParams(id: id ?? this.id, strength: strength ?? this.strength);

  Map<String, dynamic> toMap() => {'id': id, 'strength': strength};

  factory FilterParams.fromMap(Map<String, dynamic> map) => FilterParams(
        id: map['id']?.toString() ?? none,
        strength: map.containsKey('strength') ? readNum(map, 'strength') : 100,
      );

  @override
  bool operator ==(Object other) =>
      other is FilterParams && other.id == id && other.strength == strength;

  @override
  int get hashCode => Object.hash(id, strength);

  @override
  String toString() => 'FilterParams($id @ $strength)';
}

/// Spatial effects, each 0..100 and independently stackable.
class EffectParams {
  const EffectParams({
    this.vignette = 0,
    this.grain = 0,
    this.blur = 0,
    this.glow = 0,
  });

  static const identity = EffectParams();

  final double vignette;
  final double grain;
  final double blur;
  final double glow;

  bool get isIdentity => vignette == 0 && grain == 0 && blur == 0 && glow == 0;

  EffectParams copyWith({
    double? vignette,
    double? grain,
    double? blur,
    double? glow,
  }) =>
      EffectParams(
        vignette: vignette ?? this.vignette,
        grain: grain ?? this.grain,
        blur: blur ?? this.blur,
        glow: glow ?? this.glow,
      );

  Map<String, dynamic> toMap() => {
        'vignette': vignette,
        'grain': grain,
        'blur': blur,
        'glow': glow,
      };

  factory EffectParams.fromMap(Map<String, dynamic> map) => EffectParams(
        vignette: readNum(map, 'vignette'),
        grain: readNum(map, 'grain'),
        blur: readNum(map, 'blur'),
        glow: readNum(map, 'glow'),
      );

  @override
  bool operator ==(Object other) =>
      other is EffectParams &&
      other.vignette == vignette &&
      other.grain == grain &&
      other.blur == blur &&
      other.glow == glow;

  @override
  int get hashCode => Object.hash(vignette, grain, blur, glow);

  @override
  String toString() => 'EffectParams(v:$vignette g:$grain b:$blur gl:$glow)';
}

/// Rotation, mirroring and crop. The crop rectangle is stored **normalised**
/// (0..1 of the rotated, flipped image) rather than in pixels, so the same
/// operation replays correctly against the 1440px preview and against the
/// full-resolution original at export.
class GeometryParams {
  const GeometryParams({
    this.quarterTurns = 0,
    this.flipH = false,
    this.flipV = false,
    this.left = 0,
    this.top = 0,
    this.right = 1,
    this.bottom = 1,
  });

  static const identity = GeometryParams();

  /// Clockwise 90-degree steps, 0..3.
  final int quarterTurns;
  final bool flipH;
  final bool flipV;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get cropWidth => right - left;
  double get cropHeight => bottom - top;

  bool get hasCrop =>
      left > 0.0001 || top > 0.0001 || right < 0.9999 || bottom < 0.9999;

  bool get isIdentity => quarterTurns == 0 && !flipH && !flipV && !hasCrop;

  /// True when the image's width and height swap places.
  bool get swapsAxes => quarterTurns.isOdd;

  GeometryParams copyWith({
    int? quarterTurns,
    bool? flipH,
    bool? flipV,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) =>
      GeometryParams(
        quarterTurns: quarterTurns ?? this.quarterTurns,
        flipH: flipH ?? this.flipH,
        flipV: flipV ?? this.flipV,
        left: left ?? this.left,
        top: top ?? this.top,
        right: right ?? this.right,
        bottom: bottom ?? this.bottom,
      );

  GeometryParams withoutCrop() => copyWith(left: 0, top: 0, right: 1, bottom: 1);

  /// Turns the image a quarter clockwise **and carries the crop rectangle
  /// with it**. Rotating must not silently throw away a crop the user already
  /// made, so the rect is transformed into the new orientation rather than
  /// reset: a point (x, y) becomes (1 - y, x).
  GeometryParams rotatedCw() => copyWith(
        quarterTurns: (quarterTurns + 1) % 4,
        left: 1 - bottom,
        top: left,
        right: 1 - top,
        bottom: right,
      );

  /// Mirrors the frame; the crop rectangle mirrors with it.
  GeometryParams flippedH() => copyWith(
        flipH: !flipH,
        left: 1 - right,
        right: 1 - left,
      );

  GeometryParams flippedV() => copyWith(
        flipV: !flipV,
        top: 1 - bottom,
        bottom: 1 - top,
      );

  /// The crop rectangle clamped to the frame and kept non-degenerate.
  GeometryParams normalised() {
    final l = left.clamp(0.0, 0.98);
    final t = top.clamp(0.0, 0.98);
    return copyWith(
      left: l,
      top: t,
      right: right.clamp(l + 0.02, 1.0),
      bottom: bottom.clamp(t + 0.02, 1.0),
    );
  }

  Map<String, dynamic> toMap() => {
        'quarterTurns': quarterTurns,
        'flipH': flipH,
        'flipV': flipV,
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  factory GeometryParams.fromMap(Map<String, dynamic> map) {
    final turns = map['quarterTurns'];
    return GeometryParams(
      quarterTurns: turns is num ? turns.toInt() % 4 : 0,
      flipH: map['flipH'] == true,
      flipV: map['flipV'] == true,
      left: map.containsKey('left') ? readNum(map, 'left') : 0,
      top: map.containsKey('top') ? readNum(map, 'top') : 0,
      right: map.containsKey('right') ? readNum(map, 'right') : 1,
      bottom: map.containsKey('bottom') ? readNum(map, 'bottom') : 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeometryParams &&
      other.quarterTurns == quarterTurns &&
      other.flipH == flipH &&
      other.flipV == flipV &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode =>
      Object.hash(quarterTurns, flipH, flipV, left, top, right, bottom);

  @override
  String toString() => 'GeometryParams(turns:$quarterTurns h:$flipH v:$flipV '
      'rect:$left,$top,$right,$bottom)';
}

/// Reads a numeric field, defaulting anything missing or of the wrong type to
/// zero. Every params class depends on this: a document written by a future
/// schema version must not crash the editor.
double readNum(Map<String, dynamic> map, String key) {
  final v = map[key];
  return v is num ? v.toDouble() : 0;
}

enum EditOperationType { adjust, filter, effects, crop, text, ai }

/// One entry in the non-destructive edit stack (spec 18). The original image
/// is never written to; the stack is replayed to produce every render, which
/// is what makes undo/redo independent of any rendered file.
class EditOperation {
  EditOperation({
    required this.type,
    required this.label,
    required this.params,
    DateTime? at,
    this.thumbnail,
  }) : at = at ?? DateTime.now();

  final EditOperationType type;

  /// Shown in the history strip, e.g. "Brightness".
  final String label;

  final Map<String, dynamic> params;
  final DateTime at;

  /// Small preview of the result after this operation, rendered once when the
  /// operation is committed so the strip does not have to re-render history.
  final Uint8List? thumbnail;

  EditOperation withThumbnail(Uint8List? bytes) => EditOperation(
        type: type,
        label: label,
        params: params,
        at: at,
        thumbnail: bytes,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'label': label,
        'params': params,
        'at': at.millisecondsSinceEpoch,
      };

  factory EditOperation.fromMap(Map<String, dynamic> map) => EditOperation(
        type: EditOperationType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => EditOperationType.adjust,
        ),
        label: map['label']?.toString() ?? 'Edit',
        params: map['params'] is Map
            ? (map['params'] as Map).map((k, v) => MapEntry(k.toString(), v))
            : const {},
        at: DateTime.fromMillisecondsSinceEpoch(
          map['at'] is int ? map['at'] as int : 0,
        ),
      );
}

/// The folded result of replaying operations. Every operation type owns one
/// slice and replaces only that slice, so choosing a filter cannot silently
/// discard a crop the user made three steps earlier.
class EditState {
  const EditState({
    this.adjust = AdjustParams.identity,
    this.filter = FilterParams.identity,
    this.effects = EffectParams.identity,
    this.geometry = GeometryParams.identity,
    this.texts = const [],
    this.sourcePath,
  });

  static const initial = EditState();

  final AdjustParams adjust;
  final FilterParams filter;
  final EffectParams effects;
  final GeometryParams geometry;

  /// Text sits *above* the colour stage, so it is neither spatial work nor
  /// part of the matrix — adding a caption costs no render at all.
  final List<TextLayer> texts;

  /// Set once an AI result has been applied: the pixels the rest of the stack
  /// replays against. The user's original file is still never written to, so
  /// undoing past the AI step returns to it exactly (spec 18).
  final String? sourcePath;

  bool get isIdentity =>
      adjust.isIdentity &&
      filter.isIdentity &&
      effects.isIdentity &&
      geometry.isIdentity &&
      texts.isEmpty &&
      sourcePath == null;

  /// Everything that has to be recomputed on the CPU. The canvas caches its
  /// rendered base against this key, so moving a colour slider never
  /// invalidates it — only these parameters do.
  String get spatialKey =>
      '${sourcePath ?? ''}|${adjust.sharpness}|${effects.vignette},${effects.grain},'
      '${effects.blur},${effects.glow}|${geometry.quarterTurns},'
      '${geometry.flipH},${geometry.flipV},${geometry.left},'
      '${geometry.top},${geometry.right},${geometry.bottom}';

  /// True when the CPU stage is a no-op and the untouched source can be shown
  /// directly with only the colour matrix over it.
  bool get isSpatialIdentity =>
      adjust.sharpness == 0 && effects.isIdentity && geometry.isIdentity;

  EditState copyWith({
    AdjustParams? adjust,
    FilterParams? filter,
    EffectParams? effects,
    GeometryParams? geometry,
    List<TextLayer>? texts,
    String? sourcePath,
  }) =>
      EditState(
        adjust: adjust ?? this.adjust,
        filter: filter ?? this.filter,
        effects: effects ?? this.effects,
        geometry: geometry ?? this.geometry,
        texts: texts ?? this.texts,
        sourcePath: sourcePath ?? this.sourcePath,
      );

  /// Each operation is last-wins **within its own slice**: it carries the full
  /// parameter set for that slice, so replaying is order-independent among
  /// operations of one type and undo lands on the previous set exactly.
  EditState apply(EditOperation op) => switch (op.type) {
        EditOperationType.adjust =>
          copyWith(adjust: AdjustParams.fromMap(op.params)),
        EditOperationType.filter =>
          copyWith(filter: FilterParams.fromMap(op.params)),
        EditOperationType.effects =>
          copyWith(effects: EffectParams.fromMap(op.params)),
        EditOperationType.crop =>
          copyWith(geometry: GeometryParams.fromMap(op.params)),
        EditOperationType.text => copyWith(texts: textsFromMap(op.params)),
        EditOperationType.ai =>
          copyWith(sourcePath: op.params['path']?.toString()),
      };

  /// Text operations carry the whole layer list, so replaying one lands on an
  /// exact set of layers rather than on a sequence of add/remove deltas that
  /// could drift out of step with the cursor.
  static List<TextLayer> textsFromMap(Map<String, dynamic> params) {
    final raw = params['layers'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => TextLayer.fromMap(m.map((k, v) => MapEntry(k.toString(), v))))
        .toList(growable: false);
  }

  static Map<String, dynamic> textsToMap(List<TextLayer> layers) =>
      {'layers': layers.map((l) => l.toMap()).toList()};

  Map<String, dynamic> toMap() => {
        'adjust': adjust.toMap(),
        'filter': filter.toMap(),
        'effects': effects.toMap(),
        'geometry': geometry.toMap(),
        'texts': texts.map((l) => l.toMap()).toList(),
        'sourcePath': sourcePath,
      };

  factory EditState.fromMap(Map<String, dynamic> map) => EditState(
        adjust: AdjustParams.fromMap(_sub(map, 'adjust')),
        filter: FilterParams.fromMap(_sub(map, 'filter')),
        effects: EffectParams.fromMap(_sub(map, 'effects')),
        geometry: GeometryParams.fromMap(_sub(map, 'geometry')),
        texts: textsFromMap({'layers': map['texts']}),
        sourcePath: map['sourcePath']?.toString(),
      );

  static Map<String, dynamic> _sub(Map<String, dynamic> map, String key) =>
      map[key] is Map
          ? (map[key] as Map).map((k, v) => MapEntry(k.toString(), v))
          : const {};

  @override
  bool operator ==(Object other) =>
      other is EditState &&
      other.adjust == adjust &&
      other.filter == filter &&
      other.effects == effects &&
      other.geometry == geometry &&
      other.sourcePath == sourcePath &&
      _sameLayers(other.texts, texts);

  @override
  int get hashCode =>
      Object.hash(adjust, filter, effects, geometry, Object.hashAll(texts),
          sourcePath);

  static bool _sameLayers(List<TextLayer> a, List<TextLayer> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
