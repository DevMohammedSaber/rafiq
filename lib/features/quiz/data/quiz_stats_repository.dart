import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/quiz_stats.dart';

/// Repository for quiz statistics (local storage)
class QuizStatsRepository {
  static const String _statsKey = 'quiz_stats';

  /// Load quiz stats from SharedPreferences
  Future<QuizStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_statsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return const QuizStats();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return QuizStats.fromJson(json);
    } catch (_) {
      return const QuizStats();
    }
  }

  /// Save quiz stats to SharedPreferences
  Future<void> saveStats(QuizStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(stats.toJson());
    await prefs.setString(_statsKey, jsonString);
  }

  /// Update stats after a game
  Future<QuizStats> updateStatsAfterGame({
    required String categoryId,
    required int correct,
    required int total,
    required int score,
    required int xp,
  }) async {
    final currentStats = await loadStats();

    final newStats = currentStats.addGameResult(
      categoryId: categoryId,
      correct: correct,
      total: total,
      score: score,
      xp: xp,
    );

    await saveStats(newStats);
    return newStats;
  }

  /// Check if score is a new best for category
  Future<bool> isNewBestScore(String categoryId, int score) async {
    final stats = await loadStats();
    final currentBest = stats.bestScoreByCategory[categoryId] ?? 0;
    return score > currentBest;
  }

  /// Get best score for a category
  Future<int> getBestScore(String categoryId) async {
    final stats = await loadStats();
    return stats.bestScoreByCategory[categoryId] ?? 0;
  }

  /// Reset all stats
  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }
}
