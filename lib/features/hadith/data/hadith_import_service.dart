import 'dart:async';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../../core/db/hadith_database.dart';
import '../../../core/utils/hadith_csv_mapper.dart';
import '../../../core/utils/arabic_normalizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ImportPhase { idle, importing, completed, error }

class HadithImportProgress {
  final String bookId;
  final int inserted;
  final int totalEstimated;
  final ImportPhase phase;
  final String? error;

  HadithImportProgress({
    required this.bookId,
    required this.inserted,
    required this.totalEstimated,
    required this.phase,
    this.error,
  });
}

class HadithImportService {
  final _progressController =
      StreamController<HadithImportProgress>.broadcast();
  Stream<HadithImportProgress> get progressStream => _progressController.stream;

  static const String _dbVersionKey = 'hadith_db_version';
  static const String _scriptKey = 'hadith_script';
  static const int currentVersion = 2;

  final List<Map<String, String>> _books = [
    {'id': 'Maliks_Muwataa', 'ar': 'موطأ مالك', 'en': 'Malik\'s Muwatta'},
    {'id': 'Musnad_Ahmad_Ibn-Hanbal', 'ar': 'مسند أحمد', 'en': 'Musnad Ahmad'},
    {'id': 'Sahih_Al-Bukhari', 'ar': 'صحيح البخاري', 'en': 'Sahih Al-Bukhari'},
    {'id': 'Sahih_Muslim', 'ar': 'صحيح مسلم', 'en': 'Sahih Muslim'},
    {'id': 'Sunan_Abu-Dawud', 'ar': 'سنن أبي داود', 'en': 'Sunan Abu Dawud'},
    {'id': 'Sunan_Al-Darimi', 'ar': 'سنن الدارمي', 'en': 'Sunan Al-Darimi'},
    {'id': 'Sunan_Al-Nasai', 'ar': 'سنن النسائي', 'en': 'Sunan Al-Nasai'},
    {'id': 'Sunan_Al-Tirmidhi', 'ar': 'سنن الترمذي', 'en': 'Sunan Al-Tirmidhi'},
    {'id': 'Sunan_Ibn-Maja', 'ar': 'سنن ابن ماجه', 'en': 'Sunan Ibn Maja'},
  ];

  Future<bool> needsImport() async {
    // IMPORTANT: This app no longer uses bundled Hadith assets.
    // All Hadith content is downloaded from CDN via ContentDownloadService.
    // The old bundled asset import system is completely disabled.

    final prefs = await SharedPreferences.getInstance();

    // Check if Hadith was downloaded via CDN (new content system)
    final cdnVersion = prefs.getInt('content_version_hadith') ?? 0;

    // If CDN version exists, content is already imported
    if (cdnVersion > 0) {
      return false; // Content ready
    }

    // If CDN version doesn't exist, DON'T try to import from bundled assets
    // (they don't exist). User needs to download content from settings.
    return false; // Don't attempt bundled asset import
  }

  Future<void> startImport(String scriptType) async {
    try {
      final db = await HadithDatabase.instance.database;
      await db.transaction((txn) async {
        await txn.delete('hadith_items');
        await txn.delete('hadith_books');
      });

      for (final bookInfo in _books) {
        final bookId = bookInfo['id']!;
        final fileName = scriptType == 'tashkeel'
            ? '${bookId.toLowerCase()}_ahadith_mushakkala_mufassala.utf8.csv'
            : '${bookId.toLowerCase()}_ahadith.utf8.csv';
        final path = 'assets/source/hadith/$bookId/$fileName';

        _progressController.add(
          HadithImportProgress(
            bookId: bookInfo['ar']!,
            inserted: 0,
            totalEstimated: 0,
            phase: ImportPhase.importing,
          ),
        );

        final data = await rootBundle.loadString(path);
        // Use \n as EOL since auto-detect might fail for Arabic CSVs
        final List<List<dynamic>> rows = const CsvToListConverter(
          eol: '\n',
        ).convert(data);

        if (rows.isEmpty) continue;

        // Determine if first row is headers
        final firstRow = rows[0];
        final bool hasHeaders = firstRow.any(
          (cell) => [
            'text',
            'hadith',
            'matn',
            'arabic',
            'number',
            'no',
            'id',
          ].contains(cell.toString().toLowerCase()),
        );

        final headers = hasHeaders
            ? firstRow.map((e) => e.toString()).toList()
            : firstRow.map((e) => '').toList(); // Dummy headers for mapper

        final contentRows = hasHeaders ? rows.sublist(1) : rows;

        await db.transaction((txn) async {
          var batch = txn.batch();
          int inserted = 0;

          for (int i = 0; i < contentRows.length; i++) {
            final mapped = HadithCsvMapper.mapRow(headers, contentRows[i], i);
            final textAr = mapped['text_ar'] as String;
            if (textAr.isEmpty) continue;

            final search_text = ArabicNormalizer.normalize(textAr);

            batch.insert('hadith_items', {
              'uid': '$bookId:${mapped['number']}',
              'book_id': bookId,
              'number': mapped['number'],
              'chapter': mapped['chapter'],
              'text_ar': textAr,
              'raw_json': mapped['raw_json'],
              'search_text': search_text,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            inserted++;
            if (inserted % 500 == 0) {
              await batch.commit(noResult: true);
              batch = txn.batch(); // Create a NEW batch
              _progressController.add(
                HadithImportProgress(
                  bookId: bookInfo['ar']!,
                  inserted: inserted,
                  totalEstimated: contentRows.length,
                  phase: ImportPhase.importing,
                ),
              );
            }
          }
          await batch.commit(noResult: true);
        });

        await db.insert('hadith_books', {
          'id': bookId,
          'title_ar': bookInfo['ar']!,
          'title_en': bookInfo['en']!,
          'total_count': contentRows.length,
          'has_tashkeel': scriptType == 'tashkeel' ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dbVersionKey, currentVersion);
      await prefs.setString(_scriptKey, scriptType);

      _progressController.add(
        HadithImportProgress(
          bookId: '',
          inserted: 0,
          totalEstimated: 0,
          phase: ImportPhase.completed,
        ),
      );
    } catch (e) {
      _progressController.add(
        HadithImportProgress(
          bookId: '',
          inserted: 0,
          totalEstimated: 0,
          phase: ImportPhase.error,
          error: e.toString(),
        ),
      );
    }
  }

  void dispose() {
    _progressController.close();
  }
}
