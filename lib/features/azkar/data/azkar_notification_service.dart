import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/models/azkar_reminder_settings.dart';

class AzkarNotificationService {
  static const int _morningNotificationId = 20001;
  static const int _eveningNotificationId = 20002;

  Future<void> init() async {
    try {
      final isInitialized = await AwesomeNotifications()
          .isNotificationAllowed();
      if (!isInitialized) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (e) {
      // AwesomeNotifications may already be initialized by PrayerNotificationService
    }
  }

  Future<void> scheduleDailyAzkarReminders(
    AzkarReminderSettings settings,
  ) async {
    await cancelAzkarReminders();

    final now = DateTime.now();
    final location = tz.local;

    for (int day = 0; day < 365; day++) {
      final targetDate = now.add(Duration(days: day));

      if (settings.enabledMorning) {
        final morningTime = _parseTime(settings.morningTime);
        final morningDateTime = tz.TZDateTime(
          location,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          morningTime.hour,
          morningTime.minute,
        );

        if (morningDateTime.isAfter(tz.TZDateTime.now(location))) {
          try {
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: _morningNotificationId + (day * 100),
                channelKey: 'prayers_channel',
                title: 'أذكار الصباح',
                body: 'حان وقت أذكار الصباح',
                notificationLayout: NotificationLayout.Default,
              ),
              schedule: NotificationCalendar.fromDate(
                date: morningDateTime,
                allowWhileIdle: true,
              ),
            );
          } catch (e) {
            // Handle error silently
          }
        }
      }

      if (settings.enabledEvening) {
        final eveningTime = _parseTime(settings.eveningTime);
        final eveningDateTime = tz.TZDateTime(
          location,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          eveningTime.hour,
          eveningTime.minute,
        );

        if (eveningDateTime.isAfter(tz.TZDateTime.now(location))) {
          try {
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: _eveningNotificationId + (day * 100),
                channelKey: 'prayers_channel',
                title: 'أذكار المساء',
                body: 'حان وقت أذكار المساء',
                notificationLayout: NotificationLayout.Default,
              ),
              schedule: NotificationCalendar.fromDate(
                date: eveningDateTime,
                allowWhileIdle: true,
              ),
            );
          } catch (e) {
            // Handle error silently
          }
        }
      }
    }
  }

  Future<void> cancelAzkarReminders() async {
    try {
      for (int day = 0; day < 365; day++) {
        await AwesomeNotifications().cancel(
          _morningNotificationId + (day * 100),
        );
        await AwesomeNotifications().cancel(
          _eveningNotificationId + (day * 100),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) {
      return DateTime(2000, 1, 1, 8, 0);
    }
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(2000, 1, 1, hour, minute);
  }
}
