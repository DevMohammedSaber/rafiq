import 'quran_page_map.dart';

class QuranPaginationRepository {
  /// Returns the page number for a specific Ayah using the static map.
  Future<int> getPageForAyah(int surahId, int ayahNumber) async {
    return quranPageMap[surahId]?[ayahNumber] ?? 1;
  }

  /// Get all unique page numbers associated with a Surah.
  Future<List<int>> getPagesForSurah(int surahId) async {
    final surahMap = quranPageMap[surahId];
    if (surahMap == null) return [1];

    final Set<int> pages = Set<int>.from(surahMap.values);
    final sorted = pages.toList()..sort();
    return sorted;
  }
}
