import 'package:equatable/equatable.dart';

/// Quiz game mode
enum QuizMode {
  quick, // 10 questions, no timer
  timed, // 10 questions, 10 seconds per question
  practice, // infinite, no timer
}

/// Quiz result for a completed game
class QuizResult extends Equatable {
  final String categoryId;
  final QuizMode mode;
  final int totalQuestions;
  final int correctAnswers;
  final int score;
  final int xpEarned;
  final Duration timeTaken;
  final DateTime completedAt;
  final bool isNewBest;

  const QuizResult({
    required this.categoryId,
    required this.mode,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.xpEarned,
    required this.timeTaken,
    required this.completedAt,
    this.isNewBest = false,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  /// Calculate score from correct answers
  /// Formula: (correct * 10) + (accuracy bonus) + (time bonus for timed mode)
  static int calculateScore({
    required int correct,
    required int total,
    required QuizMode mode,
    Duration? timeTaken,
  }) {
    int baseScore = correct * 10;

    // Accuracy bonus
    double accuracy = total > 0 ? (correct / total) : 0;
    if (accuracy == 1.0) {
      baseScore += 50; // Perfect score bonus
    } else if (accuracy >= 0.8) {
      baseScore += 20; // Good score bonus
    }

    // Time bonus for timed mode
    if (mode == QuizMode.timed && timeTaken != null) {
      int secondsLeft = (total * 10) - timeTaken.inSeconds;
      if (secondsLeft > 0) {
        baseScore += (secondsLeft ~/ 2); // Half point per second left
      }
    }

    return baseScore;
  }

  /// Calculate XP earned
  static int calculateXP({
    required int correct,
    required int total,
    required QuizMode mode,
  }) {
    int xp = correct * 5; // Base XP

    // Mode multiplier
    if (mode == QuizMode.timed) {
      xp = (xp * 1.5).round(); // 50% bonus for timed mode
    }

    // Perfect game bonus
    double accuracy = total > 0 ? (correct / total) : 0;
    if (accuracy == 1.0) {
      xp += 25;
    }

    return xp;
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      categoryId: json['categoryId'] as String,
      mode: QuizMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => QuizMode.quick,
      ),
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      score: json['score'] as int,
      xpEarned: json['xpEarned'] as int? ?? 0,
      timeTaken: Duration(seconds: json['timeTakenSeconds'] as int? ?? 0),
      completedAt: DateTime.parse(json['completedAt'] as String),
      isNewBest: json['isNewBest'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'mode': mode.name,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': score,
      'xpEarned': xpEarned,
      'timeTakenSeconds': timeTaken.inSeconds,
      'completedAt': completedAt.toIso8601String(),
      'isNewBest': isNewBest,
    };
  }

  QuizResult copyWith({bool? isNewBest}) {
    return QuizResult(
      categoryId: categoryId,
      mode: mode,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      score: score,
      xpEarned: xpEarned,
      timeTaken: timeTaken,
      completedAt: completedAt,
      isNewBest: isNewBest ?? this.isNewBest,
    );
  }

  @override
  List<Object?> get props => [
    categoryId,
    mode,
    totalQuestions,
    correctAnswers,
    score,
    xpEarned,
    timeTaken,
    completedAt,
    isNewBest,
  ];
}
