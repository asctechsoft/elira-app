import 'dart:convert';

/// A draft. Created the moment a photo is picked, before any edit happens, so
/// the work survives the app being killed mid-session (spec 6, 18).
///
/// [originalPath] always points at a copy inside app storage, never at the
/// gallery file: the original must never be modified, and a `photo_manager`
/// cache path can be evicted by the OS at any time.
class EditProject {
  const EditProject({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.createdAt,
    required this.updatedAt,
    this.sourceAssetId,
    this.thumbnailPath,
    this.editedPath,
    this.width = 0,
    this.height = 0,
    this.initialTool,
    this.adjustments = const {},
  });

  final String id;
  final String name;

  /// Working copy of the untouched original, inside app storage.
  final String originalPath;

  /// `photo_manager` asset id, when the project came from the gallery.
  final String? sourceAssetId;

  final String? thumbnailPath;

  /// Latest rendered result, once the editor produces one.
  final String? editedPath;

  final int width;
  final int height;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tool the editor should open on, set when the user arrived from a Home
  /// quick action ("Remove", "Retouch", ...) rather than the generic Edit tab.
  final String? initialTool;

  /// Operation stack. Empty in this phase; the editor fills it in phase 3.
  final Map<String, dynamic> adjustments;

  int get megapixels => (width * height / 1000000).round();

  bool get hasDimensions => width > 0 && height > 0;

  String get resolutionLabel => hasDimensions ? '$width × $height' : 'Unknown size';

  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Edited just now';
    if (diff.inMinutes < 60) return 'Edited ${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'Edited ${diff.inHours} hours ago';
    return 'Edited ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  EditProject copyWith({
    String? name,
    String? thumbnailPath,
    String? editedPath,
    DateTime? updatedAt,
    String? initialTool,
    Map<String, dynamic>? adjustments,
  }) =>
      EditProject(
        id: id,
        name: name ?? this.name,
        originalPath: originalPath,
        sourceAssetId: sourceAssetId,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        editedPath: editedPath ?? this.editedPath,
        width: width,
        height: height,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        initialTool: initialTool ?? this.initialTool,
        adjustments: adjustments ?? this.adjustments,
      );

  /// Column names match the `projects` table sketched in TODO section 9, so the
  /// sqflite layer can persist this without another round of changes.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'original_path': originalPath,
        'source_asset_id': sourceAssetId,
        'thumbnail_path': thumbnailPath,
        'edited_path': editedPath,
        'width': width,
        'height': height,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'initial_tool': initialTool,
        'adjustments': jsonEncode(adjustments),
      };

  factory EditProject.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> decodeAdjustments(Object? raw) {
      if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
        } catch (_) {}
      }
      return const {};
    }

    int asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

    return EditProject(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Untitled',
      originalPath: map['original_path']?.toString() ?? '',
      sourceAssetId: map['source_asset_id']?.toString(),
      thumbnailPath: map['thumbnail_path']?.toString(),
      editedPath: map['edited_path']?.toString(),
      width: asInt(map['width']),
      height: asInt(map['height']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['created_at'])),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['updated_at'])),
      initialTool: map['initial_tool']?.toString(),
      adjustments: decodeAdjustments(map['adjustments']),
    );
  }
}
