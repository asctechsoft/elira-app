import 'dart:io';

import 'package:elira/data/presets/preset_repository.dart';
import 'package:elira/data/projects/app_database.dart';
import 'package:elira/data/projects/in_memory_project_repository.dart';
import 'package:elira/data/projects/project_repository.dart';
import 'package:elira/data/projects/sqflite_project_repository.dart';
import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:elira/models/data_models/user_preset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

UserPreset _preset(String id, {String name = 'Warm look', DateTime? at}) =>
    UserPreset.fromState(
      id: id,
      name: name,
      at: at,
      state: const EditState(
        adjust: AdjustParams(brightness: 20),
        filter: FilterParams(id: 'warm', strength: 70),
        effects: EffectParams(grain: 15),
      ),
    );

/// The contract both implementations have to satisfy. Running it twice is the
/// point: the in-memory store is what every other test uses, so it must behave
/// like the real SQL one or those tests are proving nothing.
void _projectContract(String label, ProjectRepository Function() build) {
  group('ProjectRepository contract [$label]', () {
    late ProjectRepository repository;

    setUp(() => repository = build());

    test('save and read back', () async {
      await repository.save(_project('p1', adjustments: const {'v': 1}));
      final loaded = await repository.byId('p1');

      expect(loaded, isNotNull);
      expect(loaded!.name, 'Trip');
      expect(loaded.width, 100);
      expect(loaded.adjustments['v'], 1);
    });

    test('an unknown id is null', () async {
      expect(await repository.byId('ghost'), isNull);
    });

    test('same id replaces rather than duplicates', () async {
      await repository.save(_project('p1', name: 'First'));
      await repository.save(_project('p1', name: 'Second'));

      expect(await repository.count(), 1);
      expect((await repository.byId('p1'))!.name, 'Second');
    });

    test('recent is newest first and respects the limit', () async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 4; i++) {
        await repository.save(
          _project('p$i', updatedAt: base.add(Duration(days: i))),
        );
      }

      expect((await repository.recent()).map((p) => p.id),
          ['p3', 'p2', 'p1', 'p0']);
      expect((await repository.recent(limit: 2)).map((p) => p.id), ['p3', 'p2']);
      expect((await repository.all()).length, 4);
    });

    test('touch updates only what it was given', () async {
      await repository.save(_project('p1', name: 'Original'));

      await repository.touch('p1', adjustments: const {'operations': []});

      final loaded = (await repository.byId('p1'))!;
      expect(loaded.adjustments['operations'], isEmpty);
      expect(loaded.name, 'Original',
          reason: 'saving the stack must not revert a rename');
      expect(loaded.thumbnailPath, isNotNull);
    });

    test('touch moves the project to the front', () async {
      final base = DateTime(2026, 1, 1);
      await repository.save(_project('old', updatedAt: base));
      await repository
          .save(_project('new', updatedAt: base.add(const Duration(days: 1))));

      await repository.touch('old', name: 'Renamed');

      final recent = await repository.recent();
      expect(recent.first.id, 'old');
      expect(recent.first.name, 'Renamed');
    });

    test('touching an unknown id is harmless', () async {
      await repository.touch('ghost', name: 'X');
      expect(await repository.count(), 0);
    });

    test('delete removes only that row', () async {
      await repository.save(_project('p1'));
      await repository.save(_project('p2'));

      await repository.delete('p1');

      expect(await repository.byId('p1'), isNull);
      expect(await repository.count(), 1);
    });
  });
}

void _presetContract(String label, PresetRepository Function() build) {
  group('PresetRepository contract [$label]', () {
    late PresetRepository repository;

    setUp(() => repository = build());

    test('save and read back the whole look', () async {
      await repository.save(_preset('s1'));
      final loaded = (await repository.all()).single;

      expect(loaded.name, 'Warm look');
      expect(loaded.filter.id, 'warm');
      expect(loaded.filter.strength, 70);
      expect(loaded.adjust.brightness, 20);
      expect(loaded.effects.grain, 15);
    });

    test('newest used first', () async {
      final base = DateTime(2026, 1, 1);
      await repository.save(_preset('old', name: 'Old', at: base));
      await repository.save(
          _preset('new', name: 'New', at: base.add(const Duration(days: 1))));

      expect((await repository.all()).map((p) => p.name), ['New', 'Old']);
    });

    test('markUsed bumps the count and moves it up', () async {
      final base = DateTime(2026, 1, 1);
      await repository.save(_preset('old', name: 'Old', at: base));
      await repository.save(
          _preset('new', name: 'New', at: base.add(const Duration(days: 1))));

      await repository.markUsed('old');

      final all = await repository.all();
      expect(all.first.name, 'Old');
      expect(all.first.useCount, 1);
    });

    test('rename keeps everything else', () async {
      await repository.save(_preset('s1'));
      await repository.rename('s1', 'Sunset');

      final loaded = (await repository.all()).single;
      expect(loaded.name, 'Sunset');
      expect(loaded.filter.id, 'warm');
    });

    test('delete removes it', () async {
      await repository.save(_preset('s1'));
      await repository.delete('s1');

      expect(await repository.all(), isEmpty);
    });

    test('operating on an unknown id is harmless', () async {
      await repository.markUsed('ghost');
      await repository.rename('ghost', 'X');
      await repository.delete('ghost');

      expect(await repository.all(), isEmpty);
    });
  });
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;
  var counter = 0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('elira_db_test');
  });

  tearDown(() async {
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  AppDatabase database() => AppDatabase(
        fileName: 'test_${counter++}.db',
        directoryOverride: tmp.path,
      );

  // Both implementations, same contract.
  _projectContract('in memory', InMemoryProjectRepository.new);
  _projectContract('sqflite', () => SqfliteProjectRepository(database()));

  _presetContract('in memory', InMemoryPresetRepository.new);
  _presetContract('sqflite', () => SqflitePresetRepository(database()));

  group('schema', () {
    test('a fresh database has both tables and the indexes', () async {
      final db = await database().open();

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((r) => r['name']).toSet();
      expect(names, containsAll(['projects', 'presets']));

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      expect(indexes.map((r) => r['name']),
          containsAll(['idx_projects_updated_at', 'idx_presets_updated_at']));

      await db.close();
    });

    test('every column EditProject writes exists in the table', () async {
      // The repository passes EditProject.toMap() straight to insert, so a
      // mismatch between the model and the schema is a runtime crash that no
      // amount of compiling catches.
      final db = await database().open();
      final columns = await db.rawQuery('PRAGMA table_info(projects)');
      final names = columns.map((r) => r['name']).toSet();

      expect(names, containsAll(_project('p1').toMap().keys));
      await db.close();
    });

    test('every column UserPreset writes exists in the table', () async {
      final db = await database().open();
      final columns = await db.rawQuery('PRAGMA table_info(presets)');
      final names = columns.map((r) => r['name']).toSet();

      expect(names, containsAll(_preset('s1').toMap().keys));
      await db.close();
    });

    test('upgrading from v1 adds presets and keeps the existing projects',
        () async {
      final path = '${tmp.path}/upgrade.db';

      // A v1 database, exactly as an installed app would have it.
      final v1 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE projects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                original_path TEXT NOT NULL,
                source_asset_id TEXT,
                thumbnail_path TEXT,
                edited_path TEXT,
                width INTEGER NOT NULL DEFAULT 0,
                height INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                initial_tool TEXT,
                adjustments TEXT
              )
            ''');
            await db.execute(
              'CREATE INDEX idx_projects_updated_at ON projects (updated_at DESC)',
            );
          },
        ),
      );
      await v1.insert('projects', _project('kept', name: 'Old draft').toMap());
      await v1.close();

      // Now open it with the current code, which must migrate in place.
      final repository = SqfliteProjectRepository(
        AppDatabase(fileName: 'upgrade.db', directoryOverride: tmp.path),
      );
      final survived = await repository.byId('kept');

      expect(survived, isNotNull, reason: 'an upgrade must not lose drafts');
      expect(survived!.name, 'Old draft');

      final presets = SqflitePresetRepository(
        AppDatabase(fileName: 'upgrade.db', directoryOverride: tmp.path),
      );
      await presets.save(_preset('s1'));
      expect((await presets.all()).single.name, 'Warm look');
    });
  });
}
