import 'dart:collection';
import '../domain/models/mushaf_page.dart';
import '../domain/models/surah_meta.dart';
import '../domain/models/surah.dart';
import 'quran_repository.dart';
import 'quran_pagination_repository.dart';

class MushafDataRepository {
  static const int _maxCacheSize = 10;
  static const int _totalPages = 604;

  final QuranRepository _quranRepository;
  final QuranPaginationRepository _paginationRepository;
  
  List<Surah>? _cachedSurahs;
  final LinkedHashMap<int, MushafPage> _pageCache = LinkedHashMap();
  final Map<int, Map<int, int>> _ayahPageMap = {};

  MushafDataRepository({
    QuranRepository? quranRepository,
    QuranPaginationRepository? paginationRepository,
  }) : _quranRepository = quranRepository ?? QuranRepository(),
       _paginationRepository = paginationRepository ?? QuranPaginationRepository();

  Future<void> loadIndex() async {
    if (_cachedSurahs != null && _ayahPageMap.isNotEmpty) return;
    
    _cachedSurahs = await _quranRepository.loadSurahs();
    
    for (final surah in _cachedSurahs!) {
      final ayahs = await _quranRepository.loadAyahs(surah.id);
      _ayahPageMap[surah.id] = {};
      for (final ayah in ayahs) {
        final page = await _paginationRepository.getPageForAyah(
          surah.id,
          ayah.ayahNumber,
        );
        _ayahPageMap[surah.id]![ayah.ayahNumber] = page;
      }
    }
  }

  int get totalPages => _totalPages;

  Future<List<SurahMeta>> getSurahs() async {
    await loadIndex();
    return _cachedSurahs!.map((surah) {
      final firstPage = _ayahPageMap[surah.id]?[1];
      return SurahMeta(
        id: surah.id,
        nameAr: surah.nameAr,
        nameEn: surah.nameEn,
        firstPage: firstPage,
      );
    }).toList();
  }

  Future<SurahMeta?> getSurahMeta(int id) async {
    await loadIndex();
    try {
      final surah = _cachedSurahs!.firstWhere((s) => s.id == id);
      final firstPage = _ayahPageMap[id]?[1];
      return SurahMeta(
        id: surah.id,
        nameAr: surah.nameAr,
        nameEn: surah.nameEn,
        firstPage: firstPage,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int?> getPageForAyah(int surahId, int ayahNumber) async {
    await loadIndex();
    return _ayahPageMap[surahId]?[ayahNumber];
  }

  Future<int?> getFirstPageForSurah(int surahId) async {
    await loadIndex();
    return _ayahPageMap[surahId]?[1];
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
      await loadIndex();
      
      final pageItems = <MushafPageItem>[];
      
      for (final surah in _cachedSurahs!) {
        final ayahs = await _quranRepository.loadAyahs(surah.id);
        for (final ayah in ayahs) {
          final ayahPage = _ayahPageMap[surah.id]?[ayah.ayahNumber];
          if (ayahPage == pageNumber) {
            pageItems.add(
              MushafPageItem(
                surah: surah.id,
                ayah: ayah.ayahNumber,
                text: ayah.textAr,
              ),
            );
          }
        }
      }

      final page = MushafPage(
        page: pageNumber,
        items: pageItems,
      );

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
    _ayahPageMap.clear();
  }
}
