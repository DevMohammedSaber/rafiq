import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final String languageCode;
  final String themeMode;
  final UserLocation location;
  final PrayerSettings prayerSettings;
  final QuranSettings quranSettings;
  final bool setupDone;
  final bool hadithWithTashkeel;

  const UserSettings({
    this.languageCode = 'ar',
    this.themeMode = 'system',
    this.location = const UserLocation(),
    this.prayerSettings = const PrayerSettings(),
    this.quranSettings = const QuranSettings(),
    this.setupDone = false,
    this.hadithWithTashkeel = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      languageCode: json['languageCode'] as String? ?? 'ar',
      themeMode: json['themeMode'] as String? ?? 'system',
      location: UserLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      prayerSettings: PrayerSettings.fromJson(
        json['prayerSettings'] as Map<String, dynamic>? ?? {},
      ),
      quranSettings: QuranSettings.fromJson(
        json['quranSettings'] as Map<String, dynamic>? ?? {},
      ),
      setupDone: json['setupDone'] as bool? ?? false,
      hadithWithTashkeel: json['hadithWithTashkeel'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'themeMode': themeMode,
      'location': location.toJson(),
      'prayerSettings': prayerSettings.toJson(),
      'quranSettings': quranSettings.toJson(),
      'setupDone': setupDone,
      'hadithWithTashkeel': hadithWithTashkeel,
    };
  }

  UserSettings copyWith({
    String? languageCode,
    String? themeMode,
    UserLocation? location,
    PrayerSettings? prayerSettings,
    QuranSettings? quranSettings,
    bool? setupDone,
    bool? hadithWithTashkeel,
  }) {
    return UserSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      location: location ?? this.location,
      prayerSettings: prayerSettings ?? this.prayerSettings,
      quranSettings: quranSettings ?? this.quranSettings,
      setupDone: setupDone ?? this.setupDone,
      hadithWithTashkeel: hadithWithTashkeel ?? this.hadithWithTashkeel,
    );
  }

  @override
  List<Object?> get props => [
    languageCode,
    themeMode,
    location,
    prayerSettings,
    quranSettings,
    setupDone,
    hadithWithTashkeel,
  ];
}

class UserLocation extends Equatable {
  final bool useAutoLocation;
  final String countryCode;
  final String city;
  final double? lat;
  final double? lng;

  const UserLocation({
    this.useAutoLocation = false,
    this.countryCode = 'EG',
    this.city = 'Cairo',
    this.lat,
    this.lng,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      useAutoLocation: json['useAutoLocation'] as bool? ?? false,
      countryCode: json['countryCode'] as String? ?? 'EG',
      city: json['city'] as String? ?? 'Cairo',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useAutoLocation': useAutoLocation,
      'countryCode': countryCode,
      'city': city,
      'lat': lat,
      'lng': lng,
    };
  }

  UserLocation copyWith({
    bool? useAutoLocation,
    String? countryCode,
    String? city,
    double? lat,
    double? lng,
  }) {
    return UserLocation(
      useAutoLocation: useAutoLocation ?? this.useAutoLocation,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  List<Object?> get props => [useAutoLocation, countryCode, city, lat, lng];
}

/// Per-prayer notification settings
class PerPrayerSettings extends Equatable {
  final bool enabled;
  final bool adhanEnabled;
  final bool iqamaEnabled;
  final int iqamaAfterMin;

  const PerPrayerSettings({
    this.enabled = true,
    this.adhanEnabled = true,
    this.iqamaEnabled = true,
    this.iqamaAfterMin = 15,
  });

  factory PerPrayerSettings.fromJson(Map<String, dynamic> json) {
    return PerPrayerSettings(
      enabled: json['enabled'] as bool? ?? true,
      adhanEnabled: json['adhanEnabled'] as bool? ?? true,
      iqamaEnabled: json['iqamaEnabled'] as bool? ?? true,
      iqamaAfterMin: json['iqamaAfterMin'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'adhanEnabled': adhanEnabled,
      'iqamaEnabled': iqamaEnabled,
      'iqamaAfterMin': iqamaAfterMin,
    };
  }

  PerPrayerSettings copyWith({
    bool? enabled,
    bool? adhanEnabled,
    bool? iqamaEnabled,
    int? iqamaAfterMin,
  }) {
    return PerPrayerSettings(
      enabled: enabled ?? this.enabled,
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      iqamaEnabled: iqamaEnabled ?? this.iqamaEnabled,
      iqamaAfterMin: iqamaAfterMin ?? this.iqamaAfterMin,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    adhanEnabled,
    iqamaEnabled,
    iqamaAfterMin,
  ];
}

class PrayerSettings extends Equatable {
  final String calculationMethod; // EGYPTIAN, MWL, KARACHI, etc.
  final String asrMethod; // shafi, hanafi
  final bool remindersEnabled;
  final int beforeAdhanMinutes;
  final int beforeIqamaMinutes;
  final Map<String, PerPrayerSettings> perPrayerSettings;
  final DateTime? lastScheduledAt;

  // Legacy fields for backward compatibility
  final Map<String, bool> enabledPrayers;
  final Map<String, int> iqamaAfterMinutes;

  static const Map<String, PerPrayerSettings> defaultPerPrayerSettings = {
    'fajr': PerPrayerSettings(iqamaAfterMin: 20),
    'dhuhr': PerPrayerSettings(iqamaAfterMin: 15),
    'asr': PerPrayerSettings(iqamaAfterMin: 15),
    'maghrib': PerPrayerSettings(iqamaAfterMin: 10),
    'isha': PerPrayerSettings(iqamaAfterMin: 20),
  };

  const PrayerSettings({
    this.calculationMethod = 'EGYPTIAN',
    this.asrMethod = 'shafi',
    this.remindersEnabled = true,
    this.beforeAdhanMinutes = 10,
    this.beforeIqamaMinutes = 5,
    this.perPrayerSettings = defaultPerPrayerSettings,
    this.lastScheduledAt,
    // Legacy fields
    this.enabledPrayers = const {
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    },
    this.iqamaAfterMinutes = const {
      'fajr': 20,
      'dhuhr': 15,
      'asr': 15,
      'maghrib': 10,
      'isha': 20,
    },
  });

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    // Parse perPrayerSettings
    Map<String, PerPrayerSettings> perPrayer = {};
    final perPrayerJson = json['perPrayerSettings'] as Map<String, dynamic>?;
    if (perPrayerJson != null) {
      perPrayerJson.forEach((key, value) {
        perPrayer[key] = PerPrayerSettings.fromJson(
          value as Map<String, dynamic>,
        );
      });
    } else {
      // Default values
      perPrayer = Map.from(defaultPerPrayerSettings);
    }

    return PrayerSettings(
      calculationMethod: json['calculationMethod'] as String? ?? 'EGYPTIAN',
      asrMethod: json['asrMethod'] as String? ?? 'shafi',
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      beforeAdhanMinutes: json['beforeAdhanMinutes'] as int? ?? 10,
      beforeIqamaMinutes: json['beforeIqamaMinutes'] as int? ?? 5,
      perPrayerSettings: perPrayer,
      lastScheduledAt: json['lastScheduledAt'] != null
          ? DateTime.tryParse(json['lastScheduledAt'] as String)
          : null,
      // Legacy fields
      enabledPrayers:
          (json['enabledPrayers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {
            'fajr': true,
            'dhuhr': true,
            'asr': true,
            'maghrib': true,
            'isha': true,
          },
      iqamaAfterMinutes:
          (json['iqamaAfterMinutes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          const {'fajr': 20, 'dhuhr': 15, 'asr': 15, 'maghrib': 10, 'isha': 20},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calculationMethod': calculationMethod,
      'asrMethod': asrMethod,
      'remindersEnabled': remindersEnabled,
      'beforeAdhanMinutes': beforeAdhanMinutes,
      'beforeIqamaMinutes': beforeIqamaMinutes,
      'perPrayerSettings': perPrayerSettings.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'lastScheduledAt': lastScheduledAt?.toIso8601String(),
      // Legacy fields
      'enabledPrayers': enabledPrayers,
      'iqamaAfterMinutes': iqamaAfterMinutes,
    };
  }

  PrayerSettings copyWith({
    String? calculationMethod,
    String? asrMethod,
    bool? remindersEnabled,
    int? beforeAdhanMinutes,
    int? beforeIqamaMinutes,
    Map<String, PerPrayerSettings>? perPrayerSettings,
    DateTime? lastScheduledAt,
    Map<String, bool>? enabledPrayers,
    Map<String, int>? iqamaAfterMinutes,
  }) {
    return PrayerSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      beforeAdhanMinutes: beforeAdhanMinutes ?? this.beforeAdhanMinutes,
      beforeIqamaMinutes: beforeIqamaMinutes ?? this.beforeIqamaMinutes,
      perPrayerSettings: perPrayerSettings ?? this.perPrayerSettings,
      lastScheduledAt: lastScheduledAt ?? this.lastScheduledAt,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      iqamaAfterMinutes: iqamaAfterMinutes ?? this.iqamaAfterMinutes,
    );
  }

  /// Get PerPrayerSettings for a specific prayer, with fallback to defaults
  PerPrayerSettings getPerPrayer(String prayerKey) {
    return perPrayerSettings[prayerKey] ??
        defaultPerPrayerSettings[prayerKey] ??
        const PerPrayerSettings();
  }

  /// Update a specific prayer's settings
  PrayerSettings updatePerPrayer(String prayerKey, PerPrayerSettings settings) {
    final updated = Map<String, PerPrayerSettings>.from(perPrayerSettings);
    updated[prayerKey] = settings;
    return copyWith(perPrayerSettings: updated);
  }

  @override
  List<Object?> get props => [
    calculationMethod,
    asrMethod,
    remindersEnabled,
    beforeAdhanMinutes,
    beforeIqamaMinutes,
    perPrayerSettings,
    lastScheduledAt,
    enabledPrayers,
    iqamaAfterMinutes,
  ];
}

class QuranSettings extends Equatable {
  final double fontSize;
  final String fontFamily;
  final int? lastReadSurahId;
  final int? lastReadAyahNumber;
  final int? lastReadMushafPage;
  final String viewMode; // 'card', 'mushaf', or 'page'
  final Map<int, double> scrollPositions; // surahId -> scroll position

  const QuranSettings({
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.lastReadSurahId,
    this.lastReadAyahNumber,
    this.lastReadMushafPage,
    this.viewMode = 'card',
    this.scrollPositions = const {},
  });

  factory QuranSettings.fromJson(Map<String, dynamic> json) {
    final scrollPositionsJson =
        json['scrollPositions'] as Map<String, dynamic>?;
    final scrollPositions =
        scrollPositionsJson?.map(
          (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
        ) ??
        <int, double>{};

    return QuranSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontFamily: json['fontFamily'] as String? ?? 'Amiri',
      lastReadSurahId: json['lastReadSurahId'] as int?,
      lastReadAyahNumber: json['lastReadAyahNumber'] as int?,
      lastReadMushafPage: json['lastReadMushafPage'] as int?,
      viewMode: json['viewMode'] as String? ?? 'card',
      scrollPositions: scrollPositions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lastReadSurahId': lastReadSurahId,
      'lastReadAyahNumber': lastReadAyahNumber,
      'lastReadMushafPage': lastReadMushafPage,
      'viewMode': viewMode,
      'scrollPositions': scrollPositions.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  QuranSettings copyWith({
    double? fontSize,
    String? fontFamily,
    int? lastReadSurahId,
    int? lastReadAyahNumber,
    int? lastReadMushafPage,
    String? viewMode,
    Map<int, double>? scrollPositions,
  }) {
    return QuranSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lastReadSurahId: lastReadSurahId ?? this.lastReadSurahId,
      lastReadAyahNumber: lastReadAyahNumber ?? this.lastReadAyahNumber,
      lastReadMushafPage: lastReadMushafPage ?? this.lastReadMushafPage,
      viewMode: viewMode ?? this.viewMode,
      scrollPositions: scrollPositions ?? this.scrollPositions,
    );
  }

  @override
  List<Object?> get props => [
    fontSize,
    fontFamily,
    lastReadSurahId,
    lastReadAyahNumber,
    lastReadMushafPage,
    viewMode,
    scrollPositions,
  ];
}
