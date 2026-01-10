import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/models/azkar_category.dart';
import '../domain/models/zikr.dart';

class AzkarRepository {
  static const String _categoriesPath = 'assets/source/azkar/categories.json';
  static const String _morningPath = 'assets/source/azkar/azkar_sabah.json';
  static const String _eveningPath = 'assets/source/azkar/azkar_massa.json';
  static const String _afterPrayerPath =
      'assets/source/azkar/PostPrayer_azkar.json';
  static const String _generalPath = 'assets/source/azkar/azkar.json';
  static const String _hisnAlmuslimPath =
      'assets/source/azkar/hisn_almuslim.json';

  List<AZkarCategory>? _cachedCategories;
  final Map<String, List<Zikr>> _cachedZikr = {};

  Future<List<AZkarCategory>> loadCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final jsonString = await rootBundle.loadString(_categoriesPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedCategories = jsonList
          .map((e) => AZkarCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedCategories!;
    } catch (e) {
      // Try alternative path if the first one fails
      try {
        const altPath = 'assets/azkar/categories.json';
        final jsonString = await rootBundle.loadString(altPath);
        final List<dynamic> jsonList = json.decode(jsonString);
        _cachedCategories = jsonList
            .map((e) => AZkarCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedCategories!;
      } catch (e2) {
        throw Exception(
          'Failed to load azkar categories: $e (also tried alternative path: $e2)',
        );
      }
    }
  }

  Future<List<Zikr>> loadZikrByCategory(String categoryId) async {
    if (_cachedZikr.containsKey(categoryId)) {
      return _cachedZikr[categoryId]!;
    }

    try {
      List<Zikr> categoryZikr = [];

      switch (categoryId) {
        case 'morning':
          categoryZikr = await _loadFromSabahFile();
          break;
        case 'evening':
          categoryZikr = await _loadFromMassaFile();
          break;
        case 'after_prayer':
          categoryZikr = await _loadFromPostPrayerFile();
          break;
        case 'general':
          categoryZikr = await _loadFromGeneralFile();
          break;
        case 'sleep':
          categoryZikr = await _loadSleepZikr();
          break;
        case 'hisn_almuslim':
          categoryZikr = await _loadFromHisnAlmuslimFile();
          break;
        default:
          categoryZikr = [];
      }

      _cachedZikr[categoryId] = categoryZikr;
      return categoryZikr;
    } catch (e) {
      throw Exception('Failed to load zikr for category $categoryId: $e');
    }
  }

  Future<List<Zikr>> _loadFromSabahFile() async {
    try {
      final jsonString = await rootBundle.loadString(_morningPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final content = jsonData['content'];
      if (content == null || content is! List) {
        throw Exception('Invalid format: content is not a list');
      }
      final List<dynamic> contentList = content;

      List<Zikr> zikrList = [];
      for (int i = 0; i < contentList.length; i++) {
        final item = contentList[i] as Map<String, dynamic>;
        final zekr = item['zekr'] as String? ?? '';
        final repeat = (item['repeat'] as num?)?.toInt() ?? 1;
        final bless = item['bless'] as String? ?? '';

        final title = _extractTitle(zekr);
        final source = bless.isNotEmpty ? bless : null;

        zikrList.add(
          Zikr(
            id: 'morning_${i + 1}',
            categoryId: 'morning',
            titleAr: title,
            titleEn: 'Morning Remembrance ${i + 1}',
            textAr: zekr,
            textEn: '',
            repeat: repeat,
            sourceAr: source,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      throw Exception('Failed to load morning azkar from $_morningPath: $e');
    }
  }

  Future<List<Zikr>> _loadFromMassaFile() async {
    try {
      final jsonString = await rootBundle.loadString(_eveningPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final content = jsonData['content'];
      if (content == null || content is! List) {
        throw Exception('Invalid format: content is not a list');
      }
      final List<dynamic> contentList = content;

      List<Zikr> zikrList = [];
      for (int i = 0; i < contentList.length; i++) {
        final item = contentList[i] as Map<String, dynamic>;
        final zekr = item['zekr'] as String? ?? '';
        final repeat = (item['repeat'] as num?)?.toInt() ?? 1;
        final bless = item['bless'] as String? ?? '';

        final title = _extractTitle(zekr);
        final source = bless.isNotEmpty ? bless : null;

        zikrList.add(
          Zikr(
            id: 'evening_${i + 1}',
            categoryId: 'evening',
            titleAr: title,
            titleEn: 'Evening Remembrance ${i + 1}',
            textAr: zekr,
            textEn: '',
            repeat: repeat,
            sourceAr: source,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      throw Exception('Failed to load evening azkar from $_eveningPath: $e');
    }
  }

  Future<List<Zikr>> _loadFromPostPrayerFile() async {
    try {
      final jsonString = await rootBundle.loadString(_afterPrayerPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final content = jsonData['content'];
      if (content == null || content is! List) {
        throw Exception('Invalid format: content is not a list');
      }
      final List<dynamic> contentList = content;

      List<Zikr> zikrList = [];
      for (int i = 0; i < contentList.length; i++) {
        final item = contentList[i] as Map<String, dynamic>;
        final zekr = item['zekr'] as String? ?? '';
        final repeat = (item['repeat'] as num?)?.toInt() ?? 1;
        final bless = item['bless'] as String? ?? '';

        final title = _extractTitle(zekr);
        final source = bless.isNotEmpty ? bless : null;

        zikrList.add(
          Zikr(
            id: 'after_prayer_${i + 1}',
            categoryId: 'after_prayer',
            titleAr: title,
            titleEn: 'After Prayer Remembrance ${i + 1}',
            textAr: zekr,
            textEn: '',
            repeat: repeat,
            sourceAr: source,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      throw Exception(
        'Failed to load after prayer azkar from $_afterPrayerPath: $e',
      );
    }
  }

  Future<List<Zikr>> _loadFromGeneralFile() async {
    try {
      final jsonString = await rootBundle.loadString(_generalPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      List<Zikr> zikrList = [];
      for (int i = 0; i < jsonList.length; i++) {
        final item = jsonList[i] as Map<String, dynamic>;
        final content = item['content'] as String? ?? '';
        final count = (item['count'] as num?)?.toInt() ?? 1;
        final fadl = item['fadl'] as String? ?? '';
        final source = item['source'] as String? ?? '';

        final title = _extractTitle(content);
        final sourceText = source.isNotEmpty
            ? source
            : (fadl.isNotEmpty ? fadl : null);

        zikrList.add(
          Zikr(
            id: 'general_${i + 1}',
            categoryId: 'general',
            titleAr: title,
            titleEn: 'General Remembrance ${i + 1}',
            textAr: content,
            textEn: '',
            repeat: count,
            sourceAr: sourceText,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      return [];
    }
  }

  Future<List<Zikr>> _loadSleepZikr() async {
    try {
      final jsonString = await rootBundle.loadString(_generalPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      List<Zikr> sleepZikr = [];
      int sleepIndex = 0;

      for (int i = 0; i < jsonList.length; i++) {
        final item = jsonList[i] as Map<String, dynamic>;
        final type = (item['type'] as num?)?.toInt() ?? 0;

        if (type == 2) {
          final content = item['content'] as String? ?? '';
          final count = (item['count'] as num?)?.toInt() ?? 1;
          final fadl = item['fadl'] as String? ?? '';
          final source = item['source'] as String? ?? '';

          final title = _extractTitle(content);
          final sourceText = source.isNotEmpty
              ? source
              : (fadl.isNotEmpty ? fadl : null);

          sleepZikr.add(
            Zikr(
              id: 'sleep_${sleepIndex + 1}',
              categoryId: 'sleep',
              titleAr: title,
              titleEn: 'Sleep Remembrance ${sleepIndex + 1}',
              textAr: content,
              textEn: '',
              repeat: count,
              sourceAr: sourceText,
              sourceEn: null,
            ),
          );
          sleepIndex++;
        }
      }

      if (sleepZikr.isEmpty) {
        sleepZikr.addAll([
          Zikr(
            id: 'sleep_1',
            categoryId: 'sleep',
            titleAr: 'المعوذات قبل النوم',
            titleEn: 'Seeking Refuge Before Sleep',
            textAr:
                'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيم قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ. بِسْمِ اللهِ الرَّحْمنِ الرَّحِيم قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ. بِسْمِ اللهِ الرَّحْمنِ الرَّحِيم قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ',
            textEn: '',
            repeat: 3,
            sourceAr: 'البخاري ومسلم',
            sourceEn: null,
          ),
        ]);
      }

      return sleepZikr;
    } catch (e) {
      throw Exception('Failed to load sleep azkar from $_generalPath: $e');
    }
  }

  Future<List<Zikr>> _loadFromHisnAlmuslimFile() async {
    try {
      final jsonString = await rootBundle.loadString(_hisnAlmuslimPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Zikr> zikrList = [];
      int globalIndex = 0;

      jsonData.forEach((sectionName, sectionData) {
        final section = sectionData as Map<String, dynamic>;
        final textList = section['text'] as List<dynamic>? ?? [];
        final footnoteList = section['footnote'] as List<dynamic>? ?? [];

        for (int i = 0; i < textList.length; i++) {
          final text = textList[i] as String? ?? '';
          if (text.trim().isEmpty) continue;

          final extractedTitle = _extractTitle(text);
          final titleAr = extractedTitle.length > 60
              ? '${extractedTitle.substring(0, 60)}...'
              : extractedTitle;

          String? source;
          // Match footnote to text item by index
          if (footnoteList.isNotEmpty) {
            if (i < footnoteList.length) {
              final footnote = footnoteList[i].toString().trim();
              if (footnote.isNotEmpty) {
                source = footnote;
                if (source.length > 150) {
                  source = '${source.substring(0, 150)}...';
                }
              }
            } else if (footnoteList.length == 1 && textList.length > 1) {
              // If there's only one footnote for multiple texts, use it for all
              final footnote = footnoteList[0].toString().trim();
              if (footnote.isNotEmpty) {
                source = footnote;
                if (source.length > 150) {
                  source = '${source.substring(0, 150)}...';
                }
              }
            }
          }

          zikrList.add(
            Zikr(
              id: 'hisn_almuslim_${globalIndex + 1}',
              categoryId: 'hisn_almuslim',
              titleAr: titleAr,
              titleEn: 'Fortress of the Muslim ${globalIndex + 1}',
              textAr: text,
              textEn: '',
              repeat: 1,
              sourceAr: source,
              sourceEn: null,
            ),
          );
          globalIndex++;
        }
      });

      return zikrList;
    } catch (e) {
      throw Exception(
        'Failed to load hisn almuslim from $_hisnAlmuslimPath: $e',
      );
    }
  }

  String _extractTitle(String text) {
    if (text.isEmpty) return 'ذكر';

    String cleaned = text.trim();

    // Remove common prefixes and clean up
    cleaned = cleaned.replaceAll(RegExp(r'^قال\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^وقال\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^وعن\s+'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'^قال\s+رسول\s+الله\s+صلى\s+الله\s+عليه\s+وسلم\s*'),
      '',
    );

    // Remove curly braces and their content (Quran verses)
    cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*\}'), '');

    // Remove asterisks and their following text (footnote markers)
    cleaned = cleaned.replaceAll(RegExp(r'\*[^*]*'), '');

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Take first line or first 50 characters
    final lines = cleaned.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.isEmpty && lines.length > 1) {
        return lines[1].trim().length > 50
            ? '${lines[1].trim().substring(0, 50)}...'
            : lines[1].trim();
      }
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 50)}...';
      }
      return firstLine.isEmpty ? 'ذكر' : firstLine;
    }

    if (cleaned.length > 50) {
      return '${cleaned.substring(0, 50)}...';
    }
    return cleaned.isEmpty ? 'ذكر' : cleaned;
  }

  Future<Zikr?> getZikrById(String zikrId) async {
    try {
      final parts = zikrId.split('_');
      if (parts.length < 2) return null;

      final categoryId = parts[0];
      final zikrList = await loadZikrByCategory(categoryId);

      try {
        return zikrList.firstWhere((zikr) => zikr.id == zikrId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cachedCategories = null;
    _cachedZikr.clear();
  }
}
