import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/content/content_cache_paths.dart';

/// Azkar database manager for CDN-imported content.
class AzkarDatabaseCdn {
  static final AzkarDatabaseCdn instance = AzkarDatabaseCdn._();
  AzkarDatabaseCdn._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = ContentCachePaths.azkarDbPath;
    await ContentCachePaths.ensureDirectoryExists(dbPath);

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS azkar_categories (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        description TEXT,
        order_index INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS azkar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        text_ar TEXT NOT NULL,
        text_en TEXT,
        count INTEGER DEFAULT 1,
        benefit TEXT,
        reference TEXT,
        order_index INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES azkar_categories(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_azkar_category ON azkar(category_id)',
    );
  }

  /// Import azkar from CSV directory containing multiple CSV files.
  Future<void> importFromCsvDirectory(
    String azkarDir,
    void Function(int current, int total) onProgress,
  ) async {
    final db = await database;

    // Clear existing data
    await db.delete('azkar');
    await db.delete('azkar_categories');

    final dir = Directory(azkarDir);
    if (!await dir.exists()) return;

    final csvFiles = await dir
        .list()
        .where((f) => f.path.endsWith('.csv'))
        .toList();

    int processed = 0;
    int total = csvFiles.length;

    // First import categories if categories.csv exists
    final categoriesFile = File('$azkarDir/categories.csv');
    if (await categoriesFile.exists()) {
      await _importCategories(db, categoriesFile);
    }

    // Import each azkar file
    for (final fileEntity in csvFiles) {
      final file = File(fileEntity.path);
      final fileName = file.path.split('/').last;

      // Skip categories file as its already processed
      if (fileName == 'categories.csv') {
        processed++;
        continue;
      }

      await _importAzkarFile(db, file, fileName);
      processed++;
      onProgress(processed, total);
    }
  }

  Future<void> _importCategories(Database db, File file) async {
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

    final header = rows.first.map((e) {
      var s = e.toString().toLowerCase().trim();
      if (s.startsWith('\ufeff')) s = s.substring(1);
      return s;
    }).toList();

    int idIdx = _findColumnIndex(header, [
      'id',
      'category_id',
      'cat_id',
    ], required: false);
    int nameArIdx = _findColumnIndex(header, [
      'name_ar',
      'name',
      'title_ar',
      'arabic',
      'ar',
    ], required: false);
    int nameEnIdx = _findColumnIndex(header, [
      'name_en',
      'title_en',
      'english',
      'en',
    ], required: false);
    int descIdx = _findColumnIndex(header, [
      'description',
      'desc',
      'details',
    ], required: false);

    // Fallback
    if (nameArIdx == -1) {
      // Assume 0=ID, 1=NameAR
      if (rows.first.length >= 2) {
        idIdx = 0;
        nameArIdx = 1;
      } else if (rows.first.length == 1) {
        nameArIdx = 0;
      }
    }
    // Final fallback
    if (nameArIdx == -1) nameArIdx = 0;

    final contentRows = rows.skip(1).toList();
    int orderIndex = 0;

    for (final row in contentRows) {
      if (row.length <= nameArIdx) continue;

      final id = idIdx >= 0 && row.length > idIdx
          ? row[idIdx].toString()
          : 'cat_$orderIndex';
      final nameAr = row[nameArIdx].toString();
      final nameEn = nameEnIdx >= 0 && row.length > nameEnIdx
          ? row[nameEnIdx].toString()
          : '';
      final desc = descIdx >= 0 && row.length > descIdx
          ? row[descIdx].toString()
          : '';

      await db.insert('azkar_categories', {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'description': desc,
        'order_index': orderIndex,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      orderIndex++;
    }
  }

  Future<void> _importAzkarFile(Database db, File file, String fileName) async {
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

    final header = rows.first.map((e) {
      var s = e.toString().toLowerCase().trim();
      if (s.startsWith('\ufeff')) s = s.substring(1);
      return s;
    }).toList();

    int textArIdx = _findColumnIndex(header, [
      'text_ar',
      'text',
      'zikr',
      'content',
      'arabic',
    ], required: false);
    int textEnIdx = _findColumnIndex(header, [
      'text_en',
      'translation',
      'english',
    ], required: false);
    int countIdx = _findColumnIndex(header, [
      'count',
      'repeat',
      'times',
    ], required: false);
    int benefitIdx = _findColumnIndex(header, [
      'benefit',
      'fadl',
      'virtue',
    ], required: false);
    int refIdx = _findColumnIndex(header, [
      'reference',
      'source',
      'ref',
    ], required: false);
    int categoryIdx = _findColumnIndex(header, [
      'category',
      'category_id',
    ], required: false);

    // Fallback logic
    if (textArIdx == -1) {
      // Heuristic: Text is usually 0, Count is 1, Benefit is 2
      if (rows.first.length >= 1) {
        textArIdx = 0;
        if (rows.first.length >= 2) countIdx = 1;
        if (rows.first.length >= 3) benefitIdx = 2;
      }
    }
    // Final fallback
    if (textArIdx == -1) textArIdx = 0;

    // Check header data
    bool headerIsData = false;
    if (rows.isNotEmpty) {
      // If count column parses to int, valid row 0?
      // But often header 'count' string can't parse.
      // If 'text_ar' is actually Arabic text?
      // Just check if count column (if exists) is int.
      if (countIdx >= 0 && countIdx < rows.first.length) {
        if (int.tryParse(rows.first[countIdx].toString()) != null) {
          headerIsData = true;
        }
      }
    }

    // Derive category from filename
    final defaultCategory = fileName
        .replaceAll('.csv', '')
        .replaceAll('_', ' ');

    // Ensure category exists
    await db.insert('azkar_categories', {
      'id': defaultCategory,
      'name_ar': defaultCategory,
      'name_en': defaultCategory,
      'order_index': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final contentRows = headerIsData ? rows : rows.skip(1).toList();
    int orderIndex = 0;

    await db.transaction((txn) async {
      var batch = txn.batch();

      for (final row in contentRows) {
        if (row.length <= textArIdx) continue;

        final textAr = row[textArIdx].toString();
        if (textAr.isEmpty) continue;

        final textEn = textEnIdx >= 0 && row.length > textEnIdx
            ? row[textEnIdx].toString()
            : '';
        final count = countIdx >= 0 && row.length > countIdx
            ? int.tryParse(row[countIdx].toString()) ?? 1
            : 1;
        final benefit = benefitIdx >= 0 && row.length > benefitIdx
            ? row[benefitIdx].toString()
            : '';
        final reference = refIdx >= 0 && row.length > refIdx
            ? row[refIdx].toString()
            : '';
        final category = categoryIdx >= 0 && row.length > categoryIdx
            ? row[categoryIdx].toString()
            : defaultCategory;

        batch.insert('azkar', {
          'category_id': category,
          'text_ar': textAr,
          'text_en': textEn,
          'count': count,
          'benefit': benefit,
          'reference': reference,
          'order_index': orderIndex,
        });

        orderIndex++;
        if (orderIndex % 100 == 0) {
          await batch.commit(noResult: true);
          batch = txn.batch();
        }
      }

      await batch.commit(noResult: true);
    });
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

  Future<void> close() async {
    if (_database?.isOpen == true) {
      await _database!.close();
      _database = null;
    }
  }
}
