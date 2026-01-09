import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../../profile/domain/models/user_settings.dart';
import 'prayer_times_service.dart';

class PrayerNotificationService {
  final PrayerTimesService _prayerTimesService = PrayerTimesService();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      // set the icon to null to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'prayers_channel_group',
          channelKey: 'prayers_channel',
          channelName: 'Prayer Notifications',
          channelDescription: 'Notifications for Adhan and Iqama',
          defaultColor: const Color(0xFF1B5E20), // AppColors.primary roughly
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          // soundSource: 'resource://raw/res_custom_notification', // Removed to avoid crash
          criticalAlerts: true,
        ),
      ],
      // Channel groups are only visual and are voluntary
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'prayers_channel_group',
          channelGroupName: 'Prayer Notifications',
        ),
      ],
      debug: true,
    );
  }

  Future<void> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> scheduleNotificationsForDays(
    UserSettings settings,
    int days,
  ) async {
    await AwesomeNotifications().cancelAll();

    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      final prayerTimes = _prayerTimesService.getPrayerTimesForDate(
        settings,
        date,
      );

      await _scheduleForPrayer(settings, prayerTimes.fajr, 'Fajr', i);
      await _scheduleForPrayer(settings, prayerTimes.dhuhr, 'Dhuhr', i);
      await _scheduleForPrayer(settings, prayerTimes.asr, 'Asr', i);
      await _scheduleForPrayer(settings, prayerTimes.maghrib, 'Maghrib', i);
      await _scheduleForPrayer(settings, prayerTimes.isha, 'Isha', i);
    }
  }

  Future<void> _scheduleForPrayer(
    UserSettings settings,
    DateTime prayerTime,
    String prayerName,
    int dayIndex,
  ) async {
    final prayerKey = prayerName.toLowerCase();

    // Check if enabled
    if (settings.prayerSettings.enabledPrayers[prayerKey] != true) return;

    // IDs: dayIndex * 100 + prayerIndex * 10 + type
    int prayerBaseId = (dayIndex * 100) + (_getPrayerIndex(prayerName) * 10);

    // 1. Before Adhan
    if (settings.prayerSettings.beforeAdhanMinutes > 0) {
      final beforeTime = prayerTime.subtract(
        Duration(minutes: settings.prayerSettings.beforeAdhanMinutes),
      );
      if (beforeTime.isAfter(DateTime.now())) {
        await _scheduleOne(
          id: prayerBaseId + 1,
          title: 'Upcoming Prayer',
          body:
              '$prayerName is in ${settings.prayerSettings.beforeAdhanMinutes} minutes',
          scheduledDate: beforeTime,
        );
      }
    }

    // 2. Adhan
    if (prayerTime.isAfter(DateTime.now())) {
      await _scheduleOne(
        id: prayerBaseId + 2,
        title: 'Time for $prayerName',
        body: 'It is now $prayerName time',
        scheduledDate: prayerTime,
        playSound: true,
      );
    }

    // 3. Before Iqama
    final iqamaMinutes =
        settings.prayerSettings.iqamaAfterMinutes[prayerKey] ?? 10;
    final iqamaTime = prayerTime.add(Duration(minutes: iqamaMinutes));

    if (settings.prayerSettings.beforeIqamaMinutes > 0) {
      final beforeIqama = iqamaTime.subtract(
        Duration(minutes: settings.prayerSettings.beforeIqamaMinutes),
      );
      if (beforeIqama.isAfter(DateTime.now())) {
        await _scheduleOne(
          id: prayerBaseId + 3,
          title: 'Iqama Soon',
          body:
              'Iqama for $prayerName in ${settings.prayerSettings.beforeIqamaMinutes} minutes',
          scheduledDate: beforeIqama,
        );
      }
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool playSound = false,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'prayers_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        // customSound: playSound ? 'resource://raw/adhan' : null, // If using custom sounds
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  int _getPrayerIndex(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return 1;
      case 'Dhuhr':
        return 2;
      case 'Asr':
        return 3;
      case 'Maghrib':
        return 4;
      case 'Isha':
        return 5;
      default:
        return 0;
    }
  }
}
