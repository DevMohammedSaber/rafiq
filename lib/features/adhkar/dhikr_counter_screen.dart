import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_colors.dart';

class DhikrCounterScreen extends StatefulWidget {
  final String categoryTitle;

  const DhikrCounterScreen({super.key, required this.categoryTitle});

  @override
  State<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends State<DhikrCounterScreen> {
  int _count = 0;
  final int _target = 33;
  int _currentIndex = 0;

  final List<String> _adhkar = [
    "Subhan Allah",
    "Alhamdulillah",
    "Allahu Akbar",
  ];

  void _increment() {
    setState(() {
      if (_count < _target) {
        _count++;
      } else {
        // Complete current dhikr, move to next or cycle
        if (_currentIndex < _adhkar.length - 1) {
          _currentIndex++;
          _count = 0;
        } else {
          // Finished all
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("All Adhkar Completed!")),
          );
          _count = 0;
          _currentIndex = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              _adhkar[_currentIndex],
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Read $_target times",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const Spacer(),

            // Counter Button
            GestureDetector(
              onTap: _increment,
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: _count / _target,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_count",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text("Tap"),
                  ],
                ),
                progressColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
              ),
            ),
            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() => _count = 0);
                    },
                    icon: const Icon(Icons.refresh, size: 30),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate next manual
                      if (_currentIndex < _adhkar.length - 1) {
                        setState(() {
                          _currentIndex++;
                          _count = 0;
                        });
                      }
                    },
                    icon: const Icon(Icons.skip_next, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
