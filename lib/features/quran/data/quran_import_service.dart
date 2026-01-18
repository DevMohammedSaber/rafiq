import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:rafiq/core/utils/arabic_normalizer.dart';
import 'package:rafiq/core/config/content_config.dart';
import 'package:rafiq/core/content/content_cache_paths.dart';
import 'package:rafiq/features/quran/data/quran_database_cdn.dart';
import 'package:rafiq/features/quran/data/surah_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'quran_page_map.dart';

enum QuranImportPhase { idle, importing, completed, error }

class QuranImportProgress {
  final int inserted;
  final int totalEstimated;
  final QuranImportPhase phase;
  final String? error;

  QuranImportProgress({
    required this.inserted,
    required this.totalEstimated,
    required this.phase,
    this.error,
  });
}

class QuranImportService {
  final _progressController = StreamController<QuranImportProgress>.broadcast();
  Stream<QuranImportProgress> get progressStream => _progressController.stream;

  static const String _dbVersionKey = 'quran_db_version';
  static const int currentVersion = 2; // Bumped for page column

  Future<bool> needsImport() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the same key as ContentDownloadService for consistency
    final version = prefs.getInt(ContentConfig.prefKeyQuranVersion) ?? 0;

    final db = await QuranDatabaseCdn.instance.database;
    final ayahCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quran_ayahs'),
        ) ??
        0;

    return version == 0 || ayahCount == 0;
  }

  Future<void> startImport() async {
    try {
      final db = await QuranDatabaseCdn.instance.database;

      _progressController.add(
        QuranImportProgress(
          inserted: 0,
          totalEstimated: 6236,
          phase: QuranImportPhase.importing,
        ),
      );

      String data;
      final csvPath = ContentCachePaths.quranCsvPath;

      if (await File(csvPath).exists()) {
        data = await File(csvPath).readAsString();
      } else {
        // Fallback to assets ONLY if bundled (might not be in future)
        try {
          data = await rootBundle.loadString('assets/source/quran/quran.csv');
        } catch (e) {
          throw Exception(
            "Quran data not found. Please download it from settings.",
          );
        }
      }

      final rows = const CsvToListConverter(
        fieldDelimiter: '|',
        eol: '\n',
      ).convert(data);

      if (rows.isEmpty) throw Exception('CSV is empty');

      final headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
      final contentRows = rows.sublist(1);

      // Detect columns
      int surahIdx = _detectColumn(headers, [
        'surah',
        'sura',
        'surah_id',
        'chapter',
        's',
      ], 0);
      int ayahIdx = _detectColumn(headers, [
        'ayah',
        'aya',
        'verse',
        'ayah_id',
        'a',
      ], 1);
      int textIdx = _detectColumn(headers, [
        'text',
        'arabic',
        'aya_text',
        'uthmani',
        'text_ar',
      ], 2);

      await db.transaction((txn) async {
        var batch = txn.batch();
        int inserted = 0;

        for (final row in contentRows) {
          if (row.length <=
              (textIdx > surahIdx
                  ? (textIdx > ayahIdx ? textIdx : ayahIdx)
                  : (surahIdx > ayahIdx ? surahIdx : ayahIdx))) {
            continue;
          }

          final surah = int.tryParse(row[surahIdx].toString());
          final ayah = int.tryParse(row[ayahIdx].toString());
          final text = row[textIdx].toString();

          if (surah == null || ayah == null || text.isEmpty) continue;
          if (surah < 1 || surah > 114) continue;

          final searchText = ArabicNormalizer.normalize(text);

          // Get page from map
          int? page = quranPageMap[surah]?[ayah];

          batch.insert('quran_ayahs', {
            'id': '$surah:$ayah',
            'surah': surah,
            'ayah': ayah,
            'text': text,
            'search_text': searchText,
            'page': page,
          });

          inserted++;
          if (inserted % 500 == 0) {
            await batch.commit(noResult: true);
            batch = txn.batch();
            _progressController.add(
              QuranImportProgress(
                inserted: inserted,
                totalEstimated: contentRows.length,
                phase: QuranImportPhase.importing,
              ),
            );
          }
        }
        await batch.commit(noResult: true);
      });

      // Populate quran_surahs
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final surah in surahNames) {
          final count =
              Sqflite.firstIntValue(
                await txn.rawQuery(
                  'SELECT COUNT(*) FROM quran_ayahs WHERE surah = ?',
                  [surah.id],
                ),
              ) ??
              0;

          batch.insert('quran_surahs', {
            'surah': surah.id,
            'name_ar': surah.ar,
            'name_en': surah.en,
            'ayah_count': count,
            'place': surah.place,
            'type': surah.type,
          });
        }
        await batch.commit(noResult: true);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dbVersionKey, currentVersion);

      _progressController.add(
        QuranImportProgress(
          inserted: contentRows.length,
          totalEstimated: contentRows.length,
          phase: QuranImportPhase.completed,
        ),
      );
    } catch (e) {
      _progressController.add(
        QuranImportProgress(
          inserted: 0,
          totalEstimated: 0,
          phase: QuranImportPhase.error,
          error: e.toString(),
        ),
      );
    }
  }

  int _detectColumn(
    List<String> headers,
    List<String> candidates,
    int fallback,
  ) {
    for (int i = 0; i < headers.length; i++) {
      if (candidates.contains(headers[i])) return i;
    }
    return fallback;
  }

  void dispose() {
    _progressController.close();
  }
}
