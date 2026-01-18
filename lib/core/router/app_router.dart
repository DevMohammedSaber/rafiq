import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/content/content_update_manager.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/profile/presentation/cubit/settings_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/location_permission_screen.dart';
import '../../features/onboarding/presentation/pages/setup_page.dart';
import '../../features/home/home_screen.dart';
import '../../features/quran/presentation/pages/quran_home_page.dart';
import '../../features/quran/presentation/pages/quran_ayah_reader_page.dart';
import '../../features/quran/presentation/pages/quran_mushaf_images_reader_page.dart';
import '../../features/quran/presentation/pages/quran_search_page.dart';
import '../../features/quran/data/quran_repository.dart';
import '../../features/quran/presentation/cubit/quran_home_cubit.dart';
import '../../features/quran/presentation/cubit/quran_bootstrap_cubit.dart';
import '../../features/quran/presentation/cubit/quran_search_cubit.dart';
import '../../features/quran/presentation/pages/quran_import_page.dart';
import '../../features/quran/data/quran_import_service.dart';
import '../../features/quran/mushaf/presentation/pages/mushaf_store_page.dart';
import '../../features/quran/tafsir/presentation/cubit/tafsir_cubit.dart';
import '../../features/quran/tafsir/presentation/pages/tafsir_page.dart';
import '../../features/quran/audio/presentation/cubit/quran_audio_cubit.dart';
import '../../features/quran/audio/presentation/pages/quran_audio_settings_page.dart';
import '../../features/azkar/presentation/pages/azkar_categories_page.dart';
import '../../features/azkar/presentation/pages/zikr_list_page.dart';
import '../../features/azkar/presentation/pages/zikr_reader_page.dart';
import '../../features/azkar/presentation/pages/azkar_reminder_settings_page.dart';
import '../../features/azkar/presentation/cubit/azkar_categories_cubit.dart';
import '../../features/azkar/presentation/cubit/zikr_list_cubit.dart';
import '../../features/azkar/presentation/cubit/zikr_reader_cubit.dart';
import '../../features/azkar/presentation/cubit/azkar_reminder_cubit.dart';
import '../../features/azkar/data/azkar_repository.dart';
import '../../features/azkar/data/azkar_user_repository.dart';
import '../../features/azkar/data/azkar_reminder_repository.dart';
import '../../features/azkar/data/azkar_notification_service.dart';
import '../../features/prayer/presentation/pages/prayer_page.dart';
import '../../features/prayer/presentation/pages/prayer_settings_page.dart';
import '../../features/prayer/presentation/cubit/prayer_cubit.dart';
import '../../features/prayer/data/prayer_times_service.dart';
import '../../features/prayer/data/prayer_notification_service.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/qibla/presentation/cubit/qibla_cubit.dart';
import '../../features/tasbeeh/presentation/pages/tasbeeh_page.dart';
import '../../features/tasbeeh/presentation/pages/tasbeeh_presets_page.dart';
import '../../features/tasbeeh/presentation/cubit/tasbeeh_cubit.dart';
import '../../features/tasbeeh/data/tasbeeh_local_repository.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/quiz/presentation/pages/quiz_home_page.dart';
import '../../features/quiz/presentation/pages/quiz_game_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../../features/quiz/presentation/cubit/quiz_home_cubit.dart';
import '../../features/quiz/presentation/cubit/quiz_game_cubit.dart';
import '../../features/quiz/domain/models/quiz_result.dart';
import '../../features/more/more_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../core/components/bottom_nav_bar.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/hadith/data/hadith_repository.dart';
import '../../features/hadith/data/hadith_import_service.dart';
import '../../features/hadith/data/hadith_user_repository.dart';
import '../../features/hadith/data/hadith_daily_repository.dart';
import '../../features/hadith/presentation/cubit/hadith_bootstrap_cubit.dart';
import '../../features/hadith/presentation/cubit/hadith_books_cubit.dart';
import '../../features/hadith/presentation/cubit/hadith_list_cubit.dart';
import '../../features/hadith/presentation/cubit/hadith_detail_cubit.dart';
import '../../features/hadith/presentation/cubit/hadith_of_day_cubit.dart';
import '../../features/hadith/presentation/pages/hadith_home_page.dart';
import '../../features/hadith/presentation/pages/hadith_list_page.dart';
import '../../features/hadith/presentation/pages/hadith_detail_page.dart';
import '../../features/bootstrap/presentation/pages/content_selection_page.dart';
import '../../features/bootstrap/presentation/cubit/content_selection_cubit.dart';
import '../../features/settings/presentation/pages/content_downloads_page.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorQuranKey = GlobalKey<NavigatorState>(debugLabel: 'quran');
final _shellNavigatorAzkarKey = GlobalKey<NavigatorState>(debugLabel: 'azkar');
final _shellNavigatorPrayerKey = GlobalKey<NavigatorState>(
  debugLabel: 'prayer',
);
final _shellNavigatorMoreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

class AppRouter {
  final AuthCubit authCubit;
  final SettingsCubit settingsCubit;

  AppRouter(this.authCubit, this.settingsCubit);

  late final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authCubit.stream),
      GoRouterRefreshStream(settingsCubit.stream),
    ]),
    redirect: (context, state) async {
      final authState = authCubit.state;
      final settingsState = settingsCubit.state;

      final bool isAuthenticated =
          authState is AuthAuthenticated || authState is AuthGuest;
      final bool isUnauthenticated = authState is AuthUnauthenticated;
      final bool isAuthInitial = authState is AuthInitial;
      final bool isAuthLoading = authState is AuthLoading;

      final bool onLoginPage = state.fullPath == '/login';
      final bool onSetupPage = state.fullPath == '/setup';
      final bool onOnboardingPage = state.fullPath == '/';
      final bool onSplashPage = state.fullPath == '/splash';
      final bool onContentSelectionPage =
          state.fullPath == '/content/select-download';

      if (onSplashPage) return null;

      // 0. Check Content Readiness
      bool isContentReady = false;
      try {
        isContentReady = await ContentUpdateManager().isContentReady();
      } catch (_) {}

      if (!isContentReady) {
        if (onContentSelectionPage) return null;
        return '/content/select-download';
      }

      if (isAuthInitial || isAuthLoading) {
        return null;
      }

      // 1. Unauthenticated -> Login
      if (isUnauthenticated) {
        if (onLoginPage || onOnboardingPage) {
          return null;
        }
        return '/login';
      }

      // 2. Authenticated
      if (isAuthenticated) {
        if (settingsState is SettingsLoading) {
          return null;
        }

        if (settingsState is SettingsLoaded) {
          if (!settingsState.settings.setupDone) {
            if (onSetupPage) return null;
            return '/setup';
          }

          if (onLoginPage ||
              onSetupPage ||
              onOnboardingPage ||
              onSplashPage ||
              onContentSelectionPage) {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/content/select-download',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (context) => ContentSelectionCubit(),
          child: const ContentSelectionPage(),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: '/hadith',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => HadithBootstrapCubit(HadithImportService()),
            ),
            BlocProvider(
              create: (context) => HadithBooksCubit(HadithRepository()),
            ),
          ],
          child: const HadithHomePage(),
        ),
        routes: [
          GoRoute(
            path: 'book/:bookId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final bookId = state.pathParameters['bookId']!;
              return BlocProvider(
                create: (context) => HadithListCubit(
                  HadithRepository(),
                  HadithUserRepository(),
                  bookId,
                ),
                child: HadithListPage(bookId: bookId),
              );
            },
          ),
          GoRoute(
            path: 'item/:uid',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final uid = state.pathParameters['uid']!;
              return BlocProvider(
                create: (context) => HadithDetailCubit(
                  HadithRepository(),
                  HadithUserRepository(),
                ),
                child: HadithDetailPage(uid: uid),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tasbeeh',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final authState = context.read<AuthCubit>().state;
          String? userId;
          if (authState is AuthAuthenticated) {
            userId = authState.user.uid;
          }
          return BlocProvider(
            create: (context) => TasbeehCubit(
              localRepository: TasbeehLocalRepository(),
              userId: userId,
            ),
            child: const TasbeehPage(),
          );
        },
        routes: [
          GoRoute(
            path: 'presets',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final authState = context.read<AuthCubit>().state;
              String? userId;
              if (authState is AuthAuthenticated) {
                userId = authState.user.uid;
              }
              return BlocProvider(
                create: (context) => TasbeehCubit(
                  localRepository: TasbeehLocalRepository(),
                  userId: userId,
                )..init(),
                child: const TasbeehPresetsPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => ProfileCubit(),
            child: const ProfilePage(),
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              return BlocProvider(
                create: (context) => ProfileCubit()..load(),
                child: const EditProfilePage(),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWrapperGoRouter(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => BlocProvider(
                  create: (context) => HadithOfDayCubit(
                    HadithRepository(),
                    HadithDailyRepository(),
                  ),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorQuranKey,
            routes: [
              GoRoute(
                path: '/quran',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) =>
                          QuranBootstrapCubit(QuranImportService())
                            ..checkStatus(),
                    ),
                    BlocProvider(
                      create: (context) => QuranHomeCubit(QuranRepository()),
                    ),
                  ],
                  child: BlocBuilder<QuranBootstrapCubit, QuranBootstrapState>(
                    builder: (context, bootstrapState) {
                      if (bootstrapState is QuranBootstrapReady) {
                        return const QuranHomePage();
                      }
                      return const QuranImportPage();
                    },
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'search',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) => QuranSearchCubit(),
                        child: const QuranSearchPage(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'audio-settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) => QuranAudioCubit(),
                        child: const QuranAudioSettingsPage(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'tafsir/:surahId/:ayahNumber',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final surahId =
                          int.tryParse(
                            state.pathParameters['surahId'] ?? '1',
                          ) ??
                          1;
                      final ayahNumber =
                          int.tryParse(
                            state.pathParameters['ayahNumber'] ?? '1',
                          ) ??
                          1;
                      final ayahText = state.uri.queryParameters['text'] ?? '';

                      return BlocProvider(
                        create: (context) => TafsirCubit(),
                        child: TafsirPage(
                          surahId: surahId,
                          ayahNumber: ayahNumber,
                          ayahText: ayahText,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'text/:surahId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final surahId =
                          int.tryParse(
                            state.pathParameters['surahId'] ?? '1',
                          ) ??
                          1;
                      final ayahStr = state.uri.queryParameters['ayah'];
                      final scrollToAyah = ayahStr != null
                          ? int.tryParse(ayahStr)
                          : null;

                      // Use the new QuranAyahReaderPage (Mode 1: Ayah-by-Ayah)
                      return QuranAyahReaderPage(
                        surahId: surahId,
                        scrollToAyah: scrollToAyah,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'mushaf',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final pageStr = state.uri.queryParameters['page'];
                      final page = pageStr != null
                          ? int.tryParse(pageStr)
                          : null;
                      // Use the new QuranMushafImagesReaderPage (Mode 2: Mushaf Images)
                      return QuranMushafImagesReaderPage(initialPage: page);
                    },
                    routes: [
                      GoRoute(
                        path: 'store',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const MushafStorePage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAzkarKey,
            routes: [
              GoRoute(
                path: '/azkar',
                builder: (context, state) => BlocProvider(
                  create: (context) => AzkarCategoriesCubit(AzkarRepository()),
                  child: const AzkarCategoriesPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'category/:categoryId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final categoryId =
                          state.pathParameters['categoryId'] ?? '';
                      return BlocProvider(
                        create: (context) => ZikrListCubit(
                          AzkarRepository(),
                          AzkarUserRepository(),
                        ),
                        child: ZikrListPage(categoryId: categoryId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'reader/:categoryId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final categoryId =
                          state.pathParameters['categoryId'] ?? '';
                      final indexStr = state.uri.queryParameters['index'];
                      final initialIndex = indexStr != null
                          ? int.tryParse(indexStr)
                          : null;
                      return BlocProvider(
                        create: (context) => ZikrReaderCubit(
                          AzkarRepository(),
                          AzkarUserRepository(),
                        ),
                        child: ZikrReaderPage(
                          categoryId: categoryId,
                          initialIndex: initialIndex,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'reminders',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) => AzkarReminderCubit(
                          AzkarReminderRepository(),
                          AzkarNotificationService(),
                        ),
                        child: const AzkarReminderSettingsPage(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPrayerKey,
            routes: [
              GoRoute(
                path: '/prayers',
                builder: (context, state) => BlocProvider(
                  create: (context) => PrayerCubit(
                    prayerTimesService: PrayerTimesService(),
                    notificationService: context
                        .read<PrayerNotificationService>(),
                    settingsCubit: context.read<SettingsCubit>(),
                  ),
                  child: const PrayerPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PrayerSettingsPage(),
                  ),
                  GoRoute(
                    path: 'qibla',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final settingsState = context.read<SettingsCubit>().state;
                      final userLocation = settingsState is SettingsLoaded
                          ? settingsState.settings.location
                          : null;
                      return BlocProvider(
                        create: (context) =>
                            QiblaCubit(userLocation: userLocation),
                        child: const QiblaPage(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMoreKey,
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'downloads',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const ContentDownloadsPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'quiz',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => BlocProvider(
                      create: (context) => QuizHomeCubit(),
                      child: const QuizHomePage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Quiz game route (outside shell)
      GoRoute(
        path: '/quiz',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (context) => QuizHomeCubit(),
          child: const QuizHomePage(),
        ),
        routes: [
          GoRoute(
            path: 'game',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final categoryId = extra?['categoryId'] as String? ?? 'general';
              final mode = extra?['mode'] as QuizMode? ?? QuizMode.quick;

              // Get user ID if authenticated
              final authState = context.read<AuthCubit>().state;
              String? userId;
              if (authState is AuthAuthenticated) {
                userId = authState.user.uid;
              }

              return BlocProvider(
                create: (context) => QuizGameCubit(
                  categoryId: categoryId,
                  mode: mode,
                  userId: userId,
                ),
                child: const QuizGamePage(),
              );
            },
          ),
          GoRoute(
            path: 'result',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final result = state.extra as QuizResult?;
              if (result == null) {
                return const Scaffold(
                  body: Center(child: Text('No result data')),
                );
              }
              return QuizResultPage(result: result);
            },
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class MainWrapperGoRouter extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperGoRouter({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
