import 'dart:collection';
import '../domain/models/mushaf_page.dart';
import '../domain/models/surah_meta.dart';
import '../domain/models/surah.dart';
import 'quran_repository.dart';

class MushafDataRepository {
  static const int _maxCacheSize = 20;
  static const int _totalPages = 604;

  final QuranRepository _quranRepository;

  List<Surah>? _cachedSurahs;
  final LinkedHashMap<int, MushafPage> _pageCache = LinkedHashMap();

  MushafDataRepository({QuranRepository? quranRepository})
    : _quranRepository = quranRepository ?? QuranRepository();

  Future<void> loadIndex() async {
    if (_cachedSurahs != null) return;
    _cachedSurahs = await _quranRepository.loadSurahs();
  }

  int get totalPages => _totalPages;

  Future<List<SurahMeta>> getSurahs() async {
    await loadIndex();
    final List<SurahMeta> metas = [];

    // Efficiently get first page for each surah
    for (final surah in _cachedSurahs!) {
      final firstAyah = await _quranRepository.getAyah(surah.id, 1);
      metas.add(
        SurahMeta(
          id: surah.id,
          nameAr: surah.nameAr,
          nameEn: surah.nameEn,
          firstPage: firstAyah?.page,
        ),
      );
    }
    return metas;
  }

  Future<SurahMeta?> getSurahMeta(int id) async {
    await loadIndex();
    try {
      final surah = _cachedSurahs!.firstWhere((s) => s.id == id);
      final firstAyah = await _quranRepository.getAyah(id, 1);
      return SurahMeta(
        id: surah.id,
        nameAr: surah.nameAr,
        nameEn: surah.nameEn,
        firstPage: firstAyah?.page,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int?> getPageForAyah(int surahId, int ayahNumber) async {
    final ayah = await _quranRepository.getAyah(surahId, ayahNumber);
    return ayah?.page;
  }

  Future<int?> getFirstPageForSurah(int surahId) async {
    final ayah = await _quranRepository.getAyah(surahId, 1);
    return ayah?.page;
  }

  Future<MushafPage> getPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages) {
      throw Exception('Invalid page number: $pageNumber');
    }

    if (_pageCache.containsKey(pageNumber)) {
      final cached = _pageCache[pageNumber]!;
      _pageCache.remove(pageNumber);
      _pageCache[pageNumber] = cached;
      return cached;
    }

    try {
      // Find all ayahs on this page
      final db = await _quranRepository.getDb();
      final result = await db.query(
        'quran_ayahs',
        where: 'page = ?',
        whereArgs: [pageNumber],
        orderBy: 'surah ASC, ayah ASC',
      );

      List<MushafPageItem> pageItems;

      // If no results found with page data, use estimated fallback
      if (result.isEmpty) {
        pageItems = await _getEstimatedPageItems(pageNumber);
      } else {
        pageItems = result
            .map(
              (row) => MushafPageItem(
                surah: row['surah'] as int,
                ayah: row['ayah'] as int,
                text: row['text'] as String,
              ),
            )
            .toList();
      }

      final page = MushafPage(page: pageNumber, items: pageItems);

      _pageCache[pageNumber] = page;

      if (_pageCache.length > _maxCacheSize) {
        final firstKey = _pageCache.keys.first;
        _pageCache.remove(firstKey);
      }

      return page;
    } catch (e) {
      throw Exception('Failed to load page $pageNumber: $e');
    }
  }

  /// Fallback: estimate which ayahs belong to a page based on position
  /// This is used when the database doesn't have page column populated
  Future<List<MushafPageItem>> _getEstimatedPageItems(int pageNumber) async {
    // 604 pages, ~6236 ayahs = ~10.3 ayahs per page on average
    // This is a rough estimation for when page data is missing
    const avgAyahsPerPage = 10;

    // Calculate start ayah offset for this page
    final startAyahIndex = (pageNumber - 1) * avgAyahsPerPage;

    try {
      final db = await _quranRepository.getDb();

      // Get ayahs by row offset
      final result = await db.query(
        'quran_ayahs',
        orderBy: 'surah ASC, ayah ASC',
        limit: avgAyahsPerPage,
        offset: startAyahIndex,
      );

      return result
          .map(
            (row) => MushafPageItem(
              surah: row['surah'] as int,
              ayah: row['ayah'] as int,
              text: row['text'] as String,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> prefetchPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages) return;
    if (_pageCache.containsKey(pageNumber)) return;
    try {
      await getPage(pageNumber);
    } catch (e) {
      // Silently fail for prefetch
    }
  }

  void clearCache() {
    _pageCache.clear();
  }
}
