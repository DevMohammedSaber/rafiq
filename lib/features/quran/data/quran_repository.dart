import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/models/surah.dart';
import '../domain/models/ayah.dart';

class QuranRepository {
  List<Surah>? _cachedSurahs;
  final Map<int, List<Ayah>> _cachedAyahs = {};

  // Load all surahs from surah.json
  Future<List<Surah>> loadSurahs() async {
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/source/surah.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedSurahs = jsonList
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedSurahs!;
    } catch (e) {
      throw Exception('Failed to load surahs: $e');
    }
  }

  // Load ayahs for a specific surah
  Future<List<Ayah>> loadAyahs(int surahId) async {
    if (_cachedAyahs.containsKey(surahId)) {
      return _cachedAyahs[surahId]!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/source/surah/surah_$surahId.json',
      );
      final Map<String, dynamic> surahData = json.decode(jsonString);
      final Map<String, dynamic>? verseMap =
          surahData['verse'] as Map<String, dynamic>?;

      if (verseMap == null) {
        return [];
      }

      final List<Ayah> ayahs = [];
      verseMap.forEach((key, value) {
        // key format: "verse_1", "verse_2", etc.
        final ayahNumber = int.tryParse(key.replaceFirst('verse_', '')) ?? 0;
        if (ayahNumber > 0) {
          ayahs.add(Ayah.fromJson(surahId, ayahNumber, value as String));
        }
      });

      // Sort by ayah number
      ayahs.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
      _cachedAyahs[surahId] = ayahs;
      return ayahs;
    } catch (e) {
      throw Exception('Failed to load ayahs for surah $surahId: $e');
    }
  }

  // Get a single surah by ID
  Future<Surah?> getSurahById(int surahId) async {
    final surahs = await loadSurahs();
    try {
      return surahs.firstWhere((s) => s.id == surahId);
    } catch (e) {
      return null;
    }
  }

  // Search surahs by name (Arabic or English)
  Future<List<Surah>> searchSurahs(String query) async {
    final surahs = await loadSurahs();
    if (query.isEmpty) {
      return surahs;
    }

    final lowerQuery = query.toLowerCase();
    return surahs.where((s) {
      return s.nameEn.toLowerCase().contains(lowerQuery) ||
          s.nameAr.contains(query);
    }).toList();
  }

  // Clear cache if needed
  void clearCache() {
    _cachedSurahs = null;
    _cachedAyahs.clear();
  }
}
