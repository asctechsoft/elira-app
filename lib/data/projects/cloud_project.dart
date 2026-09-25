import '../../models/data_models/edit_project.dart';

/// A project as it exists in Firestore.
///
/// Note what is **not** here: `originalPath`, `thumbnailPath`, `editedPath`.
/// Those are absolute paths inside this device's app storage. They mean
/// nothing on another device, and uploading them would leak the directory
/// layout for no benefit. What travels is the recipe plus the id of the
/// gallery photo it came from.
class CloudProject {
  const CloudProject({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.updatedAt,
    this.sourceAssetId,
    this.adjustments = const {},
    this.schemaVersion = 1,
  });

  final String id;
  final String name;
  final int width;
  final int height;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The gallery asset the working copy was made from. This is what makes a
  /// same-device restore possible: the photo is still in the library even when
  /// app storage has been cleared.
  final String? sourceAssetId;

  final Map<String, dynamic> adjustments;
  final int schemaVersion;

  /// False when the photo cannot be found again from this record alone, which
  /// is the case for a camera capture: it was never a gallery asset, and
  /// without cloud storage for the bytes there is nothing to restore from.
  bool get isRestorable => sourceAssetId != null && sourceAssetId!.isNotEmpty;

  factory CloudProject.fromProject(EditProject project) => CloudProject(
        id: project.id,
        name: project.name,
        width: project.width,
        height: project.height,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
        sourceAssetId: project.sourceAssetId,
        adjustments: project.adjustments,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'width': width,
        'height': height,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'sourceAssetId': sourceAssetId,
        'adjustments': adjustments,
        'schemaVersion': schemaVersion,
      };

  factory CloudProject.fromMap(String id, Map<String, dynamic> map) {
    int asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

    return CloudProject(
      id: id,
      name: map['name']?.toString() ?? 'Untitled',
      width: asInt(map['width']),
      height: asInt(map['height']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['createdAt'])),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['updatedAt'])),
      sourceAssetId: map['sourceAssetId']?.toString(),
      adjustments: map['adjustments'] is Map
          ? (map['adjustments'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : const {},
      schemaVersion: map['schemaVersion'] is int ? map['schemaVersion'] as int : 1,
    );
  }

  @override
  String toString() => 'CloudProject($id, "$name")';
}
