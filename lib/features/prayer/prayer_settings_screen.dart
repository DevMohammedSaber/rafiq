import 'package:flutter/material.dart';
import '../../core/components/app_card.dart';

class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prayer Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, "Location"),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Location"),
                  subtitle: const Text("Cairo, Egypt"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  title: const Text("Automatic Location"),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, "Calculation Method"),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Calculation Authority"),
                  subtitle: const Text("Egyptian General Authority of Survey"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("Asr Calculation"),
                  subtitle: const Text("Standard (Shafi, Maliki, Hanbali)"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, "Adjustments"),
          AppCard(
            child: ListTile(
              title: const Text("Manual Adjustments"),
              subtitle: const Text("Adjust prayer times by minutes"),
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
