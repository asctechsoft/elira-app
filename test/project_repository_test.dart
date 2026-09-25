import 'package:elira/data/projects/in_memory_project_repository.dart';
import 'package:elira/data/projects/project_repository.dart';
import 'package:elira/data/projects/sqflite_project_repository.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:flutter_test/flutter_test.dart';

EditProject _project(
  String id, {
  String name = 'Trip',
  DateTime? updatedAt,
  Map<String, dynamic> adjustments = const {},
}) {
  final now = updatedAt ?? DateTime.now();
  return EditProject(
    id: id,
    name: name,
    originalPath: '/tmp/$id.jpg',
    thumbnailPath: '/tmp/$id-thumb.jpg',
    width: 100,
    height: 80,
    createdAt: now,
    updatedAt: now,
    adjustments: adjustments,
  );
}

void main() {
  late ProjectRepository repository;

  setUp(() => repository = InMemoryProjectRepository());

  group('storing and reading', () {
    test('a saved project can be read back whole', () async {
      final project = _project('p1', adjustments: const {'v': 1});
      await repository.save(project);

      final loaded = await repository.byId('p1');

      expect(loaded, isNotNull);
      expect(loaded!.name, 'Trip');
      expect(loaded.adjustments, const {'v': 1});
      expect(loaded.width, 100);
    });

    test('an unknown id is null, not an error', () async {
      expect(await repository.byId('nope'), isNull);
    });

    test('saving the same id replaces rather than duplicates', () async {
      await repository.save(_project('p1', name: 'First'));
      await repository.save(_project('p1', name: 'Second'));

      expect(await repository.count(), 1);
      expect((await repository.byId('p1'))!.name, 'Second');
    });

    test('recent is newest first', () async {
      final base = DateTime(2026, 1, 1);
      await repository.save(_project('old', updatedAt: base));
      await repository.save(
          _project('newest', updatedAt: base.add(const Duration(days: 2))));
      await repository.save(
          _project('middle', updatedAt: base.add(const Duration(days: 1))));

      final recent = await repository.recent();

      expect(recent.map((p) => p.id), ['newest', 'middle', 'old']);
    });

    test('recent respects the limit', () async {
      for (var i = 0; i < 5; i++) {
        await repository.save(_project('p$i',
            updatedAt: DateTime(2026, 1, 1).add(Duration(days: i))));
      }

      expect((await repository.recent(limit: 2)).map((p) => p.id), ['p4', 'p3']);
    });

    test('delete removes only that project', () async {
      await repository.save(_project('p1'));
      await repository.save(_project('p2'));

      await repository.delete('p1');

      expect(await repository.byId('p1'), isNull);
      expect(await repository.byId('p2'), isNotNull);
      expect(await repository.count(), 1);
    });

    test('deleting something that is not there is harmless', () async {
      await repository.delete('ghost');
      expect(await repository.count(), 0);
    });
  });

  group('touch', () {
    test('updates only the fields it was given', () async {
      await repository.save(_project('p1', name: 'Original'));

      await repository.touch('p1', adjustments: const {'operations': []});

      final loaded = (await repository.byId('p1'))!;
      expect(loaded.adjustments, const {'operations': []});
      expect(loaded.name, 'Original',
          reason: 'a save of the stack must not revert a rename');
      expect(loaded.thumbnailPath, isNotNull);
    });

    test('moves the project to the front of recent', () async {
      final base = DateTime(2026, 1, 1);
      await repository.save(_project('old', updatedAt: base));
      await repository.save(
          _project('new', updatedAt: base.add(const Duration(days: 1))));

      await repository.touch('old', adjustments: const {'v': 1});

      expect((await repository.recent()).first.id, 'old');
    });

    test('touching an unknown id does nothing', () async {
      await repository.touch('ghost', name: 'X');
      expect(await repository.count(), 0);
    });
  });

  group('NullProjectRepository', () {
    test('swallows every write and reports nothing stored', () async {
      const repository = NullProjectRepository();

      await repository.save(_project('p1'));
      await repository.touch('p1', name: 'X');
      await repository.delete('p1');

      expect(await repository.recent(), isEmpty);
      expect(await repository.all(), isEmpty);
      expect(await repository.byId('p1'), isNull);
      expect(await repository.count(), 0);
    });
  });

  group('EditProject round trip', () {
    test('survives the map the database stores', () {
      final project = _project('p1', adjustments: const {
        'v': 1,
        'operations': [
          {'type': 'adjust', 'label': 'Brightness', 'params': {'brightness': 40}},
        ],
      });

      final restored = EditProject.fromMap(project.toMap());

      expect(restored.id, project.id);
      expect(restored.adjustments['v'], 1);
      expect((restored.adjustments['operations'] as List).length, 1);
      expect(restored.updatedAt.millisecondsSinceEpoch,
          project.updatedAt.millisecondsSinceEpoch);
    });
  });
}
