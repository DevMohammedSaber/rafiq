import 'package:sqflite/sqflite.dart';
import '../../hadith/data/hadith_database_cdn.dart';
import '../domain/models/hadith_models.dart';
import '../../../core/utils/arabic_normalizer.dart';

class HadithRepository {
  Future<Database> get _db async => HadithDatabaseCdn.instance.database;

  Future<List<HadithBook>> getBooks() async {
    final db = await _db;
    final result = await db.query('hadith_books');
    return result.map((e) => _mapToBook(e)).toList();
  }

  Future<List<HadithItem>> getHadithByBook(
    String bookId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;
    final result = await db.query(
      'hadiths',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: limit,
      offset: offset,
      orderBy: 'id ASC',
    );
    return result.map((e) => _mapToHadith(e)).toList();
  }

  Future<List<HadithItem>> searchInBook(
    String bookId,
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;
    final normalizedQuery = ArabicNormalizer.normalize(query);
    final result = await db.query(
      'hadiths',
      where: 'book_id = ? AND search_text LIKE ?',
      whereArgs: [bookId, '%$normalizedQuery%'],
      limit: limit,
      offset: offset,
    );
    return result.map((e) => _mapToHadith(e)).toList();
  }

  Future<HadithItem?> getHadithByUid(String uid) async {
    final db = await _db;
    // uid is the string representation of ID
    final id = int.tryParse(uid);
    if (id == null) return null;

    final result = await db.query('hadiths', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return _mapToHadith(result.first);
  }

  Future<int> getTotalHadithCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(hadith_count) as total FROM hadith_books',
    );
    if (result.isEmpty || result.first['total'] == null) return 0;
    return result.first['total'] as int;
  }

  HadithBook _mapToBook(Map<String, dynamic> row) {
    return HadithBook(
      id: row['id'] as String,
      titleAr: row['name_ar'] as String,
      titleEn: row['name_en'] as String,
      totalCount: row['hadith_count'] as int? ?? 0,
      hasTashkeel: false, // CDN plain import is usually without tashkeel
    );
  }

  HadithItem _mapToHadith(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final numberStr = row['hadith_number'] as String?;
    final number = int.tryParse(numberStr ?? '');

    return HadithItem(
      uid: id,
      bookId: row['book_id'] as String,
      number: number,
      chapter: row['chapter'] as String?,
      textAr: row['text_ar'] as String,
      rawJson: '{}', // Not available in CDN schema
      searchText: row['search_text'] as String? ?? '',
    );
  }
}
