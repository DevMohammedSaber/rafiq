import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Theme.of(context).disabledColor,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: "nav.home".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(FontAwesomeIcons.bookOpen),
            label: "nav.quran".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(FontAwesomeIcons.handsPraying),
            label: "nav.azkar".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time_filled_rounded),
            label: "nav.prayers".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded),
            label: "nav.more".tr(),
          ),
        ],
      ),
    );
  }
}
