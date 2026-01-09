import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final String languageCode;
  final String themeMode;
  final UserLocation location;
  final PrayerSettings prayerSettings;
  final QuranSettings quranSettings;
  final bool setupDone;

  const UserSettings({
    this.languageCode = 'ar',
    this.themeMode = 'system',
    this.location = const UserLocation(),
    this.prayerSettings = const PrayerSettings(),
    this.quranSettings = const QuranSettings(),
    this.setupDone = false,
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
    };
  }

  UserSettings copyWith({
    String? languageCode,
    String? themeMode,
    UserLocation? location,
    PrayerSettings? prayerSettings,
    QuranSettings? quranSettings,
    bool? setupDone,
  }) {
    return UserSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      location: location ?? this.location,
      prayerSettings: prayerSettings ?? this.prayerSettings,
      quranSettings: quranSettings ?? this.quranSettings,
      setupDone: setupDone ?? this.setupDone,
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

class PrayerSettings extends Equatable {
  final String calculationMethod; // EGYPTIAN, etc.
  final String asrMethod; // shafi, hanafi
  final int beforeAdhanMinutes;
  final Map<String, bool> enabledPrayers;
  final Map<String, int> iqamaAfterMinutes;
  final int beforeIqamaMinutes;

  const PrayerSettings({
    this.calculationMethod = 'EGYPTIAN',
    this.asrMethod = 'shafi',
    this.beforeAdhanMinutes = 10,
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
    this.beforeIqamaMinutes = 5,
  });

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    return PrayerSettings(
      calculationMethod: json['calculationMethod'] as String? ?? 'EGYPTIAN',
      asrMethod: json['asrMethod'] as String? ?? 'shafi',
      beforeAdhanMinutes: json['beforeAdhanMinutes'] as int? ?? 10,
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
      beforeIqamaMinutes: json['beforeIqamaMinutes'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calculationMethod': calculationMethod,
      'asrMethod': asrMethod,
      'beforeAdhanMinutes': beforeAdhanMinutes,
      'enabledPrayers': enabledPrayers,
      'iqamaAfterMinutes': iqamaAfterMinutes,
      'beforeIqamaMinutes': beforeIqamaMinutes,
    };
  }

  PrayerSettings copyWith({
    String? calculationMethod,
    String? asrMethod,
    int? beforeAdhanMinutes,
    Map<String, bool>? enabledPrayers,
    Map<String, int>? iqamaAfterMinutes,
    int? beforeIqamaMinutes,
  }) {
    return PrayerSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      beforeAdhanMinutes: beforeAdhanMinutes ?? this.beforeAdhanMinutes,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      iqamaAfterMinutes: iqamaAfterMinutes ?? this.iqamaAfterMinutes,
      beforeIqamaMinutes: beforeIqamaMinutes ?? this.beforeIqamaMinutes,
    );
  }

  @override
  List<Object?> get props => [
    calculationMethod,
    asrMethod,
    beforeAdhanMinutes,
    enabledPrayers,
    iqamaAfterMinutes,
    beforeIqamaMinutes,
  ];
}

class QuranSettings extends Equatable {
  final double fontSize;
  final String fontFamily;
  final int? lastReadSurahId;
  final int? lastReadAyahNumber;
  final String viewMode; // 'card' or 'mushaf'

  const QuranSettings({
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.lastReadSurahId,
    this.lastReadAyahNumber,
    this.viewMode = 'card',
  });

  factory QuranSettings.fromJson(Map<String, dynamic> json) {
    return QuranSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontFamily: json['fontFamily'] as String? ?? 'Amiri',
      lastReadSurahId: json['lastReadSurahId'] as int?,
      lastReadAyahNumber: json['lastReadAyahNumber'] as int?,
      viewMode: json['viewMode'] as String? ?? 'card',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lastReadSurahId': lastReadSurahId,
      'lastReadAyahNumber': lastReadAyahNumber,
      'viewMode': viewMode,
    };
  }

  QuranSettings copyWith({
    double? fontSize,
    String? fontFamily,
    int? lastReadSurahId,
    int? lastReadAyahNumber,
    String? viewMode,
  }) {
    return QuranSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lastReadSurahId: lastReadSurahId ?? this.lastReadSurahId,
      lastReadAyahNumber: lastReadAyahNumber ?? this.lastReadAyahNumber,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [
    fontSize,
    fontFamily,
    lastReadSurahId,
    lastReadAyahNumber,
    viewMode,
  ];
}
