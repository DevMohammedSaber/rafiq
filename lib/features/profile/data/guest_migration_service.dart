import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for migrating guest data to authenticated user account
class GuestMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences keys for guest data
  static const String _userSettingsKey = 'user_settings';
  static const String _tasbeehPresetsKey = 'tasbeeh_presets';
  static const String _tasbeehStatsKey = 'tasbeeh_stats';
  static const String _azkarFavoritesKey = 'azkar_favorites';
  static const String _hadithFavoritesKey = 'hadith_favorites';
  static const String _quranBookmarksKey = 'quran_bookmarks';
  static const String _guestNameKey = 'guest_name';
  static const String _guestProfileKey = 'guest_profile';

  /// Migrate all guest data to the authenticated user's Firestore account
  Future<MigrationResult> migrateGuestDataToUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final userDoc = _firestore.collection('users').doc(uid);

    final List<String> migratedKeys = [];
    final List<String> failedKeys = [];

    // Migrate user settings
    try {
      final settingsJson = prefs.getString(_userSettingsKey);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final settings = jsonDecode(settingsJson);
        await userDoc.set({'settings': settings}, SetOptions(merge: true));
        migratedKeys.add('settings');
      }
    } catch (e) {
      failedKeys.add('settings');
    }

    // Migrate tasbeeh presets
    try {
      final presetsJson = prefs.getString(_tasbeehPresetsKey);
      if (presetsJson != null && presetsJson.isNotEmpty) {
        final presets = jsonDecode(presetsJson) as List<dynamic>;
        // Only migrate custom presets (non-default)
        final customPresets = presets
            .where((p) => p['isDefault'] != true)
            .toList();
        if (customPresets.isNotEmpty) {
          await userDoc.set({
            'tasbeeh': {'presets': customPresets},
          }, SetOptions(merge: true));
          migratedKeys.add('tasbeeh_presets');
        }
      }
    } catch (e) {
      failedKeys.add('tasbeeh_presets');
    }

    // Migrate tasbeeh stats
    try {
      final statsJson = prefs.getString(_tasbeehStatsKey);
      if (statsJson != null && statsJson.isNotEmpty) {
        final stats = jsonDecode(statsJson);
        await userDoc.set({
          'tasbeeh': {'stats': stats},
        }, SetOptions(merge: true));
        migratedKeys.add('tasbeeh_stats');
      }
    } catch (e) {
      failedKeys.add('tasbeeh_stats');
    }

    // Migrate azkar favorites
    try {
      final favoritesJson = prefs.getString(_azkarFavoritesKey);
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final favorites = jsonDecode(favoritesJson);
        await userDoc.set({
          'azkar': {'favorites': favorites},
        }, SetOptions(merge: true));
        migratedKeys.add('azkar_favorites');
      }
    } catch (e) {
      failedKeys.add('azkar_favorites');
    }

    // Migrate hadith favorites
    try {
      final favoritesJson = prefs.getString(_hadithFavoritesKey);
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final favorites = jsonDecode(favoritesJson);
        await userDoc.set({
          'hadith': {'favorites': favorites},
        }, SetOptions(merge: true));
        migratedKeys.add('hadith_favorites');
      }
    } catch (e) {
      failedKeys.add('hadith_favorites');
    }

    // Migrate quran bookmarks
    try {
      final bookmarksJson = prefs.getString(_quranBookmarksKey);
      if (bookmarksJson != null && bookmarksJson.isNotEmpty) {
        final bookmarks = jsonDecode(bookmarksJson);
        await userDoc.set({
          'quran': {'bookmarks': bookmarks},
        }, SetOptions(merge: true));
        migratedKeys.add('quran_bookmarks');
      }
    } catch (e) {
      failedKeys.add('quran_bookmarks');
    }

    return MigrationResult(
      migratedKeys: migratedKeys,
      failedKeys: failedKeys,
      success: failedKeys.isEmpty,
    );
  }

  /// Clear guest-specific data after migration
  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestNameKey);
    await prefs.remove(_guestProfileKey);
    // Note: We don't clear other data as it may be needed as fallback
  }

  /// Check if there is guest data to migrate
  Future<bool> hasGuestDataToMigrate() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(_userSettingsKey) ||
        prefs.containsKey(_tasbeehPresetsKey) ||
        prefs.containsKey(_azkarFavoritesKey) ||
        prefs.containsKey(_hadithFavoritesKey) ||
        prefs.containsKey(_quranBookmarksKey);
  }
}

/// Result of data migration
class MigrationResult {
  final List<String> migratedKeys;
  final List<String> failedKeys;
  final bool success;

  const MigrationResult({
    required this.migratedKeys,
    required this.failedKeys,
    required this.success,
  });

  bool get hasMigratedData => migratedKeys.isNotEmpty;

  @override
  String toString() {
    return 'MigrationResult(migrated: $migratedKeys, failed: $failedKeys, success: $success)';
  }
}
