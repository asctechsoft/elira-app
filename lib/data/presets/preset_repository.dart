import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/data_models/user_preset.dart';
import '../projects/app_database.dart';

abstract class PresetRepository {
  /// Most recently used first.
  Future<List<UserPreset>> all();

  Future<void> save(UserPreset preset);

  /// Bumps the use count and moves the preset to the front of the list.
  Future<void> markUsed(String id);

  Future<void> rename(String id, String name);

  Future<void> delete(String id);
}

class SqflitePresetRepository implements PresetRepository {
  SqflitePresetRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.open();

  @override
  Future<List<UserPreset>> all() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.presetsTable,
      orderBy: 'updated_at DESC',
    );
    return rows.map(UserPreset.fromMap).toList();
  }

  @override
  Future<void> save(UserPreset preset) async {
    final db = await _db;
    await db.insert(
      AppDatabase.presetsTable,
      preset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markUsed(String id) async {
    final db = await _db;
    // One statement rather than read-modify-write, so two quick taps cannot
    // both read the same count and lose one of the increments.
    await db.rawUpdate(
      'UPDATE ${AppDatabase.presetsTable} '
      'SET use_count = use_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  @override
  Future<void> rename(String id, String name) async {
    final db = await _db;
    await db.update(
      AppDatabase.presetsTable,
      {'name': name, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppDatabase.presetsTable, where: 'id = ?', whereArgs: [id]);
  }
}

class InMemoryPresetRepository implements PresetRepository {
  InMemoryPresetRepository([List<UserPreset> seed = const []]) {
    for (final preset in seed) {
      _presets[preset.id] = preset;
    }
  }

  final Map<String, UserPreset> _presets = {};

  @override
  Future<List<UserPreset>> all() async {
    final list = _presets.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> save(UserPreset preset) async => _presets[preset.id] = preset;

  @override
  Future<void> markUsed(String id) async {
    final existing = _presets[id];
    if (existing == null) return;
    _presets[id] = existing.copyWith(
      useCount: existing.useCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> rename(String id, String name) async {
    final existing = _presets[id];
    if (existing == null) return;
    _presets[id] = existing.copyWith(name: name, updatedAt: DateTime.now());
  }

  @override
  Future<void> delete(String id) async => _presets.remove(id);
}

/// Used when the database could not be opened, so the Filters panel simply
/// shows no saved looks instead of the app refusing to start.
class NullPresetRepository implements PresetRepository {
  const NullPresetRepository();

  @override
  Future<List<UserPreset>> all() async => const [];

  @override
  Future<void> save(UserPreset preset) async =>
      debugPrint('[presets] no database: ${preset.id} was not saved');

  @override
  Future<void> markUsed(String id) async {}

  @override
  Future<void> rename(String id, String name) async {}

  @override
  Future<void> delete(String id) async {}
}
