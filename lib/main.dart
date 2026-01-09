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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // NOTE: We assume Firebase is set up. If firebase_options.dart exists:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // For now, standard init:
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepository = AuthRepository();
  final authCubit = AuthCubit(authRepository);
  await authCubit.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MuslimCompanionApp(
        authRepository: authRepository,
        authCubit: authCubit,
      ),
    ),
  );
}

class MuslimCompanionApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AuthCubit authCubit;

  const MuslimCompanionApp({
    super.key,
    required this.authRepository,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: authRepository)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider.value(value: authCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            // Rebuild router if needed or just pass it access to cubit
            final appRouter = AppRouter(authCubit);

            return MaterialApp.router(
              title: 'Muslim Companion',
              debugShowCheckedModeBanner: false,

              // Theme
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,

              // Localization
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,

              // Router
              routerConfig: appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
