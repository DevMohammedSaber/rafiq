import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../../profile/domain/models/user_settings.dart';
import 'prayer_times_service.dart';

/// Service for managing prayer notifications using Awesome Notifications
class PrayerNotificationService {
  final PrayerTimesService _prayerTimesService = PrayerTimesService();

  // Channel keys
  static const String reminderChannelKey = 'prayer_reminder';
  static const String adhanChannelKey = 'prayer_adhan';
  static const String iqamaChannelKey = 'prayer_iqama';

  // Channel group key
  static const String prayerChannelGroupKey = 'prayers_channel_group';

  // Prayer indices for notification ID generation
  static const Map<String, int> prayerIndices = {
    'fajr': 1,
    'dhuhr': 2,
    'asr': 3,
    'maghrib': 4,
    'isha': 5,
  };

  // Notification type indices
  static const int beforeAdhanType = 1;
  static const int adhanType = 2;
  static const int beforeIqamaType = 3;
  static const int iqamaType = 4;

  /// Initialize Awesome Notifications with 3 prayer channels
  Future<void> init() async {
    await PrayerTimesService.initializeTimezone();

    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelGroupKey: prayerChannelGroupKey,
          channelKey: reminderChannelKey,
          channelName: 'Prayer Reminder',
          channelDescription: 'Reminder notifications before prayer time',
          defaultColor: const Color(0xFF1B5E20),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          soundSource: _getSoundSource('reminder'),
          criticalAlerts: false,
          defaultPrivacy: NotificationPrivacy.Private,
          locked: false,
        ),
        NotificationChannel(
          channelGroupKey: prayerChannelGroupKey,
          channelKey: adhanChannelKey,
          channelName: 'Prayer Adhan',
          channelDescription: 'Adhan notifications at prayer time',
          defaultColor: const Color(0xFF1B5E20),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          soundSource: _getSoundSource('adhan'),
          criticalAlerts: true,
          defaultPrivacy: NotificationPrivacy.Private,
          locked: false,
        ),
        NotificationChannel(
          channelGroupKey: prayerChannelGroupKey,
          channelKey: iqamaChannelKey,
          channelName: 'Prayer Iqama',
          channelDescription: 'Iqama notifications',
          defaultColor: const Color(0xFF1B5E20),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          soundSource: _getSoundSource('iqama'),
          criticalAlerts: true,
          defaultPrivacy: NotificationPrivacy.Private,
          locked: false,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: prayerChannelGroupKey,
          channelGroupName: 'Prayer Notifications',
        ),
      ],
      debug: true,
    );
  }

  /// Get platform-specific sound source
  String? _getSoundSource(String soundName) {
    if (Platform.isAndroid) {
      return 'resource://raw/$soundName';
    } else if (Platform.isIOS) {
      return soundName;
    }
    return null;
  }

  /// Check if notifications are allowed
  Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    bool isAllowed = await isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  /// Set up notification action listeners
  /// Call this in main.dart after MaterialApp is created
  static void setListeners(BuildContext context) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Handle notification taps
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload;
    if (payload != null) {
      final type = payload['type'];
      final prayer = payload['prayer'];
      debugPrint('Notification tapped: type=$type, prayer=$prayer');
      // Navigation will be handled by the app when it opens
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('Notification created: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }

  /// Cancel all prayer notifications
  Future<void> cancelAllPrayerSchedules() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Calculate how many days to schedule based on enabled notifications
  int _calculateDaysToSchedule(UserSettings settings) {
    if (Platform.isIOS) {
      // iOS has a limit of ~64 scheduled notifications
      int notificationsPerDay = 0;
      final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

      for (final prayer in prayers) {
        final perPrayer = settings.prayerSettings.getPerPrayer(prayer);
        if (!perPrayer.enabled) continue;

        // Before Adhan
        if (settings.prayerSettings.beforeAdhanMinutes > 0) {
          notificationsPerDay++;
        }
        // Adhan
        if (perPrayer.adhanEnabled) {
          notificationsPerDay++;
        }
        // Before Iqama
        if (perPrayer.iqamaEnabled &&
            settings.prayerSettings.beforeIqamaMinutes > 0) {
          notificationsPerDay++;
        }
        // Iqama
        if (perPrayer.iqamaEnabled) {
          notificationsPerDay++;
        }
      }

      if (notificationsPerDay == 0) return 0;

      // Calculate days to stay under 60 notifications (leaving buffer)
      int days = (60 / notificationsPerDay).floor();
      return days.clamp(1, 7);
    }

    // Android can handle more
    return 7;
  }

  /// Generate deterministic notification ID
  /// Format: YYYYMMDD * 100 + prayerIndex * 10 + typeIndex
  int _generateNotificationId(DateTime date, String prayer, int typeIndex) {
    final dateInt = date.year * 10000 + date.month * 100 + date.day;
    final prayerIndex = prayerIndices[prayer] ?? 0;
    return (dateInt % 100000) * 100 + prayerIndex * 10 + typeIndex;
  }

  /// Schedule notifications for multiple days
  Future<void> scheduleNotificationsForDays(
    UserSettings settings,
    int days,
  ) async {
    if (!settings.prayerSettings.remindersEnabled) {
      await cancelAllPrayerSchedules();
      return;
    }

    await cancelAllPrayerSchedules();

    final actualDays = _calculateDaysToSchedule(settings);
    if (actualDays == 0) return;

    final now = DateTime.now();

    for (int i = 0; i < actualDays; i++) {
      final date = now.add(Duration(days: i));
      await _scheduleForDate(settings, date);
    }
  }

  /// Schedule all notifications for a specific date
  Future<void> _scheduleForDate(UserSettings settings, DateTime date) async {
    final prayerTimes = _prayerTimesService.getPrayerTimesForDate(
      settings,
      date,
    );
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    for (final prayer in prayers) {
      final perPrayer = settings.prayerSettings.getPerPrayer(prayer);
      if (!perPrayer.enabled) continue;

      DateTime prayerTime;
      switch (prayer) {
        case 'fajr':
          prayerTime = prayerTimes.fajr;
          break;
        case 'dhuhr':
          prayerTime = prayerTimes.dhuhr;
          break;
        case 'asr':
          prayerTime = prayerTimes.asr;
          break;
        case 'maghrib':
          prayerTime = prayerTimes.maghrib;
          break;
        case 'isha':
          prayerTime = prayerTimes.isha;
          break;
        default:
          continue;
      }

      await _scheduleForPrayer(
        settings: settings,
        prayerTime: prayerTime,
        prayerName: prayer,
        perPrayerSettings: perPrayer,
        date: date,
      );
    }
  }

  /// Schedule notifications for a single prayer
  Future<void> _scheduleForPrayer({
    required UserSettings settings,
    required DateTime prayerTime,
    required String prayerName,
    required PerPrayerSettings perPrayerSettings,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final prayerDisplayName = _getPrayerDisplayName(prayerName);

    // 1. Before Adhan notification
    if (settings.prayerSettings.beforeAdhanMinutes > 0) {
      final beforeTime = prayerTime.subtract(
        Duration(minutes: settings.prayerSettings.beforeAdhanMinutes),
      );
      if (beforeTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(date, prayerName, beforeAdhanType),
          channelKey: reminderChannelKey,
          title: 'Upcoming Prayer',
          body:
              '$prayerDisplayName is in ${settings.prayerSettings.beforeAdhanMinutes} minutes',
          scheduledDate: beforeTime,
          payload: {
            'type': 'reminder',
            'prayer': prayerName,
            'date': _formatDate(date),
          },
        );
      }
    }

    // 2. Adhan notification
    if (perPrayerSettings.adhanEnabled && prayerTime.isAfter(now)) {
      await _scheduleNotification(
        id: _generateNotificationId(date, prayerName, adhanType),
        channelKey: adhanChannelKey,
        title: 'Time for $prayerDisplayName',
        body: 'It is now $prayerDisplayName time',
        scheduledDate: prayerTime,
        payload: {
          'type': 'adhan',
          'prayer': prayerName,
          'date': _formatDate(date),
        },
      );
    }

    // Handle Iqama notifications
    if (perPrayerSettings.iqamaEnabled) {
      final iqamaTime = prayerTime.add(
        Duration(minutes: perPrayerSettings.iqamaAfterMin),
      );

      // 3. Before Iqama notification
      if (settings.prayerSettings.beforeIqamaMinutes > 0) {
        final beforeIqamaTime = iqamaTime.subtract(
          Duration(minutes: settings.prayerSettings.beforeIqamaMinutes),
        );
        if (beforeIqamaTime.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(date, prayerName, beforeIqamaType),
            channelKey: reminderChannelKey,
            title: 'Iqama Soon',
            body:
                'Iqama for $prayerDisplayName in ${settings.prayerSettings.beforeIqamaMinutes} minutes',
            scheduledDate: beforeIqamaTime,
            payload: {
              'type': 'reminder',
              'prayer': prayerName,
              'date': _formatDate(date),
            },
          );
        }
      }

      // 4. Iqama notification
      if (iqamaTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(date, prayerName, iqamaType),
          channelKey: iqamaChannelKey,
          title: 'Iqama: $prayerDisplayName',
          body: 'It is now Iqama time for $prayerDisplayName',
          scheduledDate: iqamaTime,
          payload: {
            'type': 'iqama',
            'prayer': prayerName,
            'date': _formatDate(date),
          },
        );
      }
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Get display name for prayer
  String _getPrayerDisplayName(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return 'Fajr';
      case 'dhuhr':
        return 'Dhuhr';
      case 'asr':
        return 'Asr';
      case 'maghrib':
        return 'Maghrib';
      case 'isha':
        return 'Isha';
      default:
        return prayer;
    }
  }

  /// Format date for payload
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Reschedule all notifications (convenience method)
  Future<void> reschedule(UserSettings settings) async {
    await scheduleNotificationsForDays(settings, 7);
  }

  /// Get count of scheduled notifications
  Future<int> getScheduledNotificationCount() async {
    final scheduled = await AwesomeNotifications().listScheduledNotifications();
    return scheduled.length;
  }
}
