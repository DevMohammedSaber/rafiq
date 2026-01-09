import 'package:adhan/adhan.dart';
import '../../profile/domain/models/user_settings.dart';

class PrayerTimesService {
  PrayerTimes getPrayerTimesForDate(UserSettings settings, DateTime date) {
    // Default to Cairo if lat/lng missing
    final Coordinates coordinates = Coordinates(
      settings.location.lat ?? 30.0444,
      settings.location.lng ?? 31.2357,
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

  PrayerTimes getTodayPrayerTimes(UserSettings settings) {
    return getPrayerTimesForDate(settings, DateTime.now());
  }

  Prayer? getNextPrayer(UserSettings settings) {
    final prayerTimes = getTodayPrayerTimes(settings);
    return prayerTimes.nextPrayer();
  }

  CalculationParameters _getCalculationParameters(String method) {
    switch (method) {
      case 'EGYPTIAN':
        return CalculationMethod.egyptian.getParameters();
      case 'MWL':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'KARACHI':
        return CalculationMethod.karachi.getParameters();
      case 'UMM_AL_QURA':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'DUBAI':
        return CalculationMethod.dubai.getParameters();
      case 'ISNA':
        return CalculationMethod.north_america.getParameters();
      default:
        return CalculationMethod.egyptian.getParameters();
    }
  }
}
