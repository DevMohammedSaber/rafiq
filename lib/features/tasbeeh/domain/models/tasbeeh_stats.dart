import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Tasbeeh statistics model for tracking daily totals and streaks
class TasbeehStats extends Equatable {
  /// Daily totals mapped by date (yyyy-MM-dd -> count)
  final Map<String, int> dailyTotals;

  /// Current streak of consecutive days with tasbeeh activity
  final int streak;

  /// Last active day (yyyy-MM-dd)
  final String? lastActiveDay;

  const TasbeehStats({
    this.dailyTotals = const {},
    this.streak = 0,
    this.lastActiveDay,
  });

  /// Get today's date key
  static String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Get yesterday's date key
  static String get yesterdayKey => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(const Duration(days: 1)));

  /// Get today's total count
  int get todayTotal => dailyTotals[todayKey] ?? 0;

  /// Get last 7 days data for chart
  List<DailyCount> get last7Days {
    final List<DailyCount> result = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('EEE').format(date);
      result.add(
        DailyCount(date: key, dayName: dayName, count: dailyTotals[key] ?? 0),
      );
    }

    return result;
  }

  /// Add count to today's total and update streak
  TasbeehStats addCount(int amount) {
    final today = todayKey;
    final yesterday = yesterdayKey;

    // Update daily totals
    final newDailyTotals = Map<String, int>.from(dailyTotals);
    newDailyTotals[today] = (newDailyTotals[today] ?? 0) + amount;

    // Calculate new streak
    int newStreak = streak;
    if (lastActiveDay == null) {
      // First activity ever
      newStreak = 1;
    } else if (lastActiveDay == today) {
      // Same day, streak unchanged
    } else if (lastActiveDay == yesterday) {
      // Consecutive day, increment streak
      newStreak = streak + 1;
    } else {
      // Gap in activity, reset streak
      newStreak = 1;
    }

    // Clean up old entries (keep only last 90 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final cutoffKey = DateFormat('yyyy-MM-dd').format(cutoffDate);
    newDailyTotals.removeWhere((key, _) => key.compareTo(cutoffKey) < 0);

    return TasbeehStats(
      dailyTotals: newDailyTotals,
      streak: newStreak,
      lastActiveDay: today,
    );
  }

  factory TasbeehStats.fromJson(Map<String, dynamic> json) {
    final dailyTotalsRaw = json['dailyTotals'] as Map<String, dynamic>?;
    final dailyTotals =
        dailyTotalsRaw?.map((key, value) => MapEntry(key, value as int)) ??
        <String, int>{};

    return TasbeehStats(
      dailyTotals: dailyTotals,
      streak: json['streak'] as int? ?? 0,
      lastActiveDay: json['lastActiveDay'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTotals': dailyTotals,
      'streak': streak,
      'lastActiveDay': lastActiveDay,
    };
  }

  TasbeehStats copyWith({
    Map<String, int>? dailyTotals,
    int? streak,
    String? lastActiveDay,
  }) {
    return TasbeehStats(
      dailyTotals: dailyTotals ?? this.dailyTotals,
      streak: streak ?? this.streak,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
    );
  }

  @override
  List<Object?> get props => [dailyTotals, streak, lastActiveDay];
}

/// Helper class for daily count data
class DailyCount {
  final String date;
  final String dayName;
  final int count;

  const DailyCount({
    required this.date,
    required this.dayName,
    required this.count,
  });
}
