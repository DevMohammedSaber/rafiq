import 'package:sqflite/sqflite.dart';
import 'quran_database_cdn.dart';
import '../domain/models/surah.dart';
import '../domain/models/ayah.dart';
import '../../../core/utils/arabic_normalizer.dart';

class QuranRepository {
  Future<Database> getDb() async => QuranDatabaseCdn.instance.database;

  Future<List<Surah>> loadSurahs() async {
    final db = await QuranDatabaseCdn.instance.database;
    final result = await db.query('quran_surahs', orderBy: 'surah ASC');
    return result.map((e) => _mapToSurah(e)).toList();
  }

  Future<List<Ayah>> loadAyahs(int surahId) async {
    final db = await QuranDatabaseCdn.instance.database;
    final result = await db.query(
      'quran_ayahs',
      where: 'surah = ?',
      whereArgs: [surahId],
      orderBy: 'ayah ASC',
    );
    return result.map((e) => _mapToAyah(e)).toList();
  }

  Future<Surah?> getSurahById(int surahId) async {
    final db = await QuranDatabaseCdn.instance.database;
    final result = await db.query(
      'quran_surahs',
      where: 'surah = ?',
      whereArgs: [surahId],
    );
    if (result.isEmpty) return null;
    return _mapToSurah(result.first);
  }

  Future<List<Surah>> searchSurahs(String query) async {
    final db = await QuranDatabaseCdn.instance.database;
    if (query.isEmpty) return loadSurahs();

    final result = await db.query(
      'quran_surahs',
      where: 'name_en LIKE ? OR name_ar LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'surah ASC',
    );
    return result.map((e) => _mapToSurah(e)).toList();
  }

  Future<List<Ayah>> searchAyahs(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await QuranDatabaseCdn.instance.database;
    final normalized = ArabicNormalizer.normalize(query);

    final result = await db.query(
      'quran_ayahs',
      where: 'search_text LIKE ?',
      whereArgs: ['%$normalized%'],
      limit: limit,
      offset: offset,
      orderBy: 'surah ASC, ayah ASC',
    );
    return result.map((e) => _mapToAyah(e)).toList();
  }

  Future<Ayah?> getAyah(int surahId, int ayahNumber) async {
    final db = await QuranDatabaseCdn.instance.database;
    final result = await db.query(
      'quran_ayahs',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surahId, ayahNumber],
    );
    if (result.isEmpty) return null;
    return _mapToAyah(result.first);
  }

  Surah _mapToSurah(Map<String, dynamic> row) {
    final id = row['surah'] as int;
    return Surah(
      id: id,
      index: id.toString().padLeft(3, '0'),
      nameEn: row['name_en'] as String,
      nameAr: row['name_ar'] as String,
      ayahCount: row['ayah_count'] as int,
      place: row['place'] as String,
      type: row['type'] as String,
    );
  }

  Ayah _mapToAyah(Map<String, dynamic> row) {
    return Ayah(
      surahId: row['surah'] as int,
      ayahNumber: row['ayah'] as int,
      textAr: row['text'] as String,
      page: row['page'] as int?,
    );
  }

  Future<List<Ayah>> getAyahsByPage(int page) async {
    final db = await QuranDatabaseCdn.instance.database;
    final result = await db.query(
      'quran_ayahs',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'surah ASC, ayah ASC',
    );
    return result.map((e) => _mapToAyah(e)).toList();
  }
}
