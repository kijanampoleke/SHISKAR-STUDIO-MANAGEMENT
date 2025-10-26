import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  Database? _db;
  AppDatabase._internal();

  Future<void> init() async {
    if (_db != null) return;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'shiskar_studio_manager.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Database get db {
    if (_db == null) {
      throw Exception('Database not initialized. Call AppDatabase.instance.init() first.');
    }
    return _db!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        status TEXT,
        deadline TEXT,
        updated_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER,
        done INTEGER,
        progress REAL,
        updated_at TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE media_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        path TEXT NOT NULL,
        type TEXT,
        title TEXT,
        tags TEXT,
        created_at TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE tech_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        title TEXT NOT NULL,
        notes TEXT,
        diagram_path TEXT,
        created_at TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
      );
    ''');
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    // Add schema migrations here if necessary.
  }

  Future<void> close() async => _db?.close();
}