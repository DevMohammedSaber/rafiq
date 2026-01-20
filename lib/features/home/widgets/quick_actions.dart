import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart'; // Import easy_localization
import '../../../core/theme/app_colors.dart';
import '../../../core/components/app_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'nav.quran'.tr(), // "Quran"
        'icon': FontAwesomeIcons.bookOpen,
        'color': AppColors.primary,
        'route': '/quran',
        'isTab': true,
      },
      {
        'label': 'nav.azkar'.tr(), // "Azkar"
        'icon': FontAwesomeIcons.handsPraying,
        'color': AppColors.accent,
        'route': '/azkar',
        'isTab': true,
      },
      {
        'label': 'home.hadith'.tr(), // "Hadith"
        'icon': FontAwesomeIcons.scroll,
        'color': Colors.indigo,
        'route': '/hadith',
        'isTab': false,
      },
      {
        'label': 'home.tasbih'.tr(), // "Tasbeeh"
        'icon': FontAwesomeIcons.handsHoldingCircle,
        'color': Colors.purple,
        'route': '/tasbeeh',
        'isTab': false,
      },
      // {
      //   'label': 'quiz.title'.tr(), // "Quiz"
      //   'icon': FontAwesomeIcons.gamepad,
      //   'color': Colors.deepOrange,
      //   'route': '/quiz',
      //   'isTab': false,
      // },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return AppCard(
          padding: EdgeInsets.zero,
          onTap: () {
            final route = action['route'] as String;
            final isTab = action['isTab'] as bool;
            if (isTab) {
              context.go(route);
            } else {
              context.push(route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  action['label'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
