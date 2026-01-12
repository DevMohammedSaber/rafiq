import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/prayer_cubit.dart';
import '../cubit/prayer_state.dart';
import '../widgets/prayer_list_tile.dart';
import '../widgets/countdown_timer.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrayerCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('prayer.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'qibla.title'.tr(),
            onPressed: () => context.push('/prayers/qibla'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/prayers/settings'),
          ),
        ],
      ),
      body: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          if (state is PrayerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PrayerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PrayerCubit>().load(),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is PrayerLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrayerLoaded state) {
    final hijri = HijriCalendar.fromDate(state.selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Notification permission banner
          if (!state.notificationAllowed) _buildPermissionBanner(context),

          // Date Navigation
          _buildDateNavigation(context, state, hijri),
          const SizedBox(height: 24),

          // Next Prayer Card with Countdown
          if (state.nextPrayer != null && state.countdown != null)
            _buildNextPrayerCard(context, state),
          const SizedBox(height: 24),

          // Prayer List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.prayerList.length,
            itemBuilder: (context, index) {
              final prayer = state.prayerList[index];
              // Skip sunrise for notifications
              final showNotification = prayer.key != 'sunrise';

              return PrayerListTile(
                name: _getLocalizedPrayerName(prayer.key),
                time: prayer.time,
                isNext: prayer.isNext,
                isPassed: prayer.isPassed,
                showNotificationIcon: showNotification,
                isNotificationEnabled:
                    showNotification &&
                    state.settings.prayerSettings
                        .getPerPrayer(prayer.key)
                        .enabled,
              );
            },
          ),

          const SizedBox(height: 24),

          // Scheduled notifications info
          if (state.notificationAllowed &&
              state.scheduledNotificationsCount > 0)
            _buildScheduledInfo(context, state),

          // Reschedule button
          if (state.notificationAllowed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<PrayerCubit>().rescheduleNotifications(),
                icon: const Icon(Icons.refresh),
                label: Text('prayer.reschedule'.tr()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'prayer.notifications_disabled'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'prayer.enable_notifications_desc'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () =>
                context.read<PrayerCubit>().requestNotificationPermission(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('prayer.enable_notifications'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation(
    BuildContext context,
    PrayerLoaded state,
    HijriCalendar hijri,
  ) {
    final dateFormat = DateFormat(
      'EEEE, d MMM yyyy',
      context.locale.languageCode,
    );
    final isToday = _isSameDay(state.selectedDate, DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => context.read<PrayerCubit>().previousDay(),
          icon: Icon(Icons.arrow_back_ios, size: 16),
        ),
        Expanded(
          child: GestureDetector(
            onTap: isToday
                ? null
                : () => context.read<PrayerCubit>().goToToday(),
            child: Column(
              children: [
                Text(
                  dateFormat.format(state.selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (!isToday)
                  Text(
                    'prayer.tap_for_today'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.read<PrayerCubit>().nextDay(),
          icon: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }

  Widget _buildNextPrayerCard(BuildContext context, PrayerLoaded state) {
    final nextPrayerName = _getLocalizedPrayerName(
      state.nextPrayer!.name.toLowerCase(),
    );
    final nextPrayerTime =
        state.todayTimes[state.nextPrayer!.name.toLowerCase()];

    return AppCard(
      color: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'prayer.next_prayer'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            nextPrayerName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (nextPrayerTime != null)
            Text(
              DateFormat.jm(context.locale.languageCode).format(nextPrayerTime),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white70),
            ),
          const SizedBox(height: 16),
          if (state.countdown != null)
            CountdownTimer(duration: state.countdown!, textColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildScheduledInfo(BuildContext context, PrayerLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'prayer.scheduled_notifications'.tr(
              args: [state.scheduledNotificationsCount.toString()],
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  String _getLocalizedPrayerName(String key) {
    switch (key) {
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
        return key;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
