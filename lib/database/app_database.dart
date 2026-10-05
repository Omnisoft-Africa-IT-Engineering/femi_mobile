import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._privateConstructor();

  static final AppDatabase instance =
      AppDatabase._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'femi.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_cache (
            id INTEGER PRIMARY KEY,
            username TEXT,
            company_name TEXT,
            is_pro INTEGER NOT NULL DEFAULT 0,
            plan TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}