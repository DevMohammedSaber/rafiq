import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/quiz_stats.dart';

/// Repository for syncing quiz stats with Firestore (authenticated users)
class QuizRemoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's quiz stats document reference
  DocumentReference<Map<String, dynamic>> _statsDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Sync local stats to Firestore
  Future<void> syncStats(String uid, QuizStats stats) async {
    try {
      await _statsDoc(uid).set({
        'quizStats': stats.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - local data is preserved
    }
  }

  /// Fetch stats from Firestore
  Future<QuizStats?> fetchStats(String uid) async {
    try {
      final doc = await _statsDoc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['quizStats'] == null) return null;

      return QuizStats.fromJson(Map<String, dynamic>.from(data['quizStats']));
    } catch (e) {
      return null;
    }
  }

  /// Merge local and remote stats (take best values)
  QuizStats mergeStats(QuizStats local, QuizStats remote) {
    // Merge best scores by category
    final mergedBestScores = Map<String, int>.from(local.bestScoreByCategory);
    for (final entry in remote.bestScoreByCategory.entries) {
      final currentBest = mergedBestScores[entry.key] ?? 0;
      if (entry.value > currentBest) {
        mergedBestScores[entry.key] = entry.value;
      }
    }

    return QuizStats(
      totalGames: local.totalGames > remote.totalGames
          ? local.totalGames
          : remote.totalGames,
      totalCorrect: local.totalCorrect > remote.totalCorrect
          ? local.totalCorrect
          : remote.totalCorrect,
      totalQuestions: local.totalQuestions > remote.totalQuestions
          ? local.totalQuestions
          : remote.totalQuestions,
      totalXP: local.totalXP > remote.totalXP ? local.totalXP : remote.totalXP,
      bestScoreByCategory: mergedBestScores,
      streakDays: local.streakDays > remote.streakDays
          ? local.streakDays
          : remote.streakDays,
      lastPlayedDay: local.lastPlayedDay ?? remote.lastPlayedDay,
    );
  }

  /// Save game result to leaderboard (optional future feature)
  Future<void> saveToLeaderboard(
    String uid,
    String displayName,
    String categoryId,
    int score,
  ) async {
    try {
      await _firestore.collection('quiz_leaderboard').add({
        'uid': uid,
        'displayName': displayName,
        'categoryId': categoryId,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently fail
    }
  }
}
