import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reports.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patientName TEXT,
            patientId TEXT,
            testType TEXT,
            result TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertReport(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('reports', data);
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final db = await instance.database;
    return await db.query('reports', orderBy: 'id DESC');
  }

  Future<int> updateReport(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'reports',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<int> deleteReport(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}