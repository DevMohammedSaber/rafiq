import '../../../core/db/hadith_database.dart';
import '../domain/models/hadith_models.dart';
import '../../../core/utils/arabic_normalizer.dart';

class HadithRepository {
  Future<List<HadithBook>> getBooks() async {
    final db = await HadithDatabase.instance.database;
    final result = await db.query('hadith_books');
    return result.map((e) => HadithBook.fromMap(e)).toList();
  }

  Future<List<HadithItem>> getHadithByBook(
    String bookId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await HadithDatabase.instance.database;
    final result = await db.query(
      'hadith_items',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: limit,
      offset: offset,
      orderBy: 'number ASC',
    );
    return result.map((e) => HadithItem.fromMap(e)).toList();
  }

  Future<List<HadithItem>> searchInBook(
    String bookId,
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await HadithDatabase.instance.database;
    final normalizedQuery = ArabicNormalizer.normalize(query);
    final result = await db.query(
      'hadith_items',
      where: 'book_id = ? AND search_text LIKE ?',
      whereArgs: [bookId, '%$normalizedQuery%'],
      limit: limit,
      offset: offset,
    );
    return result.map((e) => HadithItem.fromMap(e)).toList();
  }

  Future<HadithItem?> getHadithByUid(String uid) async {
    final db = await HadithDatabase.instance.database;
    final result = await db.query(
      'hadith_items',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (result.isEmpty) return null;
    return HadithItem.fromMap(result.first);
  }

  Future<int> getTotalHadithCount() async {
    final db = await HadithDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_count) as total FROM hadith_books',
    );
    if (result.isEmpty || result.first['total'] == null) return 0;
    return result.first['total'] as int;
  }
}
