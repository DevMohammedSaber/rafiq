import 'package:equatable/equatable.dart';

class AzkarReminderSettings extends Equatable {
  final bool enabledMorning;
  final bool enabledEvening;
  final String morningTime;
  final String eveningTime;

  const AzkarReminderSettings({
    this.enabledMorning = false,
    this.enabledEvening = false,
    this.morningTime = '08:00',
    this.eveningTime = '18:00',
  });

  factory AzkarReminderSettings.fromJson(Map<String, dynamic> json) {
    return AzkarReminderSettings(
      enabledMorning: json['enabledMorning'] as bool? ?? false,
      enabledEvening: json['enabledEvening'] as bool? ?? false,
      morningTime: json['morningTime'] as String? ?? '08:00',
      eveningTime: json['eveningTime'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabledMorning': enabledMorning,
      'enabledEvening': enabledEvening,
      'morningTime': morningTime,
      'eveningTime': eveningTime,
    };
  }

  AzkarReminderSettings copyWith({
    bool? enabledMorning,
    bool? enabledEvening,
    String? morningTime,
    String? eveningTime,
  }) {
    return AzkarReminderSettings(
      enabledMorning: enabledMorning ?? this.enabledMorning,
      enabledEvening: enabledEvening ?? this.enabledEvening,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
    );
  }

  @override
  List<Object?> get props => [
    enabledMorning,
    enabledEvening,
    morningTime,
    eveningTime,
  ];
}
