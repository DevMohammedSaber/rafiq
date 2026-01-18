import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/content/content_cache_paths.dart';
import '../../../core/content/content_manifest.dart';

/// Hadith database manager for CDN-imported content.
class HadithDatabaseCdn {
  static final HadithDatabaseCdn instance = HadithDatabaseCdn._();
  HadithDatabaseCdn._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = ContentCachePaths.hadithDbPath;
    await ContentCachePaths.ensureDirectoryExists(dbPath);

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadith_books (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        hadith_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadiths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        hadith_number TEXT,
        text_ar TEXT NOT NULL,
        search_text TEXT,
        sanad TEXT,
        chapter TEXT,
        grade TEXT,
        FOREIGN KEY (book_id) REFERENCES hadith_books(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hadiths_book ON hadiths(book_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hadiths_search ON hadiths(search_text)',
    );
  }

  /// Import hadith from multiple book CSV files.
  Future<void> importFromBooks(
    List<HadithBookEntry> books,
    String hadithDir,
    void Function(int current, int total) onProgress,
  ) async {
    final db = await database;

    // Clear existing data
    await db.delete('hadiths');
    await db.delete('hadith_books');

    int totalBooks = books.length;
    int processedBooks = 0;

    for (final book in books) {
      final csvPath = '${hadithDir}/${book.id}/${book.csv}';
      final file = File(csvPath);

      if (!await file.exists()) {
        processedBooks++;
        continue;
      }

      // Insert book metadata
      await db.insert('hadith_books', {
        'id': book.id,
        'name_ar': _getBookNameAr(book.id),
        'name_en': _getBookNameEn(book.id),
        'hadith_count': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Import hadiths
      await _importBookCsv(db, book.id, csvPath);

      processedBooks++;
      onProgress(processedBooks, totalBooks);
    }
  }

  Future<void> _importBookCsv(
    Database db,
    String bookId,
    String csvPath,
  ) async {
    final file = File(csvPath);
    final csvString = await file.readAsString();

    // Detect delimiter
    String delimiter = ',';
    final firstLine = csvString.split('\n').firstOrNull ?? '';
    if (firstLine.contains('|'))
      delimiter = '|';
    else if (firstLine.contains(';'))
      delimiter = ';';
    else if (firstLine.contains('\t'))
      delimiter = '\t';

    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
    ).convert(csvString, eol: '\n');

    if (rows.isEmpty) return;

    // Find column indices
    final header = rows.first.map((e) {
      var s = e.toString().toLowerCase().trim();
      if (s.startsWith('\ufeff')) s = s.substring(1);
      return s;
    }).toList();

    print('Hadith CSV Header parsed: $header using delimiter: "$delimiter"');

    int textIdx = _findColumnIndex(header, [
      'text',
      'hadith',
      'matn',
      'text_ar',
      'content',
      'arabic',
    ], required: false);

    int numberIdx = _findColumnIndex(header, [
      'number',
      'hadith_number',
      'id',
      'no',
    ], required: false);

    int sanadIdx = _findColumnIndex(header, [
      'sanad',
      'isnad',
      'chain',
    ], required: false);

    int chapterIdx = _findColumnIndex(header, [
      'chapter',
      'bab',
      'section',
      'topic',
    ], required: false);

    int gradeIdx = _findColumnIndex(header, [
      'grade',
      'hukm',
      'status',
    ], required: false);

    // Fallback to positional if text not found
    if (textIdx == -1 && rows.first.length >= 2) {
      // Heuristic: ID, Text... or Text, ID...
      // Usually ID is first.
      if (rows.first.length >= 2) {
        numberIdx = 0;
        textIdx = 1;
      }
    }

    // Final fallback
    if (textIdx == -1) textIdx = 1; // risky but try 1
    if (numberIdx == -1) numberIdx = 0;

    // Check if row 0 is header or data
    bool headerIsData = false;
    if (rows.isNotEmpty) {
      // If "text" column contains long arabic text, it might be data.
      // Or if "number" column is integer.
      final firstNum = int.tryParse(rows.first[numberIdx].toString());
      if (firstNum != null) {
        headerIsData = true;
      }
    }

    final contentRows = headerIsData ? rows : rows.skip(1).toList();
    int hadithCount = 0;

    await db.transaction((txn) async {
      var batch = txn.batch();

      for (final row in contentRows) {
        if (row.length <= textIdx) continue;

        final text = row[textIdx].toString();
        if (text.isEmpty) continue;

        final number = numberIdx >= 0 && row.length > numberIdx
            ? row[numberIdx].toString()
            : '';
        final sanad = sanadIdx >= 0 && row.length > sanadIdx
            ? row[sanadIdx].toString()
            : '';
        final chapter = chapterIdx >= 0 && row.length > chapterIdx
            ? row[chapterIdx].toString()
            : '';
        final grade = gradeIdx >= 0 && row.length > gradeIdx
            ? row[gradeIdx].toString()
            : '';

        final searchText = _normalizeArabic(text);

        batch.insert('hadiths', {
          'book_id': bookId,
          'hadith_number': number,
          'text_ar': text,
          'search_text': searchText,
          'sanad': sanad,
          'chapter': chapter,
          'grade': grade,
        });

        hadithCount++;
        if (hadithCount % 500 == 0) {
          await batch.commit(noResult: true);
          batch = txn.batch();
        }
      }

      await batch.commit(noResult: true);
    });

    // Update book hadith count
    await db.update(
      'hadith_books',
      {'hadith_count': hadithCount},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  int _findColumnIndex(
    List<String> header,
    List<String> possibleNames, {
    bool required = true,
  }) {
    for (final name in possibleNames) {
      final idx = header.indexOf(name.toLowerCase());
      if (idx >= 0) return idx;
    }
    if (required) {
      throw Exception('Required column not found: $possibleNames');
    }
    return -1;
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Remove tashkeel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  String _getBookNameAr(String bookId) {
    final names = {
      'Sahih_Al-Bukhari': 'صحيح البخاري',
      'Sahih_Muslim': 'صحيح مسلم',
      'Sunan_Abu-Dawud': 'سنن أبي داود',
      'Sunan_Al-Tirmidhi': 'سنن الترمذي',
      'Sunan_Al-Nasai': 'سنن النسائي',
      'Sunan_Ibn-Maja': 'سنن ابن ماجه',
      'Musnad_Ahmad_Ibn-Hanbal': 'مسند أحمد',
      'Maliks_Muwataa': 'موطأ مالك',
      'Sunan_Al-Darimi': 'سنن الدارمي',
    };
    return names[bookId] ?? bookId;
  }

  String _getBookNameEn(String bookId) {
    final names = {
      'Sahih_Al-Bukhari': 'Sahih Al-Bukhari',
      'Sahih_Muslim': 'Sahih Muslim',
      'Sunan_Abu-Dawud': 'Sunan Abu Dawud',
      'Sunan_Al-Tirmidhi': 'Jami At-Tirmidhi',
      'Sunan_Al-Nasai': 'Sunan An-Nasai',
      'Sunan_Ibn-Maja': 'Sunan Ibn Majah',
      'Musnad_Ahmad_Ibn-Hanbal': 'Musnad Ahmad',
      'Maliks_Muwataa': "Malik's Muwatta",
      'Sunan_Al-Darimi': 'Sunan Ad-Darimi',
    };
    return names[bookId] ?? bookId;
  }

  Future<void> close() async {
    if (_database?.isOpen == true) {
      await _database!.close();
      _database = null;
    }
  }
}
