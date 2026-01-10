import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/app_colors.dart';

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
            // Profile Card (Optional)
            AppCard(
              color: AppColors.primary,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://ui-avatars.com/api/?name=Mohamed+Saber&background=fff&color=006D5B",
                  ),
                ),
                title: const Text(
                  "Mohamed Saber",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Cairo, Egypt",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {},
                ),
              ),
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
                  "onboarding.title3".tr(), // Qibla
                  FontAwesomeIcons.compass,
                  Colors.teal,
                  () {}, // Placeholder
                ),
                _buildMenuCard(
                  context,
                  "home.tasbih".tr(),
                  FontAwesomeIcons.handsHoldingCircle,
                  Colors.purple,
                  () {}, // Placeholder
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
