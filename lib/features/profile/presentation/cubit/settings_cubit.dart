import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/models/user_settings.dart';
import '../../../prayer/data/prayer_notification_service.dart';

// States
abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final UserSettings settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final UserProfileRepository _repository;
  final PrayerNotificationService _notificationService;

  SettingsCubit(this._repository, this._notificationService)
    : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    // Optimistic update
    emit(SettingsLoaded(newSettings));
  }

  Future<void> saveSettings(
    UserSettings newSettings, {
    bool finishSetup = false,
  }) async {
    emit(SettingsLoading());
    try {
      var settingsToSave = newSettings;
      if (finishSetup) {
        settingsToSave = newSettings.copyWith(setupDone: true);
      }

      await _repository.saveSettings(settingsToSave);

      // Reschedule if saved
      await _notificationService.scheduleNotificationsForDays(
        settingsToSave,
        3,
      );

      emit(SettingsLoaded(settingsToSave));
    } catch (e) {
      emit(SettingsError("Failed to save settings: $e"));
    }
  }

  // Helper methods to mutate state easily
  void updateLocation(UserLocation location) {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      updateSettings(current.copyWith(location: location));
    }
  }

  void updatePrayerSettings(PrayerSettings prayerSettings) {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      updateSettings(current.copyWith(prayerSettings: prayerSettings));
    }
  }
}
