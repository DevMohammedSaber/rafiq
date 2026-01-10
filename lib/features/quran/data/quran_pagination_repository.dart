import 'dart:convert';
import 'package:flutter/services.dart';

class QuranPaginationRepository {
  Map<String, dynamic>? _pageMap;
  static const String _assetPath = 'assets/source/quran/page_map.json';

  Future<void> _ensureLoaded() async {
    if (_pageMap != null) return;
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _pageMap = json.decode(jsonString);
    } catch (e) {
      // Fallback or empty map if file missing/error
      _pageMap = {};
      print('Error loading Quran page map: $e');
    }
  }

  /// Returns the page number for a specific Ayah.
  /// Returns null if not found (or should we default to something?).
  /// For MVP, if not found, we might calculate a default or return 1.
  Future<int> getPageForAyah(int surahId, int ayahNumber) async {
    await _ensureLoaded();

    final surahKey = surahId.toString();
    final ayahKey = ayahNumber.toString();

    if (_pageMap != null && _pageMap!.containsKey(surahKey)) {
      final surahMap = _pageMap![surahKey];
      if (surahMap is Map && surahMap.containsKey(ayahKey)) {
        return surahMap[ayahKey] as int;
      }
    }

    // Fallback logic for unmapped Surahs (MVP):
    // Just return 1 + (surahId * some offset) or simply 1?
    // User said "Provide placeholder mapping for Al-Fatiha in assets for MVP"
    // and "Other surahs will default to a fallback".
    // Let's fallback to page 1 for now to likely show *something*.
    // Or better, return -1 to indicate "Standard View" required?
    // No, "Page Mode" is active. Let's return 1.
    return 1;
  }

  /// Get all unique page numbers associated with a Surah.
  /// Useful for knowing how many pages a Surah spans.
  Future<List<int>> getPagesForSurah(int surahId) async {
    await _ensureLoaded();
    final surahKey = surahId.toString();

    final Set<int> pages = {};

    if (_pageMap != null && _pageMap!.containsKey(surahKey)) {
      final surahMap = _pageMap![surahKey];
      if (surahMap is Map) {
        for (final val in surahMap.values) {
          if (val is int) pages.add(val);
        }
      }
    }

    if (pages.isEmpty) {
      pages.add(1); // Fallback
    }

    final sorted = pages.toList()..sort();
    return sorted;
  }
}
