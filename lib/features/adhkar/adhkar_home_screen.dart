import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/app_colors.dart';

class AdhkarHomeScreen extends StatelessWidget {
  const AdhkarHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("nav.adhkar".tr())),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return AppCard(
            padding: const EdgeInsets.all(16),
            onTap: () {
              context.push('/adhkar/counter', extra: cat['title']);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cat['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const List<Map<String, dynamic>> _categories = [
    {
      'title': 'Morning',
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.orange,
    },
    {
      'title': 'Evening',
      'icon': Icons.nights_stay_rounded,
      'color': Colors.indigo,
    },
    {'title': 'Sleep', 'icon': FontAwesomeIcons.bed, 'color': Colors.purple},
    {
      'title': 'Prayer',
      'icon': FontAwesomeIcons.handsPraying,
      'color': AppColors.primary,
    },
    {
      'title': 'Travel',
      'icon': Icons.flight_takeoff_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Quran',
      'icon': FontAwesomeIcons.bookOpen,
      'color': AppColors.accent,
    },
  ];
}
