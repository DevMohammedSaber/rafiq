import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/content/content_cache_paths.dart';
import '../../../core/utils/arabic_normalizer.dart';

/// Quran database manager for CDN-imported content.
/// Handles database creation, CSV import, and queries.
class QuranDatabaseCdn {
  static final QuranDatabaseCdn instance = QuranDatabaseCdn._();
  QuranDatabaseCdn._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = ContentCachePaths.quranDbPath;
    await ContentCachePaths.ensureDirectoryExists(dbPath);

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quran_surahs (
        id INTEGER PRIMARY KEY,
        surah INTEGER UNIQUE NOT NULL,
        index_str TEXT,
        name_en TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        ayah_count INTEGER,
        place TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quran_ayahs (
        id TEXT PRIMARY KEY,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text TEXT NOT NULL,
        search_text TEXT,
        page INTEGER,
        UNIQUE(surah, ayah)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ayahs_surah ON quran_ayahs(surah)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ayahs_page ON quran_ayahs(page)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ayahs_search ON quran_ayahs(search_text)',
    );
  }

  /// Import Quran data from CSV file.
  /// CSV format: surah_id, ayah_number, text, page (optional)
  Future<void> importFromCsv(
    String csvPath,
    void Function(int current, int total) onProgress,
  ) async {
    final db = await database;
    final file = File(csvPath);
    if (!await file.exists()) {
      throw Exception('Quran CSV file not found: $csvPath');
    }

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

    if (rows.isEmpty) {
      throw Exception('Quran CSV is empty');
    }

    // Find column indices
    final header = rows.first.map((e) {
      var s = e.toString().toLowerCase().trim();
      if (s.startsWith('\ufeff')) s = s.substring(1);
      return s;
    }).toList();

    print('CSV Header parsed: $header using delimiter: "$delimiter"');

    int surahIdx = _findColumnIndex(header, [
      'surah',
      'surah_id',
      'chapter',
      'sura',
      'sura_no',
      'surah_number',
      'chapter_id',
    ], required: false);

    int ayahIdx = _findColumnIndex(header, [
      'ayah',
      'ayah_number',
      'verse',
      'aya',
      'aya_no',
      'verse_id',
    ], required: false);

    int textIdx = _findColumnIndex(header, [
      'text',
      'text_ar',
      'uthmani',
      'arabic',
      'content',
      'ayah_text',
      'ayah_text_original',
    ], required: false);

    int pageIdx = _findColumnIndex(header, [
      'page',
      'page_number',
    ], required: false);

    // Fallback to positional if headers not found (and we have enough columns)
    if (surahIdx == -1 && rows.first.length >= 3) {
      // Heuristic: check if col 0 or 1 looks like surah
      // Assume standard: surah, ayah, text OR id, surah, ayah, text
      if (rows.first.length == 3) {
        surahIdx = 0;
        ayahIdx = 1;
        textIdx = 2;
      } else if (rows.first.length >= 4) {
        // Maybe index, surah, ayah, text
        surahIdx = 1;
        ayahIdx = 2;
        textIdx = 3;
      }
    }

    // Final fallback defaults
    if (surahIdx == -1) surahIdx = 0;
    if (ayahIdx == -1) ayahIdx = 1;
    if (textIdx == -1) textIdx = 2;

    // Validate indices within bounds
    if (rows.isNotEmpty) {
      final maxIdx = rows.first.length - 1;
      if (surahIdx > maxIdx || ayahIdx > maxIdx || textIdx > maxIdx) {
        throw Exception(
          'CSV columns mismatch. Detected: $header. Need indices: $surahIdx, $ayahIdx, $textIdx',
        );
      }
    }

    // If we fell back to positional, maybe row 0 IS data?
    // If row 0 "surah" column parses to int, valid. If string "surah", invalid.
    // The loop handles parsing check.

    // But if we skipped header (rows.skip(1)), and fallback used indices 0,1,2 on UNLABELED csv, we lost first ayah!
    // UNLABELED means row 0 is data.
    // Check if row 0 (header) parses as valid data?
    bool headerIsData = false;
    if (rows.isNotEmpty) {
      final firstSurah = int.tryParse(rows.first[surahIdx].toString());
      if (firstSurah != null && firstSurah >= 1 && firstSurah <= 114) {
        headerIsData = true;
      }
    }

    final contentRows = headerIsData ? rows : rows.skip(1).toList();
    final total = contentRows.length;

    // Clear existing data
    await db.delete('quran_ayahs');
    await db.delete('quran_surahs');

    // Track surahs for metadata
    final surahs = <int, Map<String, dynamic>>{};

    await db.transaction((txn) async {
      var batch = txn.batch();
      int inserted = 0;

      for (final row in contentRows) {
        if (row.length <= textIdx) continue;

        final surah = int.tryParse(row[surahIdx].toString());
        final ayah = int.tryParse(row[ayahIdx].toString());
        final text = row[textIdx].toString();

        if (surah == null || ayah == null || text.isEmpty) continue;
        if (surah < 1 || surah > 114) continue;

        final searchText = ArabicNormalizer.normalize(text);
        final page = pageIdx >= 0 && row.length > pageIdx
            ? int.tryParse(row[pageIdx].toString())
            : null;

        batch.insert('quran_ayahs', {
          'id': '$surah:$ayah',
          'surah': surah,
          'ayah': ayah,
          'text': text,
          'search_text': searchText,
          'page': page,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Track surah info
        if (!surahs.containsKey(surah)) {
          surahs[surah] = {'surah': surah, 'ayah_count': 0};
        }
        surahs[surah]!['ayah_count'] =
            (surahs[surah]!['ayah_count'] as int) + 1;

        inserted++;
        if (inserted % 500 == 0) {
          await batch.commit(noResult: true);
          batch = txn.batch();
          onProgress(inserted, total);
        }
      }

      await batch.commit(noResult: true);
      onProgress(total, total);
    });

    // Insert surah metadata
    await _insertSurahMetadata(db, surahs);
  }

  Future<void> _insertSurahMetadata(
    Database db,
    Map<int, Map<String, dynamic>> surahs,
  ) async {
    // Surah names (hardcoded as they dont change)
    final surahNames = _getSurahNames();

    final batch = db.batch();
    for (final entry in surahs.entries) {
      final surahId = entry.key;
      final info = surahNames[surahId] ?? {};

      batch.insert('quran_surahs', {
        'id': surahId,
        'surah': surahId,
        'index_str': surahId.toString().padLeft(3, '0'),
        'name_en': info['name_en'] ?? 'Surah $surahId',
        'name_ar': info['name_ar'] ?? 'سورة $surahId',
        'ayah_count': entry.value['ayah_count'],
        'place': info['place'] ?? 'Mecca',
        'type': info['type'] ?? 'Makkiyah',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
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

  Map<int, Map<String, String>> _getSurahNames() {
    return {
      1: {
        'name_en': 'Al-Fatihah',
        'name_ar': 'الفاتحة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      2: {
        'name_en': 'Al-Baqarah',
        'name_ar': 'البقرة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      3: {
        'name_en': "Ali 'Imran",
        'name_ar': 'آل عمران',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      4: {
        'name_en': "An-Nisa'",
        'name_ar': 'النساء',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      5: {
        'name_en': "Al-Ma'idah",
        'name_ar': 'المائدة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      6: {
        'name_en': "Al-An'am",
        'name_ar': 'الأنعام',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      7: {
        'name_en': "Al-A'raf",
        'name_ar': 'الأعراف',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      8: {
        'name_en': 'Al-Anfal',
        'name_ar': 'الأنفال',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      9: {
        'name_en': 'At-Tawbah',
        'name_ar': 'التوبة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      10: {
        'name_en': 'Yunus',
        'name_ar': 'يونس',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      11: {
        'name_en': 'Hud',
        'name_ar': 'هود',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      12: {
        'name_en': 'Yusuf',
        'name_ar': 'يوسف',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      13: {
        'name_en': "Ar-Ra'd",
        'name_ar': 'الرعد',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      14: {
        'name_en': 'Ibrahim',
        'name_ar': 'إبراهيم',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      15: {
        'name_en': 'Al-Hijr',
        'name_ar': 'الحجر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      16: {
        'name_en': 'An-Nahl',
        'name_ar': 'النحل',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      17: {
        'name_en': "Al-Isra'",
        'name_ar': 'الإسراء',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      18: {
        'name_en': 'Al-Kahf',
        'name_ar': 'الكهف',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      19: {
        'name_en': 'Maryam',
        'name_ar': 'مريم',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      20: {
        'name_en': 'Ta-Ha',
        'name_ar': 'طه',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      21: {
        'name_en': "Al-Anbiya'",
        'name_ar': 'الأنبياء',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      22: {
        'name_en': 'Al-Hajj',
        'name_ar': 'الحج',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      23: {
        'name_en': "Al-Mu'minun",
        'name_ar': 'المؤمنون',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      24: {
        'name_en': 'An-Nur',
        'name_ar': 'النور',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      25: {
        'name_en': 'Al-Furqan',
        'name_ar': 'الفرقان',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      26: {
        'name_en': "Ash-Shu'ara'",
        'name_ar': 'الشعراء',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      27: {
        'name_en': 'An-Naml',
        'name_ar': 'النمل',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      28: {
        'name_en': 'Al-Qasas',
        'name_ar': 'القصص',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      29: {
        'name_en': "Al-'Ankabut",
        'name_ar': 'العنكبوت',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      30: {
        'name_en': 'Ar-Rum',
        'name_ar': 'الروم',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      31: {
        'name_en': 'Luqman',
        'name_ar': 'لقمان',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      32: {
        'name_en': 'As-Sajdah',
        'name_ar': 'السجدة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      33: {
        'name_en': 'Al-Ahzab',
        'name_ar': 'الأحزاب',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      34: {
        'name_en': "Saba'",
        'name_ar': 'سبأ',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      35: {
        'name_en': 'Fatir',
        'name_ar': 'فاطر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      36: {
        'name_en': 'Ya-Sin',
        'name_ar': 'يس',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      37: {
        'name_en': 'As-Saffat',
        'name_ar': 'الصافات',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      38: {
        'name_en': 'Sad',
        'name_ar': 'ص',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      39: {
        'name_en': 'Az-Zumar',
        'name_ar': 'الزمر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      40: {
        'name_en': 'Ghafir',
        'name_ar': 'غافر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      41: {
        'name_en': 'Fussilat',
        'name_ar': 'فصلت',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      42: {
        'name_en': 'Ash-Shura',
        'name_ar': 'الشورى',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      43: {
        'name_en': 'Az-Zukhruf',
        'name_ar': 'الزخرف',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      44: {
        'name_en': 'Ad-Dukhan',
        'name_ar': 'الدخان',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      45: {
        'name_en': 'Al-Jathiyah',
        'name_ar': 'الجاثية',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      46: {
        'name_en': 'Al-Ahqaf',
        'name_ar': 'الأحقاف',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      47: {
        'name_en': 'Muhammad',
        'name_ar': 'محمد',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      48: {
        'name_en': 'Al-Fath',
        'name_ar': 'الفتح',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      49: {
        'name_en': 'Al-Hujurat',
        'name_ar': 'الحجرات',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      50: {
        'name_en': 'Qaf',
        'name_ar': 'ق',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      51: {
        'name_en': 'Adh-Dhariyat',
        'name_ar': 'الذاريات',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      52: {
        'name_en': 'At-Tur',
        'name_ar': 'الطور',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      53: {
        'name_en': 'An-Najm',
        'name_ar': 'النجم',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      54: {
        'name_en': 'Al-Qamar',
        'name_ar': 'القمر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      55: {
        'name_en': 'Ar-Rahman',
        'name_ar': 'الرحمن',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      56: {
        'name_en': "Al-Waqi'ah",
        'name_ar': 'الواقعة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      57: {
        'name_en': 'Al-Hadid',
        'name_ar': 'الحديد',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      58: {
        'name_en': 'Al-Mujadilah',
        'name_ar': 'المجادلة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      59: {
        'name_en': 'Al-Hashr',
        'name_ar': 'الحشر',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      60: {
        'name_en': 'Al-Mumtahanah',
        'name_ar': 'الممتحنة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      61: {
        'name_en': 'As-Saff',
        'name_ar': 'الصف',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      62: {
        'name_en': "Al-Jumu'ah",
        'name_ar': 'الجمعة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      63: {
        'name_en': 'Al-Munafiqun',
        'name_ar': 'المنافقون',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      64: {
        'name_en': 'At-Taghabun',
        'name_ar': 'التغابن',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      65: {
        'name_en': 'At-Talaq',
        'name_ar': 'الطلاق',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      66: {
        'name_en': 'At-Tahrim',
        'name_ar': 'التحريم',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      67: {
        'name_en': 'Al-Mulk',
        'name_ar': 'الملك',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      68: {
        'name_en': 'Al-Qalam',
        'name_ar': 'القلم',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      69: {
        'name_en': 'Al-Haqqah',
        'name_ar': 'الحاقة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      70: {
        'name_en': "Al-Ma'arij",
        'name_ar': 'المعارج',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      71: {
        'name_en': 'Nuh',
        'name_ar': 'نوح',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      72: {
        'name_en': 'Al-Jinn',
        'name_ar': 'الجن',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      73: {
        'name_en': 'Al-Muzzammil',
        'name_ar': 'المزمل',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      74: {
        'name_en': 'Al-Muddaththir',
        'name_ar': 'المدثر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      75: {
        'name_en': 'Al-Qiyamah',
        'name_ar': 'القيامة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      76: {
        'name_en': 'Al-Insan',
        'name_ar': 'الإنسان',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      77: {
        'name_en': 'Al-Mursalat',
        'name_ar': 'المرسلات',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      78: {
        'name_en': "An-Naba'",
        'name_ar': 'النبأ',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      79: {
        'name_en': "An-Nazi'at",
        'name_ar': 'النازعات',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      80: {
        'name_en': "'Abasa",
        'name_ar': 'عبس',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      81: {
        'name_en': 'At-Takwir',
        'name_ar': 'التكوير',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      82: {
        'name_en': 'Al-Infitar',
        'name_ar': 'الانفطار',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      83: {
        'name_en': 'Al-Mutaffifin',
        'name_ar': 'المطففين',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      84: {
        'name_en': 'Al-Inshiqaq',
        'name_ar': 'الانشقاق',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      85: {
        'name_en': 'Al-Buruj',
        'name_ar': 'البروج',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      86: {
        'name_en': 'At-Tariq',
        'name_ar': 'الطارق',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      87: {
        'name_en': "Al-A'la",
        'name_ar': 'الأعلى',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      88: {
        'name_en': 'Al-Ghashiyah',
        'name_ar': 'الغاشية',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      89: {
        'name_en': 'Al-Fajr',
        'name_ar': 'الفجر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      90: {
        'name_en': 'Al-Balad',
        'name_ar': 'البلد',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      91: {
        'name_en': 'Ash-Shams',
        'name_ar': 'الشمس',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      92: {
        'name_en': 'Al-Layl',
        'name_ar': 'الليل',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      93: {
        'name_en': 'Ad-Duha',
        'name_ar': 'الضحى',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      94: {
        'name_en': 'Ash-Sharh',
        'name_ar': 'الشرح',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      95: {
        'name_en': 'At-Tin',
        'name_ar': 'التين',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      96: {
        'name_en': "Al-'Alaq",
        'name_ar': 'العلق',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      97: {
        'name_en': 'Al-Qadr',
        'name_ar': 'القدر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      98: {
        'name_en': 'Al-Bayyinah',
        'name_ar': 'البينة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      99: {
        'name_en': 'Az-Zalzalah',
        'name_ar': 'الزلزلة',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      100: {
        'name_en': "Al-'Adiyat",
        'name_ar': 'العاديات',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      101: {
        'name_en': "Al-Qari'ah",
        'name_ar': 'القارعة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      102: {
        'name_en': 'At-Takathur',
        'name_ar': 'التكاثر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      103: {
        'name_en': "Al-'Asr",
        'name_ar': 'العصر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      104: {
        'name_en': 'Al-Humazah',
        'name_ar': 'الهمزة',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      105: {
        'name_en': 'Al-Fil',
        'name_ar': 'الفيل',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      106: {
        'name_en': 'Quraysh',
        'name_ar': 'قريش',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      107: {
        'name_en': "Al-Ma'un",
        'name_ar': 'الماعون',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      108: {
        'name_en': 'Al-Kawthar',
        'name_ar': 'الكوثر',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      109: {
        'name_en': 'Al-Kafirun',
        'name_ar': 'الكافرون',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      110: {
        'name_en': 'An-Nasr',
        'name_ar': 'النصر',
        'place': 'Medina',
        'type': 'Madaniyah',
      },
      111: {
        'name_en': 'Al-Masad',
        'name_ar': 'المسد',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      112: {
        'name_en': 'Al-Ikhlas',
        'name_ar': 'الإخلاص',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      113: {
        'name_en': 'Al-Falaq',
        'name_ar': 'الفلق',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
      114: {
        'name_en': 'An-Nas',
        'name_ar': 'الناس',
        'place': 'Mecca',
        'type': 'Makkiyah',
      },
    };
  }

  /// Close the database
  Future<void> close() async {
    if (_database?.isOpen == true) {
      await _database!.close();
      _database = null;
    }
  }
}
