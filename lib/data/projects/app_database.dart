import 'package:sqflite/sqflite.dart';

/// The local database.
///
/// Schema changes are additive and versioned: a user who already has drafts on
/// disk cannot be asked to reinstall because a column moved. [_onUpgrade] adds
/// one `if (from < n)` block per version and never recreates a table.
class AppDatabase {
  AppDatabase({this.fileName = 'elira.db', this.directoryOverride});

  final String fileName;

  /// Set by tests, which run the real SQL against a folder they own.
  final String? directoryOverride;

  static const int version = 2;
  static const String projectsTable = 'projects';
  static const String presetsTable = 'presets';

  Database? _db;

  Future<Database> open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final directory = directoryOverride ?? await getDatabasesPath();
    final db = await openDatabase(
      '$directory/$fileName',
      version: version,
      onCreate: (db, _) async {
        await _createProjects(db);
        await _createPresets(db);
      },
      onUpgrade: _onUpgrade,
    );
    _db = db;
    return db;
  }

  Future<void> _createProjects(Database db) async {
    await db.execute('''
      CREATE TABLE $projectsTable (
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
    // Home orders by this on every open, and it is the only query that runs on
    // a cold start, so it is worth the index from day one.
    await db.execute(
      'CREATE INDEX idx_projects_updated_at ON $projectsTable (updated_at DESC)',
    );
  }

  /// Added in v2: a look the user saved to reuse. Deliberately stores only the
  /// colour and effect slices — a crop or a caption belongs to one photo, not
  /// to a look.
  Future<void> _createPresets(Database db) async {
    await db.execute('''
      CREATE TABLE $presetsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        use_count INTEGER NOT NULL DEFAULT 0,
        state TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_presets_updated_at ON $presetsTable (updated_at DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) await _createPresets(db);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
