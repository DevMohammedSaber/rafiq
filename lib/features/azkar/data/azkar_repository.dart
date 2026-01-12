import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../domain/models/azkar_category.dart';
import '../domain/models/zikr.dart';

class AzkarRepository {
  static const String _categoriesPath = 'assets/source/azkar/categories.csv';
  static const String _morningPath = 'assets/source/azkar/azkar_sabah.csv';
  static const String _eveningPath = 'assets/source/azkar/azkar_massa.csv';
  static const String _afterPrayerPath =
      'assets/source/azkar/PostPrayer_azkar.csv';
  static const String _generalPath = 'assets/source/azkar/azkar.csv';
  static const String _hisnAlmuslimPath =
      'assets/source/azkar/hisn_almuslim.csv';

  List<AZkarCategory>? _cachedCategories;
  final Map<String, List<Zikr>> _cachedZikr = {};

  // Cache for Hisn AlMuslim raw data
  List<List<dynamic>>? _hisnData;

  Future<List<List<dynamic>>> _parseCsv(String path) async {
    try {
      final csvString = await rootBundle.loadString(path);
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
      );
      return rows;
    } catch (e) {
      throw Exception('Failed to parse CSV at $path: $e');
    }
  }

  Future<void> _ensureHisnLoaded() async {
    if (_hisnData != null) return;
    try {
      _hisnData = await _parseCsv(_hisnAlmuslimPath);
    } catch (e) {
      throw Exception('Failed to load hisn almuslim data: $e');
    }
  }

  Future<List<AZkarCategory>> loadCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final rows = await _parseCsv(_categoriesPath);

      // Skip header row
      final dataRows = rows.skip(1).toList();

      List<AZkarCategory> categories = dataRows.map((row) {
        return AZkarCategory(
          id: row[0].toString(),
          nameAr: row[1].toString(),
          nameEn: row[2].toString(),
        );
      }).toList();

      _cachedCategories = categories;
      return _cachedCategories!;
    } catch (e) {
      throw Exception('Failed to load azkar categories: $e');
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
          categoryZikr = await _loadFromCsvFile(_morningPath, 'morning');
          break;
        case 'evening':
          categoryZikr = await _loadFromCsvFile(_eveningPath, 'evening');
          break;
        case 'after_prayer':
          categoryZikr = await _loadFromCsvFile(
            _afterPrayerPath,
            'after_prayer',
          );
          break;
        case 'general':
          categoryZikr = await _loadGeneralZikr();
          break;
        case 'sleep':
          categoryZikr = await _loadSleepZikr();
          break;
        case 'hisn_almuslim':
          categoryZikr = await _loadHisnAlmuslim();
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

  Future<List<Zikr>> _loadFromCsvFile(String path, String categoryId) async {
    try {
      final rows = await _parseCsv(path);

      // Skip header row
      final dataRows = rows.skip(1).toList();

      List<Zikr> zikrList = [];
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.isEmpty) continue;

        final zekr = row[0].toString();
        final repeat = row.length > 1
            ? int.tryParse(row[1].toString()) ?? 1
            : 1;
        final bless = row.length > 2 ? row[2].toString() : '';

        if (zekr.trim().isEmpty) continue;

        final title = _extractTitle(zekr);

        zikrList.add(
          Zikr(
            id: '${categoryId}_${i + 1}',
            categoryId: categoryId,
            titleAr: title,
            titleEn: '${_getCategoryDisplayName(categoryId)} ${i + 1}',
            textAr: zekr,
            textEn: '',
            repeat: repeat,
            sourceAr: bless.isNotEmpty ? bless : null,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      throw Exception('Failed to load azkar from $path: $e');
    }
  }

  Future<List<Zikr>> _loadGeneralZikr() async {
    try {
      final rows = await _parseCsv(_generalPath);

      // Skip header row
      final dataRows = rows.skip(1).toList();

      List<Zikr> zikrList = [];
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.isEmpty) continue;

        // General CSV format may differ - adapt as needed
        final content = row[0].toString();
        final count = row.length > 1 ? int.tryParse(row[1].toString()) ?? 1 : 1;
        final source = row.length > 2 ? row[2].toString() : '';

        if (content.trim().isEmpty) continue;

        final title = _extractTitle(content);

        zikrList.add(
          Zikr(
            id: 'general_${i + 1}',
            categoryId: 'general',
            titleAr: title,
            titleEn: 'General Remembrance ${i + 1}',
            textAr: content,
            textEn: '',
            repeat: count,
            sourceAr: source.isNotEmpty ? source : null,
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
    // Return default sleep azkar
    return [
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
      Zikr(
        id: 'sleep_2',
        categoryId: 'sleep',
        titleAr: 'دعاء النوم',
        titleEn: 'Sleep Supplication',
        textAr: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        textEn: 'In Your name, O Allah, I die and I live.',
        repeat: 1,
        sourceAr: 'البخاري',
        sourceEn: null,
      ),
      Zikr(
        id: 'sleep_3',
        categoryId: 'sleep',
        titleAr: 'دعاء الاستيقاظ',
        titleEn: 'Waking Up Supplication',
        textAr:
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        textEn:
            'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
        repeat: 1,
        sourceAr: 'البخاري',
        sourceEn: null,
      ),
      Zikr(
        id: 'sleep_4',
        categoryId: 'sleep',
        titleAr: 'آية الكرسي',
        titleEn: 'Ayat Al-Kursi',
        textAr:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        textEn: '',
        repeat: 1,
        sourceAr: 'البقرة: 255',
        sourceEn: null,
      ),
    ];
  }

  Future<List<Zikr>> _loadHisnAlmuslim() async {
    try {
      await _ensureHisnLoaded();
      if (_hisnData == null || _hisnData!.isEmpty) return [];

      // Skip header row
      final dataRows = _hisnData!.skip(1).toList();

      List<Zikr> zikrList = [];
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.isEmpty) continue;

        final text = row[0].toString();
        if (text.trim().isEmpty) continue;

        final title = _extractTitle(text);

        zikrList.add(
          Zikr(
            id: 'hisn_${i + 1}',
            categoryId: 'hisn_almuslim',
            titleAr: title,
            titleEn: 'Fortress of the Muslim ${i + 1}',
            textAr: text,
            textEn: '',
            repeat: 1,
            sourceAr: null,
            sourceEn: null,
          ),
        );
      }
      return zikrList;
    } catch (e) {
      return [];
    }
  }

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'Morning Remembrance';
      case 'evening':
        return 'Evening Remembrance';
      case 'after_prayer':
        return 'After Prayer Remembrance';
      case 'sleep':
        return 'Sleep Remembrance';
      case 'general':
        return 'General Remembrance';
      case 'hisn_almuslim':
        return 'Fortress of the Muslim';
      default:
        return 'Remembrance';
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
      // Trying to find zikr in cache
      for (var catId in _cachedZikr.keys) {
        try {
          final zikr = _cachedZikr[catId]!.firstWhere(
            (z) => z.id == zikrId,
            orElse: () => throw 'NotFound',
          );
          if (zikr.id == zikrId) return zikr;
        } catch (_) {}
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cachedCategories = null;
    _cachedZikr.clear();
    _hisnData = null;
  }
}
