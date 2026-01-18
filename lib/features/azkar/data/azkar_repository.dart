import 'package:sqflite/sqflite.dart';
import '../domain/models/azkar_category.dart';
import '../domain/models/zikr.dart';
import 'azkar_database_cdn.dart';

class AzkarRepository {
  Future<Database> get _db async => AzkarDatabaseCdn.instance.database;

  void clearCache() {
    // No-op for database implementation
  }

  Future<List<AZkarCategory>> loadCategories() async {
    final db = await _db;
    final result = await db.query(
      'azkar_categories',
      orderBy: 'order_index ASC',
    );
    return result.map((row) {
      return AZkarCategory(
        id: row['id'] as String,
        nameAr: row['name_ar'] as String,
        nameEn: row['name_en'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<Zikr>> loadZikrByCategory(String categoryId) async {
    final db = await _db;
    final result = await db.query(
      'azkar',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'order_index ASC',
    );

    return result.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return _mapToZikr(row, categoryId, index);
    }).toList();
  }

  Future<Zikr?> getZikrById(String zikrId) async {
    // This is tricky because old IDs were synthetic.
    // If zikrId is strictly numeric (new DB ID), try that.
    // If it looks like 'cat_idx', try to parse.
    // For now, let's assume we can't easily reverse lookup 'cat_idx' efficiently without scanning.
    // But since this is likely for deep links or favorites, let's try to support the new ID format (numeric string).

    // Attempt 1: Fetch by numeric ID
    final db = await _db;
    if (int.tryParse(zikrId) != null) {
      final result = await db.query(
        'azkar',
        where: 'id = ?',
        whereArgs: [int.parse(zikrId)],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        // We might miss categoryId needed for ID reconstruction if we don't query it or it's in row
        return _mapToZikr(row, row['category_id'] as String, -1);
      }
    }

    // Fallback: If we can't find it, return null.
    // Reconstructing legacy IDs is too expensive here without better DB support.
    return null;
  }

  Zikr _mapToZikr(Map<String, dynamic> row, String categoryId, int index) {
    final textAr = row['text_ar'] as String;
    final textEn = row['text_en'] as String? ?? '';
    final count = row['count'] as int? ?? 1;
    final benefit = row['benefit'] as String?;
    final reference = row['reference'] as String?;

    // Reconstruct ID: Use database ID as stable identifier now
    final id = row['id'].toString();

    // Dynamic title extraction
    final titleAr = _extractTitle(textAr);

    // Approximate English title
    final titleEn = 'Zikr $id';

    return Zikr(
      id: id,
      categoryId: categoryId,
      titleAr: titleAr,
      titleEn: titleEn,
      textAr: textAr,
      textEn: textEn,
      repeat: count,
      sourceAr: benefit, // Using benefit field for source/benefit
      sourceEn: reference,
    );
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
}
