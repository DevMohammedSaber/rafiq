import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/tasbeeh_preset.dart';
import '../domain/models/tasbeeh_stats.dart';

/// Local repository for Tasbeeh data using SharedPreferences
class TasbeehLocalRepository {
  static const String _presetsKey = 'tasbeeh_presets';
  static const String _sessionKey = 'tasbeeh_session';
  static const String _statsKey = 'tasbeeh_stats';
  static const String _settingsKey = 'tasbeeh_settings';

  /// Load presets from local storage
  Future<List<TasbeehPreset>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(_presetsKey);

    if (presetsJson == null || presetsJson.isEmpty) {
      // Return default presets
      return TasbeehPreset.defaults;
    }

    try {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      final presets = decoded
          .map((e) => TasbeehPreset.fromJson(e as Map<String, dynamic>))
          .toList();

      // Ensure default presets exist
      final existingIds = presets.map((p) => p.id).toSet();
      for (final defaultPreset in TasbeehPreset.defaults) {
        if (!existingIds.contains(defaultPreset.id)) {
          presets.insert(0, defaultPreset);
        }
      }

      return presets;
    } catch (e) {
      return TasbeehPreset.defaults;
    }
  }

  /// Save presets to local storage
  Future<void> savePresets(List<TasbeehPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(presets.map((p) => p.toJson()).toList());
    await prefs.setString(_presetsKey, encoded);
  }

  /// Load current session state
  Future<TasbeehSession> loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);

    if (sessionJson == null || sessionJson.isEmpty) {
      return TasbeehSession(
        selectedPresetId: TasbeehPreset.defaults.first.id,
        currentCount: 0,
      );
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(sessionJson);
      return TasbeehSession.fromJson(decoded);
    } catch (e) {
      return TasbeehSession(
        selectedPresetId: TasbeehPreset.defaults.first.id,
        currentCount: 0,
      );
    }
  }

  /// Save current session state
  Future<void> saveSessionState(TasbeehSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(session.toJson());
    await prefs.setString(_sessionKey, encoded);
  }

  /// Load stats from local storage
  Future<TasbeehStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);

    if (statsJson == null || statsJson.isEmpty) {
      return const TasbeehStats();
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(statsJson);
      return TasbeehStats.fromJson(decoded);
    } catch (e) {
      return const TasbeehStats();
    }
  }

  /// Save stats to local storage
  Future<void> saveStats(TasbeehStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stats.toJson());
    await prefs.setString(_statsKey, encoded);
  }

  /// Load settings
  Future<TasbeehSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson == null || settingsJson.isEmpty) {
      return const TasbeehSettings();
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(settingsJson);
      return TasbeehSettings.fromJson(decoded);
    } catch (e) {
      return const TasbeehSettings();
    }
  }

  /// Save settings
  Future<void> saveSettings(TasbeehSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, encoded);
  }
}

/// Session state for current tasbeeh session
class TasbeehSession {
  final String selectedPresetId;
  final int currentCount;

  const TasbeehSession({
    required this.selectedPresetId,
    required this.currentCount,
  });

  factory TasbeehSession.fromJson(Map<String, dynamic> json) {
    return TasbeehSession(
      selectedPresetId:
          json['selectedPresetId'] as String? ??
          TasbeehPreset.defaults.first.id,
      currentCount: json['currentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'selectedPresetId': selectedPresetId, 'currentCount': currentCount};
  }

  TasbeehSession copyWith({String? selectedPresetId, int? currentCount}) {
    return TasbeehSession(
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      currentCount: currentCount ?? this.currentCount,
    );
  }
}

/// Settings for tasbeeh preferences
class TasbeehSettings {
  final bool hapticEnabled;
  final bool soundEnabled;

  const TasbeehSettings({this.hapticEnabled = true, this.soundEnabled = false});

  factory TasbeehSettings.fromJson(Map<String, dynamic> json) {
    return TasbeehSettings(
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'hapticEnabled': hapticEnabled, 'soundEnabled': soundEnabled};
  }

  TasbeehSettings copyWith({bool? hapticEnabled, bool? soundEnabled}) {
    return TasbeehSettings(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
