import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/presentation/cubit/settings_cubit.dart';
import '../../prayer/data/prayer_times_service.dart';

class MiniPrayerRow extends StatelessWidget {
  const MiniPrayerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const SizedBox.shrink();
        }

        final settings = state.settings;
        final prayerService = PrayerTimesService();
        final prayerTimes = prayerService.getTodayPrayerTimes(settings);
        final nextPrayer = prayerTimes.nextPrayer();
        final nextPrayerName = nextPrayer.name.toLowerCase();

        final timeFormat = DateFormat.jm(context.locale.languageCode);

        final prayers = [
          {
            'key': 'fajr',
            'name': 'prayer.fajr'.tr(),
            'time': timeFormat.format(prayerTimes.fajr),
            'active': nextPrayerName == 'fajr',
          },
          {
            'key': 'dhuhr',
            'name': 'prayer.dhuhr'.tr(),
            'time': timeFormat.format(prayerTimes.dhuhr),
            'active': nextPrayerName == 'dhuhr',
          },
          {
            'key': 'asr',
            'name': 'prayer.asr'.tr(),
            'time': timeFormat.format(prayerTimes.asr),
            'active': nextPrayerName == 'asr',
          },
          {
            'key': 'maghrib',
            'name': 'prayer.maghrib'.tr(),
            'time': timeFormat.format(prayerTimes.maghrib),
            'active': nextPrayerName == 'maghrib',
          },
          {
            'key': 'isha',
            'name': 'prayer.isha'.tr(),
            'time': timeFormat.format(prayerTimes.isha),
            'active': nextPrayerName == 'isha',
          },
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: prayers.map((prayer) {
              final isActive = prayer['active'] as bool;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : Theme.of(context).cardColor,
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
      },
    );
  }
}
