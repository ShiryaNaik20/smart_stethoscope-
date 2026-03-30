import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient_record.dart';

class DatabaseService {
  static Database? _db;

  // Get database instance
  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  // Initialize database
  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'acubeat.db');

    return openDatabase(
      path,
      version: 3, // ✅ UPDATED VERSION

      // Create table (for fresh installs)
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id TEXT,
            name       TEXT,
            age        TEXT,
            phone      TEXT,
            prediction TEXT,
            murmur TEXT,
            confidence REAL,
            audio_path TEXT,
            timestamp  TEXT
          )
        ''');
      },

      // Upgrade existing DB
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE records ADD COLUMN audio_path TEXT'
          );
        }

          if (oldVersion < 3) {
    await db.execute(
      'ALTER TABLE records ADD COLUMN murmur TEXT'
    );
  }
      },
    );
  }

  // ✅ NEW: Auto-generate patient ID
  static Future<int> getNextPatientId() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT MAX(CAST(patient_id AS INTEGER)) as maxId FROM records'
    );

    final maxId = result.first['maxId'];

    if (maxId == null) return 1;

    return (maxId as int) + 1;
  }

  // Save record
  static Future<int> saveRecord(PatientRecord record) async {
    final db = await database;
    return db.insert('records', record.toMap());
  }

  // Get all records
  static Future<List<PatientRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('records', orderBy: 'timestamp DESC');
    return maps.map((map) => PatientRecord.fromMap(map)).toList();
  }

  // Delete record
  static Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}