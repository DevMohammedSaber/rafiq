import 'package:equatable/equatable.dart';
import 'package:adhan/adhan.dart';
import '../../../profile/domain/models/user_settings.dart';

/// Prayer times model for display
class PrayerTimeDisplay {
  final String name;
  final String key;
  final DateTime time;
  final bool isNext;
  final bool isPassed;

  const PrayerTimeDisplay({
    required this.name,
    required this.key,
    required this.time,
    required this.isNext,
    required this.isPassed,
  });
}

/// Base state for Prayer feature
abstract class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PrayerInitial extends PrayerState {}

/// Loading state
class PrayerLoading extends PrayerState {}

/// Loaded state with prayer times data
class PrayerLoaded extends PrayerState {
  final Map<String, DateTime> todayTimes;
  final Prayer? nextPrayer;
  final Duration? countdown;
  final UserSettings settings;
  final bool notificationAllowed;
  final int scheduledNotificationsCount;
  final DateTime selectedDate;
  final List<PrayerTimeDisplay> prayerList;

  const PrayerLoaded({
    required this.todayTimes,
    required this.nextPrayer,
    required this.countdown,
    required this.settings,
    required this.notificationAllowed,
    required this.scheduledNotificationsCount,
    required this.selectedDate,
    required this.prayerList,
  });

  PrayerLoaded copyWith({
    Map<String, DateTime>? todayTimes,
    Prayer? nextPrayer,
    Duration? countdown,
    UserSettings? settings,
    bool? notificationAllowed,
    int? scheduledNotificationsCount,
    DateTime? selectedDate,
    List<PrayerTimeDisplay>? prayerList,
  }) {
    return PrayerLoaded(
      todayTimes: todayTimes ?? this.todayTimes,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      countdown: countdown ?? this.countdown,
      settings: settings ?? this.settings,
      notificationAllowed: notificationAllowed ?? this.notificationAllowed,
      scheduledNotificationsCount:
          scheduledNotificationsCount ?? this.scheduledNotificationsCount,
      selectedDate: selectedDate ?? this.selectedDate,
      prayerList: prayerList ?? this.prayerList,
    );
  }

  @override
  List<Object?> get props => [
    todayTimes,
    nextPrayer,
    countdown,
    settings,
    notificationAllowed,
    scheduledNotificationsCount,
    selectedDate,
    prayerList,
  ];
}

/// Error state
class PrayerError extends PrayerState {
  final String message;

  const PrayerError(this.message);

  @override
  List<Object?> get props => [message];
}
