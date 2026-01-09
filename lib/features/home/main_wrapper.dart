import 'package:flutter/material.dart';
import '../../core/components/bottom_nav_bar.dart';
import 'home_screen.dart';
import '../prayer/prayer_times_screen.dart';
import '../quran/quran_home_screen.dart';
import '../adhkar/adhkar_home_screen.dart';
import '../more/more_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranHomeScreen(),
    const AdhkarHomeScreen(),
    const PrayerTimesScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
