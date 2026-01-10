import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/db/hadith_database.dart';
import 'package:intl/intl.dart';

class HadithDailyRepository {
  static const String _dayKey = 'guest_hadith_day';
  static const String _uidKey = 'guest_hadith_uid';

  Future<String?> getDailyHadithUid(int totalCount) async {
    if (totalCount == 0) return null;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();

    final savedDay = prefs.getString(_dayKey);
    final savedUid = prefs.getString(_uidKey);

    if (savedDay == today && savedUid != null) {
      return savedUid;
    }

    // Deterministic selection
    final dayHash = today.hashCode.abs();
    final offset = dayHash % totalCount;

    final db = await HadithDatabase.instance.database;
    final result = await db.query(
      'hadith_items',
      columns: ['uid'],
      limit: 1,
      offset: offset,
    );

    if (result.isEmpty) return null;

    final newUid = result.first['uid'] as String;
    await prefs.setString(_dayKey, today);
    await prefs.setString(_uidKey, newUid);

    return newUid;
  }
}
