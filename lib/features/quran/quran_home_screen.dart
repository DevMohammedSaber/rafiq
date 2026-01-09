import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'quran_reader_screen.dart';

class QuranHomeScreen extends StatelessWidget {
  const QuranHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("The Holy Quran"),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastReadCard(context),
                  const SizedBox(height: 24),
                  Text(
                    "Surahs",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final surah = _mockSurahs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  surah['englishName']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "${surah['revelationType']} • ${surah['ayahs']} Ayahs",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  surah['arabicName']!,
                  style: const TextStyle(
                    fontFamily: 'Cairo', // Ensure Arabic font
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuranReaderScreen(surahName: surah['englishName']!),
                    ),
                  );
                },
              );
            }, childCount: _mockSurahs.length),
          ),
        ],
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            "https://www.transparenttextures.com/patterns/arabesque.png",
          ), // Subtle pattern
          opacity: 0.1,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Last Read",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Al-Kahf",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ayah No: 10",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _mockSurahs = [
    {
      'englishName': 'Al-Fatiha',
      'arabicName': 'الفاتحة',
      'revelationType': 'Meccan',
      'ayahs': 7,
    },
    {
      'englishName': 'Al-Baqarah',
      'arabicName': 'البقرة',
      'revelationType': 'Medinan',
      'ayahs': 286,
    },
    {
      'englishName': 'Al-Imran',
      'arabicName': 'آل عمران',
      'revelationType': 'Medinan',
      'ayahs': 200,
    },
    {
      'englishName': 'An-Nisa',
      'arabicName': 'النساء',
      'revelationType': 'Medinan',
      'ayahs': 176,
    },
    {
      'englishName': 'Al-Ma\'idah',
      'arabicName': 'المائدة',
      'revelationType': 'Medinan',
      'ayahs': 120,
    },
    {
      'englishName': 'Al-An\'am',
      'arabicName': 'الأنعام',
      'revelationType': 'Meccan',
      'ayahs': 165,
    },
    {
      'englishName': 'Al-A\'raf',
      'arabicName': 'الأعراف',
      'revelationType': 'Meccan',
      'ayahs': 206,
    },
  ];
}
