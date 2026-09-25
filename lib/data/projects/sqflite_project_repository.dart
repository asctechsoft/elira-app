import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/data_models/edit_project.dart';
import 'app_database.dart';
import 'project_repository.dart';

class SqfliteProjectRepository implements ProjectRepository {
  SqfliteProjectRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.open();

  @override
  Future<List<EditProject>> recent({int limit = 20}) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.projectsTable,
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(EditProject.fromMap).toList();
  }

  @override
  Future<List<EditProject>> all() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.projectsTable,
      orderBy: 'updated_at DESC',
    );
    return rows.map(EditProject.fromMap).toList();
  }

  @override
  Future<EditProject?> byId(String id) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.projectsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : EditProject.fromMap(rows.first);
  }

  @override
  Future<void> save(EditProject project) async {
    final db = await _db;
    await db.insert(
      AppDatabase.projectsTable,
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> touch(
    String id, {
    Map<String, dynamic>? adjustments,
    String? thumbnailPath,
    String? editedPath,
    String? name,
  }) async {
    final db = await _db;
    // Only the fields that were passed. A full row write here would clobber a
    // rename or a thumbnail written by another code path between reads.
    final encoded = adjustments == null ? null : jsonEncode(adjustments);
    final values = <String, Object?>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'adjustments': ?encoded,
      'thumbnail_path': ?thumbnailPath,
      'edited_path': ?editedPath,
      'name': ?name,
    };
    await db.update(
      AppDatabase.projectsTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppDatabase.projectsTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> count() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM ${AppDatabase.projectsTable}');
    final value = result.first['c'];
    return value is int ? value : 0;
  }
}

/// Used when the database cannot be opened. Losing the project list is bad;
/// refusing to start the app because of it is worse, so Home falls back to
/// this and simply shows no history.
class NullProjectRepository implements ProjectRepository {
  const NullProjectRepository();

  @override
  Future<List<EditProject>> recent({int limit = 20}) async => const [];

  @override
  Future<List<EditProject>> all() async => const [];

  @override
  Future<EditProject?> byId(String id) async => null;

  @override
  Future<void> save(EditProject project) async =>
      debugPrint('[projects] no database: ${project.id} was not saved');

  @override
  Future<void> touch(
    String id, {
    Map<String, dynamic>? adjustments,
    String? thumbnailPath,
    String? editedPath,
    String? name,
  }) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<int> count() async => 0;
}
