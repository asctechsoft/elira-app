/// One piece of text placed on the photo.
///
/// Position and size are stored **normalised** against the displayed image,
/// exactly like the crop rectangle: the same layer then lands in the same
/// place on the 1440px preview and on a full-resolution export, with no
/// per-device fudge factors.
class TextLayer {
  const TextLayer({
    required this.id,
    required this.text,
    this.fontId = defaultFontId,
    this.color = 0xFFFFFFFF,
    this.align = TextLayerAlign.center,
    this.dx = 0.5,
    this.dy = 0.5,
    this.size = 0.09,
  });

  static const String defaultFontId = 'sans';

  final String id;
  final String text;
  final String fontId;

  /// ARGB, stored as an int so the model needs no Flutter import.
  final int color;

  final TextLayerAlign align;

  /// Centre of the layer, 0..1 across the displayed image.
  final double dx;
  final double dy;

  /// Font size as a fraction of the image height. Resolution-independent, so
  /// text that looked right in the editor is not tiny in the export.
  final double size;

  bool get isBlank => text.trim().isEmpty;

  TextLayer copyWith({
    String? text,
    String? fontId,
    int? color,
    TextLayerAlign? align,
    double? dx,
    double? dy,
    double? size,
  }) =>
      TextLayer(
        id: id,
        text: text ?? this.text,
        fontId: fontId ?? this.fontId,
        color: color ?? this.color,
        align: align ?? this.align,
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
        size: size ?? this.size,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'fontId': fontId,
        'color': color,
        'align': align.name,
        'dx': dx,
        'dy': dy,
        'size': size,
      };

  factory TextLayer.fromMap(Map<String, dynamic> map) {
    double read(String key, double fallback) {
      final v = map[key];
      return v is num ? v.toDouble() : fallback;
    }

    return TextLayer(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      fontId: map['fontId']?.toString() ?? defaultFontId,
      color: map['color'] is int ? map['color'] as int : 0xFFFFFFFF,
      align: TextLayerAlign.values.firstWhere(
        (a) => a.name == map['align'],
        orElse: () => TextLayerAlign.center,
      ),
      dx: read('dx', 0.5),
      dy: read('dy', 0.5),
      size: read('size', 0.09),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TextLayer &&
      other.id == id &&
      other.text == text &&
      other.fontId == fontId &&
      other.color == color &&
      other.align == align &&
      other.dx == dx &&
      other.dy == dy &&
      other.size == size;

  @override
  int get hashCode =>
      Object.hash(id, text, fontId, color, align, dx, dy, size);

  @override
  String toString() => 'TextLayer($id, "$text")';
}

enum TextLayerAlign { left, center, right }
