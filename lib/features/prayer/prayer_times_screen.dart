import 'package:flutter/material.dart';
import '../../core/components/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'prayer_settings_screen.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prayer Times"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Date Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                ),
                Column(
                  children: [
                    Text(
                      "Friday, 8 Sep 2023",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "23 Safar 1445",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prayers List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockPrayers.length,
              itemBuilder: (context, index) {
                final prayer = _mockPrayers[index];
                final isNext = prayer['isNext'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    color: isNext ? AppColors.primary : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                prayer['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: isNext ? Colors.white : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (isNext) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Next",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          prayer['time'] as String,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: isNext ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.notifications_active_outlined, // Mock state
                          color: isNext
                              ? Colors.white70
                              : Theme.of(context).disabledColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _mockPrayers = [
    {'name': 'Fajr', 'time': '04:50 AM', 'isNext': false},
    {'name': 'Sunrise', 'time': '06:15 AM', 'isNext': false},
    {'name': 'Dhuhr', 'time': '12:05 PM', 'isNext': false},
    {'name': 'Asr', 'time': '03:45 PM', 'isNext': true},
    {'name': 'Maghrib', 'time': '06:10 PM', 'isNext': false},
    {'name': 'Isha', 'time': '07:40 PM', 'isNext': false},
  ];
}
