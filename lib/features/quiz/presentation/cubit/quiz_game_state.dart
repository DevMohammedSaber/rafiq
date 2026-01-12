import 'package:equatable/equatable.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/quiz_result.dart';

/// Game status enum
enum GameStatus { loading, answering, feedback, finished }

/// Quiz game state
class QuizGameState extends Equatable {
  final GameStatus status;
  final QuizMode mode;
  final String categoryId;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int? selectedAnswer;
  final bool? wasCorrect;
  final int remainingSeconds;
  final int correctCount;
  final int score;
  final Duration elapsedTime;
  final DateTime? startTime;
  final QuizResult? result;

  const QuizGameState({
    this.status = GameStatus.loading,
    required this.mode,
    required this.categoryId,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswer,
    this.wasCorrect,
    this.remainingSeconds = 0,
    this.correctCount = 0,
    this.score = 0,
    this.elapsedTime = Duration.zero,
    this.startTime,
    this.result,
  });

  /// Get current question
  QuizQuestion? get currentQuestion {
    if (currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  /// Get progress string (e.g., "3/10")
  String get progressText => '${currentIndex + 1}/${questions.length}';

  /// Get progress value (0.0 to 1.0)
  double get progress {
    if (questions.isEmpty) return 0;
    return (currentIndex + 1) / questions.length;
  }

  /// Check if this is the last question
  bool get isLastQuestion => currentIndex >= questions.length - 1;

  /// Check if timer is active
  bool get hasTimer => mode == QuizMode.timed;

  @override
  List<Object?> get props => [
    status,
    mode,
    categoryId,
    questions,
    currentIndex,
    selectedAnswer,
    wasCorrect,
    remainingSeconds,
    correctCount,
    score,
    elapsedTime,
    startTime,
    result,
  ];

  QuizGameState copyWith({
    GameStatus? status,
    QuizMode? mode,
    String? categoryId,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? selectedAnswer,
    bool? wasCorrect,
    int? remainingSeconds,
    int? correctCount,
    int? score,
    Duration? elapsedTime,
    DateTime? startTime,
    QuizResult? result,
    bool clearSelection = false,
    bool clearResult = false,
  }) {
    return QuizGameState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      categoryId: categoryId ?? this.categoryId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswer: clearSelection
          ? null
          : (selectedAnswer ?? this.selectedAnswer),
      wasCorrect: clearSelection ? null : (wasCorrect ?? this.wasCorrect),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      correctCount: correctCount ?? this.correctCount,
      score: score ?? this.score,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}
