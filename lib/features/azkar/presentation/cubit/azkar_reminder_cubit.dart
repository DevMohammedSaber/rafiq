import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/azkar_reminder_repository.dart';
import '../../data/azkar_notification_service.dart';
import '../../domain/models/azkar_reminder_settings.dart';

abstract class AzkarReminderState extends Equatable {
  const AzkarReminderState();
  @override
  List<Object?> get props => [];
}

class AzkarReminderInitial extends AzkarReminderState {}

class AzkarReminderLoading extends AzkarReminderState {}

class AzkarReminderLoaded extends AzkarReminderState {
  final AzkarReminderSettings settings;

  const AzkarReminderLoaded.AzarReminderLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];

  AzkarReminderLoaded copyWith({AzkarReminderSettings? settings}) {
    return AzkarReminderLoaded.AzarReminderLoaded(
      settings: settings ?? this.settings,
    );
  }
}

class AzkarReminderError extends AzkarReminderState {
  final String message;

  const AzkarReminderError(this.message);

  @override
  List<Object?> get props => [message];
}

class AzkarReminderCubit extends Cubit<AzkarReminderState> {
  final AzkarReminderRepository _repository;
  final AzkarNotificationService _notificationService;

  AzkarReminderCubit(this._repository, this._notificationService)
    : super(AzkarReminderInitial());

  Future<void> loadReminderSettings() async {
    emit(AzkarReminderLoading());
    try {
      final settings = await _repository.loadReminderSettings();
      emit(AzkarReminderLoaded.AzarReminderLoaded(settings: settings));
    } catch (e) {
      emit(AzkarReminderError(e.toString()));
    }
  }

  Future<void> saveReminderSettings(AzkarReminderSettings settings) async {
    if (state is! AzkarReminderLoaded) return;

    emit(AzkarReminderLoading());
    try {
      await _repository.saveReminderSettings(settings);

      await _notificationService.init();
      if (settings.enabledMorning || settings.enabledEvening) {
        await _notificationService.scheduleDailyAzkarReminders(settings);
      } else {
        await _notificationService.cancelAzkarReminders();
      }

      emit(AzkarReminderLoaded.AzarReminderLoaded(settings: settings));
    } catch (e) {
      emit(AzkarReminderError(e.toString()));
    }
  }

  void updateSettings(AzkarReminderSettings newSettings) {
    if (state is! AzkarReminderLoaded) return;
    emit((state as AzkarReminderLoaded).copyWith(settings: newSettings));
  }
}
