import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rafiq/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/profile/data/user_profile_repository.dart';
import 'features/profile/presentation/cubit/settings_cubit.dart';
import 'features/prayer/data/prayer_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Repositories & Services
  final authRepository = AuthRepository();
  final userProfileRepository = UserProfileRepository();
  final prayerNotificationService = PrayerNotificationService();

  // Init Services
  await prayerNotificationService.init();

  // Cubits
  final authCubit = AuthCubit(authRepository);
  await authCubit.init();

  final settingsCubit = SettingsCubit(
    userProfileRepository,
    prayerNotificationService,
  );
  await settingsCubit.loadSettings();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MuslimCompanionApp(
        authRepository: authRepository,
        userProfileRepository: userProfileRepository,
        authCubit: authCubit,
        settingsCubit: settingsCubit,
        prayerNotificationService: prayerNotificationService,
      ),
    ),
  );
}

class MuslimCompanionApp extends StatefulWidget {
  final AuthRepository authRepository;
  final UserProfileRepository userProfileRepository;
  final AuthCubit authCubit;
  final SettingsCubit settingsCubit;
  final PrayerNotificationService prayerNotificationService;

  const MuslimCompanionApp({
    super.key,
    required this.authRepository,
    required this.userProfileRepository,
    required this.authCubit,
    required this.settingsCubit,
    required this.prayerNotificationService,
  });

  @override
  State<MuslimCompanionApp> createState() => _MuslimCompanionAppState();
}

class _MuslimCompanionAppState extends State<MuslimCompanionApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Create router once and reuse it to avoid duplicate GlobalKeys
    _appRouter = AppRouter(widget.authCubit, widget.settingsCubit);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.userProfileRepository),
        RepositoryProvider.value(value: widget.prayerNotificationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider.value(value: widget.authCubit),
          BlocProvider.value(value: widget.settingsCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              onGenerateTitle: (context) => "app_title".tr(),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: _appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
