import 'package:sqflite/sqflite.dart';
import '../domain/models/quran_search_result.dart';
import '../../../core/db/quran_database.dart';
import '../../../core/utils/arabic_normalizer.dart';

/// Repository for searching Quran ayahs with support for FTS and LIKE fallback.
class QuranSearchRepository {
  /// Search ayahs with optional filters.
  /// Returns matched ayahs with surah names and highlighted snippets.
  Future<List<QuranSearchResult>> searchAyahs(
    String query, {
    int limit = 30,
    int offset = 0,
    int? surahId,
    bool exact = false,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final db = await QuranDatabase.instance.database;
    final normalizedQuery = ArabicNormalizer.normalize(query);

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // Search in normalized text
    if (exact) {
      whereConditions.add('a.search_text LIKE ?');
      whereArgs.add('%$normalizedQuery%');
    } else {
      // Split query into words and match all
      final words = normalizedQuery.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          whereConditions.add('a.search_text LIKE ?');
          whereArgs.add('%$word%');
        }
      }
    }

    // Filter by surah if specified
    if (surahId != null) {
      whereConditions.add('a.surah = ?');
      whereArgs.add(surahId);
    }

    if (whereConditions.isEmpty) {
      return [];
    }

    final whereClause = whereConditions.join(' AND ');

    // Query with JOIN to get surah names
    final sql =
        '''
      SELECT 
        a.surah,
        a.ayah,
        a.text,
        a.page,
        s.name_ar as surah_name_ar,
        s.name_en as surah_name_en
      FROM quran_ayahs a
      LEFT JOIN quran_surahs s ON a.surah = s.surah
      WHERE $whereClause
      ORDER BY a.surah ASC, a.ayah ASC
      LIMIT ? OFFSET ?
    ''';

    whereArgs.addAll([limit, offset]);

    final results = await db.rawQuery(sql, whereArgs);

    return results.map((row) {
      // Create highlighted snippet
      final text = row['text'] as String;
      final snippet = _createHighlightedSnippet(text, query);

      return QuranSearchResult(
        surahId: row['surah'] as int,
        ayahNumber: row['ayah'] as int,
        ayahKey: '${row['surah']}:${row['ayah']}',
        text: text,
        surahNameAr: row['surah_name_ar'] as String? ?? '',
        surahNameEn: row['surah_name_en'] as String? ?? '',
        highlightedSnippet: snippet,
        page: row['page'] as int?,
      );
    }).toList();
  }

  /// Count total results for pagination
  Future<int> countSearchResults(
    String query, {
    int? surahId,
    bool exact = false,
  }) async {
    if (query.trim().isEmpty) {
      return 0;
    }

    final db = await QuranDatabase.instance.database;
    final normalizedQuery = ArabicNormalizer.normalize(query);

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (exact) {
      whereConditions.add('search_text LIKE ?');
      whereArgs.add('%$normalizedQuery%');
    } else {
      final words = normalizedQuery.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          whereConditions.add('search_text LIKE ?');
          whereArgs.add('%$word%');
        }
      }
    }

    if (surahId != null) {
      whereConditions.add('surah = ?');
      whereArgs.add(surahId);
    }

    if (whereConditions.isEmpty) {
      return 0;
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quran_ayahs WHERE ${whereConditions.join(' AND ')}',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Create a snippet with the matched text highlighted
  String _createHighlightedSnippet(String text, String query) {
    // For Arabic text, we keep the full text as the snippet
    // Highlighting is done in the UI layer
    // Here we just mark the match boundaries

    final normalizedText = ArabicNormalizer.normalize(text);
    final normalizedQuery = ArabicNormalizer.normalize(query);

    // Find match position in normalized text
    final matchIndex = normalizedText.indexOf(normalizedQuery);

    if (matchIndex == -1) {
      // Try word-by-word matching
      final words = normalizedQuery.split(RegExp(r'\s+'));
      bool hasMatch = words.any(
        (word) => word.isNotEmpty && normalizedText.contains(word),
      );

      if (!hasMatch) {
        // Return truncated text
        return text.length > 150 ? '${text.substring(0, 150)}...' : text;
      }
    }

    // Return full text for now, UI will handle highlighting
    return text;
  }

  /// Get suggestions for search (autocomplete)
  Future<List<String>> getSuggestions(String query, {int limit = 5}) async {
    if (query.trim().length < 2) {
      return [];
    }

    final results = await searchAyahs(query, limit: limit);

    // Extract unique first few words from each result
    final suggestions = <String>{};
    for (final result in results) {
      final words = result.text.split(' ');
      if (words.length >= 3) {
        suggestions.add(words.take(3).join(' '));
      }
    }

    return suggestions.take(limit).toList();
  }
}
