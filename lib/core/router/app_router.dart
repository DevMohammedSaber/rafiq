import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
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
  final AuthCubit authCubit;

  AppRouter(this.authCubit);

  late final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final bool isAuthenticated =
          authState is AuthAuthenticated || authState is AuthGuest;
      final bool isUnauthenticated = authState is AuthUnauthenticated;

      // If we are at root or login, check auth
      final bool onLoginPage = state.fullPath == '/login';

      // If Unauthenticated and not on Login/Onboarding -> Redirect to Login
      // NOTE: We allow Onboarding to be the "public" face if desired, but here prompt asked:
      // "If AuthUnauthenticated -> redirect to /login"
      // Assuming Onboarding is done? Or maybe Onboarding leads to Login?
      // Let's assume: If Unauthenticated -> Login.
      // EXCEPT: If we are just starting, we might show Onboarding first?
      // Per prompt: "/login /home".
      // Let's keep Onboarding accessible or redirect?
      // Better flow: Unauth -> Login (which has Guest).

      if (isUnauthenticated) {
        return '/login';
      }

      // If Authenticated and on Login -> Redirect to Home
      if (isAuthenticated && onLoginPage) {
        return '/home';
      }

      // Default: null (no redirect)
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
        // Typically Onboarding checks if "seen" in shared_prefs.
        // For now, let's assume root goes to Onboarding, then user clicks "Get Started" -> Login?
        // Or if Authenticated, redirect will take them to Home instantly if logic above covers /.
        // NOTE: The redirect above works on ALL routes. If Authenticated, it allows /.
        // But we want Authenticated -> Home.
        // Let's fix redirect logic for root:
        redirect: (context, state) {
          final authState = authCubit.state;
          if (authState is AuthAuthenticated || authState is AuthGuest) {
            return '/home';
          }
          return null; // stay on onboarding if unauth? Or go to Login?
          // If we want to force Login: "/login"
        },
      ),
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
                    parentNavigatorKey: _rootNavigatorKey,
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

// Stream wrapper for GoRouter refresh
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
