import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../profile/domain/models/user_settings.dart';

/// Service for calculating prayer times using the adhan package
class PrayerTimesService {
  static bool _timezoneInitialized = false;

  /// Initialize timezone data (call once at app startup)
  static Future<void> initializeTimezone() async {
    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  /// Default Cairo coordinates
  static const double defaultLat = 30.0444;
  static const double defaultLng = 31.2357;

  /// Get prayer times for a specific date
  PrayerTimes getPrayerTimesForDate(UserSettings settings, DateTime date) {
    final Coordinates coordinates = Coordinates(
      settings.location.lat ?? defaultLat,
      settings.location.lng ?? defaultLng,
    );

    final params = _getCalculationParameters(
      settings.prayerSettings.calculationMethod,
    );
    params.madhab = settings.prayerSettings.asrMethod == 'hanafi'
        ? Madhab.hanafi
        : Madhab.shafi;

    final dateComponents = DateComponents.from(date);
    return PrayerTimes(coordinates, dateComponents, params);
  }

  /// Get today's prayer times
  PrayerTimes getTodayPrayerTimes(UserSettings settings) {
    return getPrayerTimesForDate(settings, DateTime.now());
  }

  /// Get the next prayer from adhan package
  Prayer? getNextPrayer(UserSettings settings) {
    final prayerTimes = getTodayPrayerTimes(settings);
    return prayerTimes.nextPrayer();
  }

  /// Get the current prayer (if any)
  Prayer? getCurrentPrayer(UserSettings settings) {
    final prayerTimes = getTodayPrayerTimes(settings);
    return prayerTimes.currentPrayer();
  }

  /// Get the next prayer time as DateTime
  DateTime? getNextPrayerTime(UserSettings settings) {
    final prayerTimes = getTodayPrayerTimes(settings);
    final nextPrayer = prayerTimes.nextPrayer();
    if (nextPrayer == Prayer.none) return null;
    return prayerTimes.timeForPrayer(nextPrayer);
  }

  /// Get time remaining until next prayer
  Duration? getTimeUntilNextPrayer(UserSettings settings) {
    final nextTime = getNextPrayerTime(settings);
    if (nextTime == null) return null;
    return nextTime.difference(DateTime.now());
  }

  /// Get all prayer times as a map for display
  Map<String, DateTime> getAllPrayerTimesMap(
    UserSettings settings,
    DateTime date,
  ) {
    final prayerTimes = getPrayerTimesForDate(settings, date);
    return {
      'fajr': prayerTimes.fajr,
      'sunrise': prayerTimes.sunrise,
      'dhuhr': prayerTimes.dhuhr,
      'asr': prayerTimes.asr,
      'maghrib': prayerTimes.maghrib,
      'isha': prayerTimes.isha,
    };
  }

  /// Get prayer name from Prayer enum
  String getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.sunrise:
        return 'sunrise';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
      case Prayer.none:
        return 'none';
    }
  }

  /// Get Prayer enum from name
  Prayer? getPrayerFromName(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Prayer.fajr;
      case 'sunrise':
        return Prayer.sunrise;
      case 'dhuhr':
        return Prayer.dhuhr;
      case 'asr':
        return Prayer.asr;
      case 'maghrib':
        return Prayer.maghrib;
      case 'isha':
        return Prayer.isha;
      default:
        return null;
    }
  }

  /// Convert to timezone-aware DateTime
  tz.TZDateTime toTZDateTime(DateTime dateTime, {String? timezone}) {
    final location = tz.getLocation(timezone ?? 'Africa/Cairo');
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Get calculation parameters based on method string
  CalculationParameters _getCalculationParameters(String method) {
    switch (method.toUpperCase()) {
      case 'EGYPTIAN':
        return CalculationMethod.egyptian.getParameters();
      case 'MWL':
      case 'MUSLIM_WORLD_LEAGUE':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'KARACHI':
        return CalculationMethod.karachi.getParameters();
      case 'UMM_AL_QURA':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'DUBAI':
        return CalculationMethod.dubai.getParameters();
      case 'ISNA':
      case 'NORTH_AMERICA':
        return CalculationMethod.north_america.getParameters();
      case 'KUWAIT':
        return CalculationMethod.kuwait.getParameters();
      case 'QATAR':
        return CalculationMethod.qatar.getParameters();
      case 'SINGAPORE':
        return CalculationMethod.singapore.getParameters();
      case 'TEHRAN':
        return CalculationMethod.tehran.getParameters();
      case 'TURKEY':
        return CalculationMethod.turkey.getParameters();
      default:
        return CalculationMethod.egyptian.getParameters();
    }
  }

  /// Get list of available calculation methods
  static List<Map<String, String>> getAvailableCalculationMethods() {
    return [
      {'key': 'EGYPTIAN', 'name': 'Egyptian General Authority of Survey'},
      {'key': 'MWL', 'name': 'Muslim World League'},
      {'key': 'ISNA', 'name': 'Islamic Society of North America'},
      {'key': 'KARACHI', 'name': 'University of Islamic Sciences, Karachi'},
      {'key': 'UMM_AL_QURA', 'name': 'Umm Al-Qura University, Makkah'},
      {'key': 'DUBAI', 'name': 'Dubai'},
      {'key': 'KUWAIT', 'name': 'Kuwait'},
      {'key': 'QATAR', 'name': 'Qatar'},
      {'key': 'SINGAPORE', 'name': 'Singapore'},
      {'key': 'TEHRAN', 'name': 'Institute of Geophysics, Tehran'},
      {'key': 'TURKEY', 'name': 'Turkey'},
    ];
  }

  /// Get list of available Asr calculation methods
  static List<Map<String, String>> getAvailableAsrMethods() {
    return [
      {'key': 'shafi', 'name': 'Standard (Shafi, Maliki, Hanbali)'},
      {'key': 'hanafi', 'name': 'Hanafi'},
    ];
  }
}
