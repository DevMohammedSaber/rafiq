import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Quiz statistics model
class QuizStats extends Equatable {
  final int totalGames;
  final int totalCorrect;
  final int totalQuestions;
  final int totalXP;
  final Map<String, int> bestScoreByCategory;
  final int streakDays;
  final String? lastPlayedDay;

  const QuizStats({
    this.totalGames = 0,
    this.totalCorrect = 0,
    this.totalQuestions = 0,
    this.totalXP = 0,
    this.bestScoreByCategory = const {},
    this.streakDays = 0,
    this.lastPlayedDay,
  });

  /// Get today's date key
  static String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Get yesterday's date key
  static String get yesterdayKey => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(const Duration(days: 1)));

  /// Calculate overall accuracy
  double get accuracy {
    if (totalQuestions == 0) return 0;
    return (totalCorrect / totalQuestions) * 100;
  }

  /// Get best overall score
  int get bestScore {
    if (bestScoreByCategory.isEmpty) return 0;
    return bestScoreByCategory.values.reduce((a, b) => a > b ? a : b);
  }

  /// Check if played today
  bool get playedToday => lastPlayedDay == todayKey;

  /// Update stats after a game
  QuizStats addGameResult({
    required String categoryId,
    required int correct,
    required int total,
    required int score,
    required int xp,
  }) {
    final newBestByCategory = Map<String, int>.from(bestScoreByCategory);
    final currentBest = newBestByCategory[categoryId] ?? 0;
    if (score > currentBest) {
      newBestByCategory[categoryId] = score;
    }

    // Calculate streak
    int newStreak = streakDays;
    final today = todayKey;
    final yesterday = yesterdayKey;

    if (lastPlayedDay == null) {
      // First game ever
      newStreak = 1;
    } else if (lastPlayedDay == today) {
      // Already played today, streak unchanged
    } else if (lastPlayedDay == yesterday) {
      // Continued streak
      newStreak = streakDays + 1;
    } else {
      // Streak broken, start new
      newStreak = 1;
    }

    return QuizStats(
      totalGames: totalGames + 1,
      totalCorrect: totalCorrect + correct,
      totalQuestions: totalQuestions + total,
      totalXP: totalXP + xp,
      bestScoreByCategory: newBestByCategory,
      streakDays: newStreak,
      lastPlayedDay: today,
    );
  }

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      totalGames: json['totalGames'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      totalXP: json['totalXP'] as int? ?? 0,
      bestScoreByCategory: json['bestScoreByCategory'] != null
          ? Map<String, int>.from(json['bestScoreByCategory'])
          : {},
      streakDays: json['streakDays'] as int? ?? 0,
      lastPlayedDay: json['lastPlayedDay'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'totalCorrect': totalCorrect,
      'totalQuestions': totalQuestions,
      'totalXP': totalXP,
      'bestScoreByCategory': bestScoreByCategory,
      'streakDays': streakDays,
      'lastPlayedDay': lastPlayedDay,
    };
  }

  @override
  List<Object?> get props => [
    totalGames,
    totalCorrect,
    totalQuestions,
    totalXP,
    bestScoreByCategory,
    streakDays,
    lastPlayedDay,
  ];
}
