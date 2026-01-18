import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility class for Quran navigation helpers.
class QuranNavigation {
  /// Open an ayah in the appropriate reader based on current view mode.
  ///
  /// [context] - Build context for navigation
  /// [surahId] - Surah number (1-114)
  /// [ayahNumber] - Ayah number within the surah
  /// [viewMode] - Current reader view mode ('card', 'mushaf', 'page')
  /// [highlightKey] - Optional ayah key to highlight (format: 'surahId:ayahNumber')
  /// [page] - Optional page number for page mode
  static void openAyah(
    BuildContext context, {
    required int surahId,
    required int ayahNumber,
    String viewMode = 'card',
    String? highlightKey,
    int? page,
  }) {
    final params = <String, String>{'ayah': ayahNumber.toString()};

    if (highlightKey != null) {
      params['highlight'] = highlightKey;
    }

    if (viewMode == 'page' && page != null) {
      // For page mode, we can pass the page number
      params['page'] = page.toString();
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    context.push('/quran/$surahId?$queryString');
  }

  /// Open mushaf at a specific page
  static void openMushafPage(
    BuildContext context, {
    required int page,
    String? highlightAyahKey,
  }) {
    final params = <String, String>{'page': page.toString(), 'mode': 'mushaf'};

    if (highlightAyahKey != null) {
      params['highlight'] = highlightAyahKey;
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    context.push('/quran/1?$queryString');
  }

  /// Navigate to search page
  static void openSearch(BuildContext context) {
    context.push('/quran/search');
  }

  /// Navigate to tafsir page for a specific ayah
  static void openTafsir(
    BuildContext context, {
    required int surahId,
    required int ayahNumber,
  }) {
    context.push('/quran/tafsir/$surahId/$ayahNumber');
  }

  /// Navigate to audio settings
  static void openAudioSettings(BuildContext context) {
    context.push('/quran/audio-settings');
  }

  /// Parse highlight parameter from route
  static (int?, int?) parseHighlightKey(String? highlightKey) {
    if (highlightKey == null || !highlightKey.contains(':')) {
      return (null, null);
    }

    final parts = highlightKey.split(':');
    if (parts.length != 2) {
      return (null, null);
    }

    final surahId = int.tryParse(parts[0]);
    final ayahNumber = int.tryParse(parts[1]);

    return (surahId, ayahNumber);
  }

  /// Build ayah key from surah and ayah
  static String buildAyahKey(int surahId, int ayahNumber) {
    return '$surahId:$ayahNumber';
  }
}
