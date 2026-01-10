import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HadithDatabase {
  static final HadithDatabase instance = HadithDatabase._init();
  static Database? _database;

  HadithDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hadith.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE hadith_books (
        id TEXT PRIMARY KEY,
        title_ar TEXT NOT NULL,
        title_en TEXT NOT NULL,
        total_count INTEGER NOT NULL,
        has_tashkeel INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE hadith_items (
        uid TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        number INTEGER,
        chapter TEXT,
        text_ar TEXT NOT NULL,
        raw_json TEXT NOT NULL,
        search_text TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES hadith_books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_book_id ON hadith_items (book_id)');
    await db.execute('CREATE INDEX idx_number ON hadith_items (number)');
    await db.execute(
      'CREATE INDEX idx_search_text ON hadith_items (search_text)',
    );
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('hadith_items');
    await db.delete('hadith_books');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
