import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../profile/domain/models/user_settings.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';
import '../../data/prayer_times_service.dart';
import '../../data/prayer_notification_service.dart';
import 'prayer_state.dart';

class PrayerCubit extends Cubit<PrayerState> {
  final PrayerTimesService _prayerTimesService;
  final PrayerNotificationService _notificationService;
  final SettingsCubit _settingsCubit;

  Timer? _countdownTimer;
  StreamSubscription? _settingsSubscription;

  PrayerCubit({
    required PrayerTimesService prayerTimesService,
    required PrayerNotificationService notificationService,
    required SettingsCubit settingsCubit,
  }) : _prayerTimesService = prayerTimesService,
       _notificationService = notificationService,
       _settingsCubit = settingsCubit,
       super(PrayerInitial()) {
    // Listen to settings changes
    _settingsSubscription = _settingsCubit.stream.listen((settingsState) {
      if (settingsState is SettingsLoaded) {
        _refreshWithSettings(settingsState.settings);
      }
    });
  }

  /// Load prayer times and notification status
  Future<void> load() async {
    emit(PrayerLoading());

    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is! SettingsLoaded) {
        emit(const PrayerError('Settings not loaded'));
        return;
      }

      final settings = settingsState.settings;
      await _loadPrayerData(settings, DateTime.now());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Refresh data when settings change
  Future<void> _refreshWithSettings(UserSettings settings) async {
    if (state is PrayerLoaded) {
      final currentState = state as PrayerLoaded;
      await _loadPrayerData(settings, currentState.selectedDate);
    }
  }

  /// Load prayer data for a specific date
  Future<void> _loadPrayerData(UserSettings settings, DateTime date) async {
    try {
      final todayTimes = _prayerTimesService.getAllPrayerTimesMap(
        settings,
        date,
      );
      final nextPrayer = _prayerTimesService.getNextPrayer(settings);
      final countdown = _prayerTimesService.getTimeUntilNextPrayer(settings);
      final notificationAllowed = await _notificationService
          .isNotificationAllowed();
      final scheduledCount = await _notificationService
          .getScheduledNotificationCount();

      // Build prayer list for display
      final prayerList = _buildPrayerList(todayTimes, nextPrayer);

      emit(
        PrayerLoaded(
          todayTimes: todayTimes,
          nextPrayer: nextPrayer,
          countdown: countdown,
          settings: settings,
          notificationAllowed: notificationAllowed,
          scheduledNotificationsCount: scheduledCount,
          selectedDate: date,
          prayerList: prayerList,
        ),
      );

      // Start countdown timer
      _startCountdownTimer(settings);
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Build prayer list for display
  List<PrayerTimeDisplay> _buildPrayerList(
    Map<String, DateTime> times,
    Prayer? nextPrayer,
  ) {
    final now = DateTime.now();
    final prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final displayNames = {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };

    return prayers.map((key) {
      final time = times[key]!;
      final prayerEnum = _prayerTimesService.getPrayerFromName(key);
      return PrayerTimeDisplay(
        name: displayNames[key] ?? key,
        key: key,
        time: time,
        isNext: prayerEnum == nextPrayer,
        isPassed: time.isBefore(now),
      );
    }).toList();
  }

  /// Start countdown timer
  void _startCountdownTimer(UserSettings settings) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is PrayerLoaded) {
        final countdown = _prayerTimesService.getTimeUntilNextPrayer(settings);
        final currentState = state as PrayerLoaded;

        if (countdown != null && countdown.isNegative) {
          // Next prayer has passed, reload
          load();
        } else {
          emit(currentState.copyWith(countdown: countdown));
        }
      }
    });
  }

  /// Request notification permission
  Future<void> requestNotificationPermission() async {
    final allowed = await _notificationService.requestPermissions();
    if (state is PrayerLoaded) {
      final currentState = state as PrayerLoaded;
      emit(currentState.copyWith(notificationAllowed: allowed));

      // Schedule notifications if permission granted
      if (allowed) {
        await rescheduleNotifications();
      }
    }
  }

  /// Update location using GPS
  Future<void> updateLocationGps() async {
    try {
      emit(PrayerLoading());

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const PrayerError('Location permission denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const PrayerError('Location permission permanently denied'));
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get city name from coordinates
      String city = 'Unknown';
      String countryCode = 'EG';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          city =
              placemarks.first.locality ??
              placemarks.first.administrativeArea ??
              'Unknown';
          countryCode = placemarks.first.isoCountryCode ?? 'EG';
        }
      } catch (_) {
        // Geocoding failed, use coordinates
      }

      // Update settings
      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        final newLocation = settingsState.settings.location.copyWith(
          useAutoLocation: true,
          lat: position.latitude,
          lng: position.longitude,
          city: city,
          countryCode: countryCode,
        );

        final newSettings = settingsState.settings.copyWith(
          location: newLocation,
        );
        await _settingsCubit.saveSettings(newSettings);
        await _loadPrayerData(newSettings, DateTime.now());
      }
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Update location manually
  Future<void> updateLocationManual({
    required String countryCode,
    required String city,
    required double lat,
    required double lng,
  }) async {
    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        final newLocation = settingsState.settings.location.copyWith(
          useAutoLocation: false,
          lat: lat,
          lng: lng,
          city: city,
          countryCode: countryCode,
        );

        final newSettings = settingsState.settings.copyWith(
          location: newLocation,
        );
        await _settingsCubit.saveSettings(newSettings);
        await _loadPrayerData(newSettings, DateTime.now());
      }
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Update prayer settings
  Future<void> updatePrayerSettings(PrayerSettings prayerSettings) async {
    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        final newSettings = settingsState.settings.copyWith(
          prayerSettings: prayerSettings,
        );
        await _settingsCubit.saveSettings(newSettings);
      }
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Reschedule all notifications
  Future<void> rescheduleNotifications() async {
    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        await _notificationService.reschedule(settingsState.settings);
        final scheduledCount = await _notificationService
            .getScheduledNotificationCount();

        if (state is PrayerLoaded) {
          final currentState = state as PrayerLoaded;
          emit(
            currentState.copyWith(scheduledNotificationsCount: scheduledCount),
          );
        }
      }
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  /// Change selected date for viewing
  Future<void> changeDate(DateTime date) async {
    final settingsState = _settingsCubit.state;
    if (settingsState is SettingsLoaded) {
      await _loadPrayerData(settingsState.settings, date);
    }
  }

  /// Navigate to next day
  Future<void> nextDay() async {
    if (state is PrayerLoaded) {
      final currentState = state as PrayerLoaded;
      final nextDate = currentState.selectedDate.add(const Duration(days: 1));
      await changeDate(nextDate);
    }
  }

  /// Navigate to previous day
  Future<void> previousDay() async {
    if (state is PrayerLoaded) {
      final currentState = state as PrayerLoaded;
      final prevDate = currentState.selectedDate.subtract(
        const Duration(days: 1),
      );
      await changeDate(prevDate);
    }
  }

  /// Navigate to today
  Future<void> goToToday() async {
    await changeDate(DateTime.now());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _settingsSubscription?.cancel();
    return super.close();
  }
}
