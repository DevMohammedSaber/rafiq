import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:adhan/adhan.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/presentation/cubit/settings_cubit.dart';
import '../../prayer/data/prayer_times_service.dart';

class NextPrayerCard extends StatefulWidget {
  const NextPrayerCard({super.key});

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  String _nextPrayerName = '';
  String _nextPrayerTime = '';
  String _countdown = '--:--:--';
  String _location = 'Cairo, Egypt';
  bool _initialized = false;
  Timer? _countdownTimer;
  DateTime? _nextPrayerDateTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadPrayerData();
      _startCountdownTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_nextPrayerDateTime != null) {
        _updateCountdown(_nextPrayerDateTime!);
        setState(() {});

        // Check if prayer time has passed
        if (_nextPrayerDateTime!.isBefore(DateTime.now())) {
          // Reload prayer data for next prayer
          _loadPrayerData();
        }
      }
    });
  }

  void _loadPrayerData() {
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      final settings = settingsState.settings;
      _location = '${settings.location.city}, ${settings.location.countryCode}';

      final prayerTimes = _prayerService.getTodayPrayerTimes(settings);
      final nextPrayer = prayerTimes.nextPrayer();

      if (nextPrayer != Prayer.none) {
        _nextPrayerName = _getPrayerDisplayName(nextPrayer.name);
        final nextTime = prayerTimes.timeForPrayer(nextPrayer);
        if (nextTime != null) {
          _nextPrayerDateTime = nextTime;
          _nextPrayerTime = DateFormat.jm(
            context.locale.languageCode,
          ).format(nextTime);
          _updateCountdown(nextTime);
        }
      } else {
        // No more prayers today, get tomorrow's Fajr
        final tomorrowTimes = _prayerService.getPrayerTimesForDate(
          settings,
          DateTime.now().add(const Duration(days: 1)),
        );
        _nextPrayerName = _getPrayerDisplayName('fajr');
        _nextPrayerDateTime = tomorrowTimes.fajr;
        _nextPrayerTime = DateFormat.jm(
          context.locale.languageCode,
        ).format(tomorrowTimes.fajr);
        _updateCountdown(tomorrowTimes.fajr);
      }
      setState(() {});
    }
  }

  void _updateCountdown(DateTime nextTime) {
    final now = DateTime.now();
    final difference = nextTime.difference(now);

    if (difference.isNegative) {
      _countdown = '00:00:00';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      _countdown =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _getPrayerDisplayName(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return 'prayer.fajr'.tr();
      case 'sunrise':
        return 'prayer.sunrise'.tr();
      case 'dhuhr':
        return 'prayer.dhuhr'.tr();
      case 'asr':
        return 'prayer.asr'.tr();
      case 'maghrib':
        return 'prayer.maghrib'.tr();
      case 'isha':
        return 'prayer.isha'.tr();
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded) {
          _loadPrayerData();
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.mosque,
                size: 150,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _location,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        FontAwesomeIcons.bell,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${"home.next_prayer".tr()}: $_nextPrayerName',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _countdown,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nextPrayerTime,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
