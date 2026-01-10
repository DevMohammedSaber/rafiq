import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/theme_cubit.dart';
import '../profile/presentation/cubit/settings_cubit.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("settings.title".tr())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // General
          Text(
            "settings.general".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text("settings.notifications".tr()),
                  trailing: Switch(value: true, onChanged: (val) {}),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text("settings.language".tr()),
                  subtitle: Text(
                    context.locale.languageCode == 'ar' ? 'العربية' : 'English',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLanguageSheet(context);
                  },
                ),
                const Divider(height: 1),
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    final isDark = state.themeMode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                      ),
                      title: Text("settings.dark_mode".tr()),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          context.read<ThemeCubit>().toggleTheme(val);
                        },
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    if (state is SettingsLoaded) {
                      return ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text("hadith.settings_tashkeel".tr()),
                        trailing: Switch(
                          value: state.settings.hadithWithTashkeel,
                          onChanged: (val) {
                            _showTashkeelConfirm(context, val);
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text(
            "settings.about".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text("settings.about_app_title".tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text("settings.privacy_policy".tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              "${"settings.version".tr()} 1.0.0",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showTashkeelConfirm(BuildContext context, bool value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("hadith.reimport_confirm_title".tr()),
        content: Text("hadith.reimport_confirm_body".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final cubit = context.read<SettingsCubit>();
              if (cubit.state is SettingsLoaded) {
                final current = (cubit.state as SettingsLoaded).settings;
                cubit.saveSettings(current.copyWith(hadithWithTashkeel: value));
                // Navigate to hadith for re-import
                context.push('/hadith');
              }
            },
            child: Text("common.continue".tr()),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "settings.language".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("English"),
                onTap: () {
                  context.setLocale(const Locale('en'));
                  final cubit = context.read<SettingsCubit>();
                  if (cubit.state is SettingsLoaded) {
                    final current = (cubit.state as SettingsLoaded).settings;
                    cubit.saveSettings(current.copyWith(languageCode: 'en'));
                  }
                  Navigator.pop(context);
                },
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              ListTile(
                title: const Text("العربية"),
                onTap: () {
                  context.setLocale(const Locale('ar'));
                  final cubit = context.read<SettingsCubit>();
                  if (cubit.state is SettingsLoaded) {
                    final current = (cubit.state as SettingsLoaded).settings;
                    cubit.saveSettings(current.copyWith(languageCode: 'ar'));
                  }
                  Navigator.pop(context);
                },
                trailing: context.locale.languageCode == 'ar'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
