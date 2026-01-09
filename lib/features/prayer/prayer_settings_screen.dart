import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/components/app_card.dart';

class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("prayer.settings.title".tr())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, "prayer.settings.location_header".tr()),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  title: Text("prayer.settings.location".tr()),
                  subtitle: const Text("Cairo, Egypt"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  title: Text("prayer.settings.auto_location".tr()),
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            "prayer.settings.calculation_header".tr(),
          ),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  title: Text("prayer.settings.calculation_authority".tr()),
                  subtitle: Text("prayer.settings.egyptian_authority".tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text("prayer.settings.asr_calculation".tr()),
                  subtitle: Text("prayer.settings.asr_standard".tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            "prayer.settings.adjustments_header".tr(),
          ),
          AppCard(
            child: ListTile(
              title: Text("prayer.settings.manual_adjustments".tr()),
              subtitle: Text("prayer.settings.manual_adjustments_desc".tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
