import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/mini_prayer_row.dart';
import 'widgets/quick_actions.dart';
import 'widgets/hadith_of_day_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/presentation/cubit/auth_cubit.dart';
import '../profile/presentation/cubit/settings_cubit.dart';
import '../quran/data/quran_repository.dart';
import '../azkar/data/azkar_reminder_repository.dart';
import '../quiz/presentation/cubit/daily_question_cubit.dart';
import '../quiz/presentation/widgets/daily_question_card.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  String displayName = "Guest";
                  String? photoUrl;

                  if (state is AuthAuthenticated) {
                    displayName = state.user.displayName ?? "User";
                    photoUrl = state.user.photoURL;
                  }

                  return Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "home.greeting".tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            context.read<AuthCubit>().signOut();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : const NetworkImage(
                                    "https://ui-avatars.com/api/?name=Guest&background=006D5B&color=fff",
                                  ),
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  const Icon(Icons.logout, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text("auth.sign_out".tr()),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Next Prayer
              const NextPrayerCard(),
              const SizedBox(height: 24),

              // Other Prayers
              Text(
                "home.todays_prayers".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const MiniPrayerRow(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "home.quick_actions".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const QuickActions(),
              const SizedBox(height: 24),

              // Daily Question
              BlocProvider(
                create: (context) => DailyQuestionCubit()..load(),
                child: const DailyQuestionCard(),
              ),
              const SizedBox(height: 24),

              // Hadith of the Day
              const HadithOfDayCard(),
              const SizedBox(height: 24),

              // Azkar Quick Actions
              Text(
                "azkar.title".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () {
                        context.push('/azkar/category/morning');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.wb_sunny_rounded,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "azkar.morning".tr(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      onTap: () {
                        context.push('/azkar/category/evening');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.nights_stay_rounded,
                                color: Colors.indigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "azkar.evening".tr(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Azkar Reminder Banner
              FutureBuilder(
                future: AzkarReminderRepository().loadReminderSettings(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final settings = snapshot.data!;
                    if (!settings.enabledMorning && !settings.enabledEvening) {
                      return AppCard(
                        onTap: () {
                          context.push('/azkar/reminders');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "azkar.enable_reminders_banner".tr(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              // Continue Reading - Dynamic
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, settingsState) {
                  if (settingsState is! SettingsLoaded) {
                    return const SizedBox.shrink();
                  }

                  final quranSettings = settingsState.settings.quranSettings;
                  final lastSurahId = quranSettings.lastReadSurahId;
                  final lastAyahNumber = quranSettings.lastReadAyahNumber;
                  final lastMushafPage = quranSettings.lastReadMushafPage;

                  if (lastMushafPage != null) {
                    return AppCard(
                      child: ListTile(
                        onTap: () {
                          context.push('/quran/1');
                        },
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text("home.continue_reading".tr()),
                        subtitle: Text(
                          '${"quran.open_mushaf".tr()} - ${"quran.page_number".tr()} $lastMushafPage',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  }

                  if (lastSurahId == null) {
                    return const SizedBox.shrink();
                  }

                  return FutureBuilder(
                    future: QuranRepository().getSurahById(lastSurahId),
                    builder: (context, snapshot) {
                      final surahName =
                          snapshot.data?.nameAr ?? 'Surah $lastSurahId';
                      final subtitle = lastAyahNumber != null
                          ? '$surahName - ${'quran.ayahs'.tr()} $lastAyahNumber'
                          : surahName;

                      return AppCard(
                        child: ListTile(
                          onTap: () {
                            final path = lastAyahNumber != null
                                ? '/quran/$lastSurahId?ayah=$lastAyahNumber'
                                : '/quran/$lastSurahId';
                            context.push(path);
                          },
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bookmark,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text("home.continue_reading".tr()),
                          subtitle: Text(subtitle),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
