import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/theme/app_colors.dart';

class PrayerListTile extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isNext;
  final bool isPassed;
  final bool showNotificationIcon;
  final bool isNotificationEnabled;

  const PrayerListTile({
    super.key,
    required this.name,
    required this.time,
    this.isNext = false,
    this.isPassed = false,
    this.showNotificationIcon = true,
    this.isNotificationEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm(context.locale.languageCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: isNext ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Prayer name
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isNext
                          ? Colors.white
                          : isPassed
                          ? Theme.of(context).disabledColor
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'prayer.next'.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Prayer time
            Text(
              timeFormat.format(time),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isNext
                    ? Colors.white
                    : isPassed
                    ? Theme.of(context).disabledColor
                    : null,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Notification icon
            if (showNotificationIcon) ...[
              const SizedBox(width: 16),
              Icon(
                isNotificationEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: isNext
                    ? Colors.white70
                    : isNotificationEnabled
                    ? AppColors.primary
                    : Theme.of(context).disabledColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
