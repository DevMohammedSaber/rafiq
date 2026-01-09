import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/location_permission_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quran/quran_home_screen.dart';
import '../../features/adhkar/adhkar_home_screen.dart';
import '../../features/prayer/prayer_times_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/quran/quran_reader_screen.dart';
import '../../features/adhkar/dhikr_counter_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/hadith/hadith_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../core/components/bottom_nav_bar.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorQuranKey = GlobalKey<NavigatorState>(debugLabel: 'quran');
final _shellNavigatorAdhkarKey = GlobalKey<NavigatorState>(
  debugLabel: 'adhkar',
);
final _shellNavigatorPrayerKey = GlobalKey<NavigatorState>(
  debugLabel: 'prayer',
);
final _shellNavigatorMoreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
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
                builder: (context, state) => const QuranHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'reader',
                    parentNavigatorKey: _rootNavigatorKey, // Push full screen
                    builder: (context, state) {
                      final surahName = state.extra as String? ?? 'Surah';
                      return QuranReaderScreen(surahName: surahName);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAdhkarKey,
            routes: [
              GoRoute(
                path: '/adhkar',
                builder: (context, state) => const AdhkarHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'counter',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final title = state.extra as String? ?? 'Dhikr';
                      return DhikrCounterScreen(categoryTitle: title);
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

// Wrapper to interface with the existing MainBottomNavBar
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
