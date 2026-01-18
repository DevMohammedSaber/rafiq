import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/db/quran_database.dart';

/// Repository for managing Quran page mappings (604 pages standard Mushaf).
/// Supports lazy loading and LRU caching for performance.
class PageMappingRepository {
  static const int _totalPages = 604;
  static const int _maxCacheSize = 10;
  static const String _mappingAssetPath = 'assets/quran/page_map_604.json';

  // LRU cache for page ayahs
  final LinkedHashMap<int, List<String>> _pageCache = LinkedHashMap();

  // Full mapping loaded from JSON (if available)
  Map<String, List<String>>? _pageToAyahsMap;
  Map<String, int>? _ayahToPageMap;
  bool _isLoaded = false;
  bool _loadFailed = false;

  /// Load the page mapping from JSON asset
  Future<void> loadMapping() async {
    if (_isLoaded || _loadFailed) return;

    try {
      final jsonString = await rootBundle.loadString(_mappingAssetPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Parse pageToAyahs
      final pageToAyahs = data['pageToAyahs'] as Map<String, dynamic>?;
      if (pageToAyahs != null) {
        _pageToAyahsMap = {};
        _ayahToPageMap = {};

        pageToAyahs.forEach((pageStr, ayahsList) {
          final pageNum = int.tryParse(pageStr);
          if (pageNum != null && ayahsList is List) {
            final ayahs = ayahsList.cast<String>().toList();
            _pageToAyahsMap![pageStr] = ayahs;

            // Build reverse mapping
            for (final ayahKey in ayahs) {
              _ayahToPageMap![ayahKey] = pageNum;
            }
          }
        });
      }

      _isLoaded = true;
    } catch (e) {
      // JSON mapping not available or incomplete, will fallback to database
      _loadFailed = true;
    }
  }

  /// Get total page count
  int getPageCount() => _totalPages;

  /// Get page number for a specific ayah
  Future<int?> getPageForAyah(int surahId, int ayahNumber) async {
    await loadMapping();

    final ayahKey = '$surahId:$ayahNumber';

    // Try JSON mapping first
    if (_ayahToPageMap != null && _ayahToPageMap!.containsKey(ayahKey)) {
      return _ayahToPageMap![ayahKey];
    }

    // Fallback to database
    return _getPageFromDatabase(surahId, ayahNumber);
  }

  /// Get all ayah keys for a specific page
  Future<List<String>> getAyahsForPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) {
      return [];
    }

    // Check cache first
    if (_pageCache.containsKey(pageNumber)) {
      // Move to end (LRU)
      final cached = _pageCache.remove(pageNumber)!;
      _pageCache[pageNumber] = cached;
      return cached;
    }

    await loadMapping();

    List<String> ayahKeys = [];

    // Try JSON mapping first
    if (_pageToAyahsMap != null &&
        _pageToAyahsMap!.containsKey(pageNumber.toString())) {
      ayahKeys = List.from(_pageToAyahsMap![pageNumber.toString()]!);
    } else {
      // Fallback to database
      ayahKeys = await _getAyahsFromDatabase(pageNumber);
    }

    // Add to cache
    _addToCache(pageNumber, ayahKeys);

    return ayahKeys;
  }

  /// Get the first ayah key for a page
  Future<String?> getFirstAyahKeyForPage(int pageNumber) async {
    final ayahs = await getAyahsForPage(pageNumber);
    return ayahs.isNotEmpty ? ayahs.first : null;
  }

  /// Get page number for a given ayah (from database)
  Future<int?> _getPageFromDatabase(int surahId, int ayahNumber) async {
    try {
      final db = await QuranDatabase.instance.database;
      final result = await db.query(
        'quran_ayahs',
        columns: ['page'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surahId, ayahNumber],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['page'] as int?;
      }
    } catch (e) {
      // Database query failed
    }
    return null;
  }

  /// Get ayahs for a page from database
  Future<List<String>> _getAyahsFromDatabase(int pageNumber) async {
    try {
      final db = await QuranDatabase.instance.database;
      final result = await db.query(
        'quran_ayahs',
        columns: ['surah', 'ayah'],
        where: 'page = ?',
        whereArgs: [pageNumber],
        orderBy: 'surah ASC, ayah ASC',
      );

      return result.map((row) => '${row['surah']}:${row['ayah']}').toList();
    } catch (e) {
      return [];
    }
  }

  /// Add page to LRU cache
  void _addToCache(int pageNumber, List<String> ayahKeys) {
    _pageCache[pageNumber] = ayahKeys;

    // Evict oldest if cache is full
    while (_pageCache.length > _maxCacheSize) {
      _pageCache.remove(_pageCache.keys.first);
    }
  }

  /// Clear the cache
  void clearCache() {
    _pageCache.clear();
  }

  /// Force reload mapping
  Future<void> reloadMapping() async {
    _isLoaded = false;
    _loadFailed = false;
    _pageToAyahsMap = null;
    _ayahToPageMap = null;
    _pageCache.clear();
    await loadMapping();
  }
}
