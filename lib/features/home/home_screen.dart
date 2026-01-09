import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/mini_prayer_row.dart';
import 'widgets/quick_actions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/presentation/cubit/auth_cubit.dart';
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
                            backgroundImage: photoUrl != null
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

              // Continue Reading
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text("home.continue_reading".tr()),
                  subtitle: const Text("Surah Al-Kahf, Ayah 10"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
