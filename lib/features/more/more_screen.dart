import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../auth/presentation/cubit/auth_cubit.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("nav.more".tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                String displayName = 'profile.guest'.tr();
                String subtitle = 'profile.upgrade_title'.tr();
                String? photoUrl;
                bool isGuest = true;

                if (authState is AuthAuthenticated) {
                  displayName = authState.user.displayName ?? 'User';
                  subtitle = authState.user.email ?? '';
                  photoUrl = authState.user.photoURL;
                  isGuest = false;
                }

                final avatarUrl = (photoUrl != null && photoUrl.isNotEmpty)
                    ? photoUrl
                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=fff&color=006D5B';

                return AppCard(
                  color: AppColors.primary,
                  onTap: () => context.push('/profile'),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGuest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'profile.guest'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Grid Menu
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  "home.hadith".tr(),
                  FontAwesomeIcons.scroll,
                  Colors.indigo,
                  () => context.push('/hadith'),
                ),
                _buildMenuCard(
                  context,
                  "home.quiz".tr(),
                  FontAwesomeIcons.brain,
                  Colors.orange,
                  () => context.push('/more/quiz'),
                ),
                _buildMenuCard(
                  context,
                  "onboarding.title3".tr(),
                  FontAwesomeIcons.compass,
                  Colors.teal,
                  () => context.push('/prayers/qibla'),
                ),
                _buildMenuCard(
                  context,
                  "home.tasbih".tr(),
                  FontAwesomeIcons.handsHoldingCircle,
                  Colors.purple,
                  () => context.push('/tasbeeh'),
                ),
                _buildMenuCard(
                  context,
                  "nav.prayers".tr(),
                  Icons.access_time_filled_rounded,
                  AppColors.primary,
                  () => context.go('/prayers'),
                ),
                _buildMenuCard(
                  context,
                  "settings.title".tr(),
                  Icons.settings,
                  Colors.grey,
                  () => context.push('/more/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
