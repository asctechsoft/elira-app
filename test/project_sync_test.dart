import 'package:elira/data/projects/cloud_project.dart';
import 'package:elira/data/projects/in_memory_project_repository.dart';
import 'package:elira/data/projects/project_sync.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:flutter_test/flutter_test.dart';

EditProject _project(
  String id, {
  String name = 'Trip',
  String? sourceAssetId = 'asset_1',
  Map<String, dynamic> adjustments = const {},
}) {
  final now = DateTime(2026, 2, 1);
  return EditProject(
    id: id,
    name: name,
    originalPath: '/data/user/0/com.asc.elira/files/projects/$id/original.jpg',
    thumbnailPath: '/data/user/0/com.asc.elira/files/projects/$id/thumb.jpg',
    sourceAssetId: sourceAssetId,
    width: 3000,
    height: 4000,
    createdAt: now,
    updatedAt: now,
    adjustments: adjustments,
  );
}

/// Records what would have gone to Firestore.
class _RecordingSync implements ProjectSync {
  bool available = true;
  List<CloudProject> remote = const [];

  final List<CloudProject> pushed = [];
  final List<String> removed = [];
  bool shouldThrow = false;

  @override
  bool get isAvailable => available;

  @override
  Future<void> push(EditProject project) async {
    if (shouldThrow) throw Exception('offline');
    pushed.add(CloudProject.fromProject(project));
  }

  @override
  Future<List<CloudProject>> pull() async {
    if (shouldThrow) throw Exception('offline');
    return remote;
  }

  @override
  Future<void> remove(String projectId) async {
    if (shouldThrow) throw Exception('offline');
    removed.add(projectId);
  }
}

void main() {
  group('what travels to the cloud', () {
    test('device paths never leave the phone', () {
      final map = CloudProject.fromProject(_project('p1')).toMap();

      // Paths are meaningless on another device and leak the app's directory
      // layout, so they are simply not part of the document.
      expect(map.keys, isNot(contains('originalPath')));
      expect(map.keys, isNot(contains('thumbnailPath')));
      expect(map.keys, isNot(contains('editedPath')));
      expect(map.values.whereType<String>().join(),
          isNot(contains('/data/user/0/')));
    });

    test('the document has exactly the fields the rules allow', () {
      final map = CloudProject.fromProject(_project('p1')).toMap();

      expect(
        map.keys.toSet(),
        {
          'name',
          'width',
          'height',
          'createdAt',
          'updatedAt',
          'sourceAssetId',
          'adjustments',
          'schemaVersion',
        },
      );
    });

    test('the recipe survives the round trip', () {
      final project = _project('p1', adjustments: const {
        'v': 1,
        'operations': [
          {'type': 'filter', 'label': 'Warm', 'params': {'id': 'warm'}},
        ],
      });

      final restored = CloudProject.fromMap(
        'p1',
        CloudProject.fromProject(project).toMap(),
      );

      expect(restored.name, 'Trip');
      expect(restored.width, 3000);
      expect(restored.sourceAssetId, 'asset_1');
      expect((restored.adjustments['operations'] as List), hasLength(1));
      expect(restored.updatedAt, project.updatedAt);
    });

    test('a malformed document decodes to something usable', () {
      final restored = CloudProject.fromMap('p1', const {
        'name': null,
        'width': 'wide',
        'adjustments': 'not a map',
      });

      expect(restored.name, 'Untitled');
      expect(restored.width, 0);
      expect(restored.adjustments, isEmpty);
    });
  });

  group('restorability', () {
    test('a gallery photo can be found again on the same device', () {
      expect(CloudProject.fromProject(_project('p1')).isRestorable, isTrue);
    });

    test('a camera capture cannot, and says so', () {
      // It was never a gallery asset, and the bytes are not in the cloud, so
      // there is nothing to restore from.
      expect(
        CloudProject.fromProject(_project('p1', sourceAssetId: null))
            .isRestorable,
        isFalse,
      );
    });
  });

  group('BackgroundProjectSync', () {
    late InMemoryProjectRepository projects;
    late _RecordingSync sync;
    late BackgroundProjectSync background;

    setUp(() {
      projects = InMemoryProjectRepository();
      sync = _RecordingSync();
      background = BackgroundProjectSync(sync: sync, projects: projects);
    });

    test('pushes a project when signed in', () async {
      background.pushLater(_project('p1'));
      await Future<void>.delayed(Duration.zero);

      expect(sync.pushed.single.id, 'p1');
    });

    test('does nothing at all when there is no cloud', () async {
      sync.available = false;

      background.pushLater(_project('p1'));
      await background.pushAll();
      await Future<void>.delayed(Duration.zero);

      expect(sync.pushed, isEmpty);
      expect(background.isAvailable, isFalse);
      expect(await background.restorable(), isEmpty);
    });

    test('a failed push is swallowed, because local already has the truth',
        () async {
      sync.shouldThrow = true;

      background.pushLater(_project('p1'));
      await Future<void>.delayed(Duration.zero);

      // No throw escaping into the editor is the whole point.
      expect(sync.pushed, isEmpty);
    });

    test('pushAll sends everything stored locally', () async {
      await projects.save(_project('p1'));
      await projects.save(_project('p2'));

      await background.pushAll();

      expect(sync.pushed.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('restorable lists only what is missing locally', () async {
      await projects.save(_project('here'));
      sync.remote = [
        CloudProject.fromProject(_project('here')),
        CloudProject.fromProject(_project('missing')),
      ];

      final restorable = await background.restorable();

      expect(restorable.map((p) => p.id), ['missing']);
    });

    test('restorable hides what cannot actually be restored', () async {
      sync.remote = [
        CloudProject.fromProject(_project('camera', sourceAssetId: null)),
        CloudProject.fromProject(_project('gallery')),
      ];

      final restorable = await background.restorable();

      expect(restorable.map((p) => p.id), ['gallery'],
          reason: 'offering a restore that would fail is worse than hiding it');
    });

    test('a failed pull is an empty list, not an exception', () async {
      sync.shouldThrow = true;
      expect(await background.restorable(), isEmpty);
    });

    test('forget removes the cloud copy', () async {
      await background.forget('p1');
      expect(sync.removed, ['p1']);
    });
  });
}
