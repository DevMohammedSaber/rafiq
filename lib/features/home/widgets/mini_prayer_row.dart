import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MiniPrayerRow extends StatelessWidget {
  const MiniPrayerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final prayers = [
      {'name': 'Fajr', 'time': '04:50 AM', 'active': false},
      {'name': 'Dhuhr', 'time': '12:05 PM', 'active': true},
      {'name': 'Asr', 'time': '03:45 PM', 'active': false},
      {'name': 'Maghrib', 'time': '06:10 PM', 'active': false},
      {'name': 'Isha', 'time': '07:40 PM', 'active': false},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: prayers.map((prayer) {
          final isActive = prayer['active'] as bool;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  prayer['name'] as String,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prayer['time'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? Colors.white70 : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
