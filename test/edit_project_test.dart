import 'package:elira/models/data_models/edit_project.dart';
import 'package:flutter_test/flutter_test.dart';

EditProject _sample({
  int width = 3024,
  int height = 4032,
  Map<String, dynamic> adjustments = const {},
  String? initialTool,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return EditProject(
    id: 'p_1',
    name: 'Santorini',
    originalPath: '/app/projects/p_1/original.jpg',
    sourceAssetId: 'asset-9',
    thumbnailPath: '/app/projects/p_1/thumb.jpg',
    width: width,
    height: height,
    createdAt: now,
    updatedAt: now,
    initialTool: initialTool,
    adjustments: adjustments,
  );
}

void main() {
  group('serialisation', () {
    test('round-trips through toMap/fromMap', () {
      final original = _sample(
        adjustments: {'brightness': 20, 'contrast': -5},
        initialTool: 'remove',
      );
      final restored = EditProject.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.originalPath, original.originalPath);
      expect(restored.sourceAssetId, 'asset-9');
      expect(restored.thumbnailPath, original.thumbnailPath);
      expect(restored.width, 3024);
      expect(restored.height, 4032);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.initialTool, 'remove');
      expect(restored.adjustments['brightness'], 20);
      expect(restored.adjustments['contrast'], -5);
    });

    test('survives a row with missing and wrong-typed columns', () {
      final restored = EditProject.fromMap(const {
        'id': 'p_2',
        'width': 'nope',
        'adjustments': 'not-json',
      });

      expect(restored.id, 'p_2');
      expect(restored.name, 'Untitled');
      expect(restored.width, 0);
      expect(restored.adjustments, isEmpty);
      expect(restored.hasDimensions, isFalse);
      expect(restored.resolutionLabel, 'Unknown size');
    });

    test('accepts adjustments already decoded as a map', () {
      final restored = EditProject.fromMap({
        'id': 'p_3',
        'adjustments': {'saturation': 10},
      });
      expect(restored.adjustments['saturation'], 10);
    });
  });

  group('derived values', () {
    test('reports resolution and megapixels', () {
      final project = _sample();
      expect(project.resolutionLabel, '3024 × 4032');
      expect(project.megapixels, 12);
      expect(project.hasDimensions, isTrue);
    });

    test('copyWith keeps identity and the untouched original', () {
      final project = _sample();
      final edited = project.copyWith(
        editedPath: '/app/projects/p_1/export.jpg',
        updatedAt: project.updatedAt.add(const Duration(minutes: 5)),
      );

      expect(edited.id, project.id);
      expect(edited.originalPath, project.originalPath,
          reason: 'the original copy must never be repointed');
      expect(edited.editedPath, '/app/projects/p_1/export.jpg');
      expect(edited.updatedAt.isAfter(project.updatedAt), isTrue);
      expect(project.editedPath, isNull, reason: 'copyWith must not mutate');
    });
  });

  group('timeAgo', () {
    EditProject agedBy(Duration d) => EditProject(
          id: 'p',
          name: 'n',
          originalPath: '/o.jpg',
          createdAt: DateTime.now().subtract(d),
          updatedAt: DateTime.now().subtract(d),
        );

    test('covers minutes, hours and days', () {
      expect(agedBy(const Duration(seconds: 5)).timeAgo, 'Edited just now');
      expect(agedBy(const Duration(minutes: 10)).timeAgo, 'Edited 10 minutes ago');
      expect(agedBy(const Duration(hours: 3)).timeAgo, 'Edited 3 hours ago');
      expect(agedBy(const Duration(days: 1)).timeAgo, 'Edited 1 day ago');
      expect(agedBy(const Duration(days: 4)).timeAgo, 'Edited 4 days ago');
    });
  });
}
