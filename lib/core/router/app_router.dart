import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/profile/presentation/cubit/settings_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/location_permission_screen.dart';
import '../../features/onboarding/presentation/pages/setup_page.dart';
import '../../features/home/home_screen.dart';
import '../../features/quran/presentation/pages/quran_home_page.dart';
import '../../features/quran/presentation/pages/quran_reader_page.dart';
import '../../features/quran/data/quran_repository.dart';
import '../../features/quran/data/quran_user_data_repository.dart';
import '../../features/quran/data/quran_pagination_repository.dart';
import '../../features/quran/data/mushaf_data_repository.dart';
import '../../features/quran/presentation/cubit/quran_home_cubit.dart';
import '../../features/quran/presentation/cubit/quran_reader_cubit.dart';
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
import '../../features/prayer/prayer_times_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/hadith/hadith_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../core/components/bottom_nav_bar.dart';
import '../../features/splash/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorQuranKey = GlobalKey<NavigatorState>(debugLabel: 'quran');
final _shellNavigatorAzkarKey = GlobalKey<NavigatorState>(
  debugLabel: 'azkar',
);
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
    redirect: (context, state) {
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
      final bool onHomePage =
          state.fullPath == '/home' ||
          state.fullPath?.startsWith('/home') == true ||
          state.fullPath?.startsWith('/quran') == true ||
          state.fullPath?.startsWith('/azkar') == true ||
          state.fullPath?.startsWith('/prayers') == true ||
          state.fullPath?.startsWith('/more') == true;

      final bool onSplashPage = state.fullPath == '/splash';

      // 1. Always show splash first (managed by initialLocation and Splash widget timer)
      // The Splash screen itself will navigate to '/' after animation/timer.
      // However, we need to protect other routes.

      // If we are on splash, stay there until manual navigation or logic kicks in.
      // Actually, to keep it simple with GoRouter:
      // We can let the Splash screen handle the "minimum duration".
      // When Splash calls context.go('/'), this redirect logic will run again.

      if (onSplashPage) return null;

      // If auth is still initializing, only redirect away from protected routes to splash?
      // No, let's keep it simple.

      if (isAuthInitial || isAuthLoading) {
        // If on splash, stay.
        // If on protected route, go to splash or login.
        return null;
      }

      // 1. Unauthenticated -> Login (unless already on login or onboarding)
      if (isUnauthenticated) {
        if (onLoginPage || onOnboardingPage) {
          return null;
        }
        // If on protected routes, redirect to login
        if (onHomePage || onSetupPage) {
          return '/login';
        }
        return '/login';
      }

      // 2. Authenticated - check setup status
      if (isAuthenticated) {
        // If settings are loading, allow current page but prevent onboarding/login
        if (settingsState is SettingsLoading) {
          if (onOnboardingPage || onLoginPage) {
            // Wait for settings
            return null;
          }
          return null;
        }

        // Settings loaded - check setup status
        if (settingsState is SettingsLoaded) {
          // Setup not done -> go to setup (unless already there)
          if (!settingsState.settings.setupDone) {
            if (onSetupPage) {
              return null;
            }
            return '/setup';
          }

          // Setup done -> go to home (if on login/setup/onboarding/splash)
          if (settingsState.settings.setupDone) {
            if (onLoginPage ||
                onSetupPage ||
                onOnboardingPage ||
                onSplashPage) {
              return '/home';
            }
          }
        }
      }

      // Default - no redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationPermissionScreen(),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorQuranKey,
            routes: [
              GoRoute(
                path: '/quran',
                builder: (context, state) => BlocProvider(
                  create: (context) => QuranHomeCubit(QuranRepository()),
                  child: const QuranHomePage(),
                ),
                routes: [
                  GoRoute(
                    path: ':surahId',
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

                      return BlocProvider(
                        create: (context) => QuranReaderCubit(
                          QuranRepository(),
                          QuranUserDataRepository(),
                          QuranPaginationRepository(),
                          MushafDataRepository(
                            quranRepository: QuranRepository(),
                            paginationRepository: QuranPaginationRepository(),
                          ),
                          context.read<SettingsCubit>(),
                        ),
                        child: QuranReaderPage(
                          surahId: surahId,
                          scrollToAyah: scrollToAyah,
                        ),
                      );
                    },
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
                builder: (context, state) => const PrayerTimesScreen(),
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
                  ),
                  GoRoute(
                    path: 'hadith',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HadithScreen(),
                  ),
                  GoRoute(
                    path: 'quiz',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const QuizScreen(),
                  ),
                ],
              ),
            ],
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
