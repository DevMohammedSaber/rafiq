import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/app_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// User Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr()), centerTitle: true),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSignedOut) {
            // Trigger sign out in auth cubit and navigate to login
            context.read<AuthCubit>().signOut();
            context.go('/login');
          } else if (state is ProfileDeleted) {
            // Account deleted, navigate to login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.account_deleted'.tr()),
                backgroundColor: AppColors.primary,
              ),
            );
            context.go('/login');
          } else if (state is ProfileError) {
            if (state.message == 'requires-recent-login') {
              _showReloginRequiredDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } else if (state is ProfileSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message.tr()),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = context.read<ProfileCubit>().currentProfile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text('errors.generic'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().load(),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          return _buildProfileContent(context, profile, state);
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    dynamic profile,
    ProfileState state,
  ) {
    final isSaving = state is ProfileSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context, profile),

          const SizedBox(height: 24),

          // Guest banner
          if (profile.isGuest) _buildGuestBanner(context),

          const SizedBox(height: 16),

          // Account Section
          _buildSectionTitle(context, 'profile.account'.tr()),
          const SizedBox(height: 8),
          _buildAccountSection(context, profile, isSaving),

          const SizedBox(height: 24),

          // App Section
          _buildSectionTitle(context, 'profile.app'.tr()),
          const SizedBox(height: 8),
          _buildAppSection(context),

          const SizedBox(height: 24),

          // Legal Section
          _buildSectionTitle(context, 'profile.legal'.tr()),
          const SizedBox(height: 8),
          _buildLegalSection(context),

          const SizedBox(height: 24),

          // Danger Zone (for auth users)
          if (!profile.isGuest) ...[
            _buildSectionTitle(
              context,
              'profile.danger_zone'.tr(),
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            _buildDangerSection(context, isSaving),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic profile) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profile.avatarUrl),
                  ),
                ),
                // Account type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: profile.isGuest ? Colors.orange : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile.isGuest
                        ? 'profile.guest'.tr()
                        : 'profile.signed_in'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              profile.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            // Email
            if (profile.email != null) ...[
              const SizedBox(height: 4),
              Text(
                profile.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],

            // Provider and join date
            if (!profile.isGuest && profile.provider != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    profile.provider == 'google'
                        ? Icons.g_mobiledata
                        : Icons.apple,
                    size: 18,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile.providerDisplayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  if (profile.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '|',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'profile.joined'.tr(
                        args: [DateFormat.yMMMd().format(profile.createdAt!)],
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_sync_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.upgrade_title'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'profile.upgrade_body'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text('profile.upgrade_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Color? color,
  }) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    dynamic profile,
    bool isSaving,
  ) {
    return AppCard(
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.edit_outlined,
            title: 'profile.edit'.tr(),
            onTap: isSaving ? null : () => context.push('/profile/edit'),
          ),
          if (profile.isGuest)
            _buildMenuTile(
              context,
              icon: Icons.login,
              title: 'profile.upgrade_button'.tr(),
              onTap: isSaving ? null : () => context.push('/login'),
              iconColor: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.settings_outlined,
            title: 'profile.settings'.tr(),
            onTap: () => context.push('/more/settings'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'profile.notifications'.tr(),
            onTap: () => context.push('/prayers/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'profile.privacy'.tr(),
            onTap: () => _showComingSoonSnackbar(context),
          ),
          _buildMenuTile(
            context,
            icon: Icons.description_outlined,
            title: 'profile.terms'.tr(),
            onTap: () => _showComingSoonSnackbar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context, bool isSaving) {
    return AppCard(
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: 'profile.sign_out'.tr(),
            iconColor: Colors.orange,
            onTap: isSaving ? null : () => _showSignOutConfirmation(context),
          ),
          _buildMenuTile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'profile.delete_account'.tr(),
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: isSaving ? null : () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).hintColor,
      ),
      onTap: onTap,
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.sign_out'.tr()),
        content: Text('profile.sign_out_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().signOut();
            },
            child: Text('profile.sign_out'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.delete_confirm_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('profile.delete_confirm_body'.tr()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'profile.delete_warning'.tr(),
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().deleteAccount();
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showReloginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.relogin_required_title'.tr()),
        content: Text('profile.relogin_required_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              context.go('/login');
            },
            child: Text('profile.sign_out'.tr()),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('common.coming_soon'.tr())));
  }
}
