import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuranDatabase {
  static final QuranDatabase instance = QuranDatabase._init();
  static Database? _database;

  QuranDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS quran_ayahs');
      await db.execute('DROP TABLE IF EXISTS quran_surahs');
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quran_surahs (
        surah INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        ayah_count INTEGER NOT NULL,
        place TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quran_ayahs (
        id TEXT PRIMARY KEY,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text TEXT NOT NULL,
        search_text TEXT NOT NULL,
        page INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_surah_ayah ON quran_ayahs (surah, ayah)',
    );
    await db.execute(
      'CREATE INDEX idx_quran_search ON quran_ayahs (search_text)',
    );
    await db.execute('CREATE INDEX idx_quran_page ON quran_ayahs (page)');
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('quran_ayahs');
    await db.delete('quran_surahs');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
