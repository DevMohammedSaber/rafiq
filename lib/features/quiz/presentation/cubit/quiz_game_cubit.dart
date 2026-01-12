import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quiz_repository.dart';
import '../../data/quiz_stats_repository.dart';
import '../../data/quiz_remote_repository.dart';
import '../../domain/models/quiz_result.dart';
import 'quiz_game_state.dart';

/// Cubit for quiz game logic
class QuizGameCubit extends Cubit<QuizGameState> {
  final QuizRepository _quizRepository;
  final QuizStatsRepository _statsRepository;
  final QuizRemoteRepository _remoteRepository;
  final String? _userId;

  Timer? _timer;
  static const int _secondsPerQuestion = 10;
  static const int _questionsPerGame = 10;

  QuizGameCubit({
    required String categoryId,
    required QuizMode mode,
    QuizRepository? quizRepository,
    QuizStatsRepository? statsRepository,
    QuizRemoteRepository? remoteRepository,
    String? userId,
  }) : _quizRepository = quizRepository ?? QuizRepository(),
       _statsRepository = statsRepository ?? QuizStatsRepository(),
       _remoteRepository = remoteRepository ?? QuizRemoteRepository(),
       _userId = userId,
       super(QuizGameState(mode: mode, categoryId: categoryId));

  /// Start the game
  Future<void> start() async {
    emit(state.copyWith(status: GameStatus.loading));

    try {
      // Load questions
      List questions;
      if (state.categoryId == 'all') {
        questions = await _quizRepository.loadRandomQuestionsAll(
          _questionsPerGame,
        );
      } else {
        questions = await _quizRepository.loadRandomQuestions(
          state.categoryId,
          _questionsPerGame,
        );
      }

      if (questions.isEmpty) {
        // Handle no questions available
        emit(state.copyWith(status: GameStatus.finished, questions: []));
        return;
      }

      // Calculate initial remaining time
      int remainingSeconds = 0;
      if (state.mode == QuizMode.timed) {
        remainingSeconds = _secondsPerQuestion;
      }

      emit(
        state.copyWith(
          status: GameStatus.answering,
          questions: List.from(questions),
          currentIndex: 0,
          correctCount: 0,
          score: 0,
          remainingSeconds: remainingSeconds,
          startTime: DateTime.now(),
          clearSelection: true,
        ),
      );

      // Start timer if timed mode
      if (state.mode == QuizMode.timed) {
        _startTimer();
      }
    } catch (e) {
      emit(state.copyWith(status: GameStatus.finished));
    }
  }

  /// Select an answer
  void selectAnswer(int index) {
    if (state.status != GameStatus.answering) return;
    if (state.selectedAnswer != null) return; // Already answered

    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = question.isCorrect(index);

    // Stop timer
    _timer?.cancel();

    // Calculate score for this question
    int questionScore = 0;
    if (isCorrect) {
      questionScore = 10;
      // Time bonus in timed mode
      if (state.mode == QuizMode.timed && state.remainingSeconds > 0) {
        questionScore += state.remainingSeconds ~/ 2;
      }
    }

    emit(
      state.copyWith(
        status: GameStatus.feedback,
        selectedAnswer: index,
        wasCorrect: isCorrect,
        correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
        score: state.score + questionScore,
      ),
    );
  }

  /// Move to next question or finish
  void next() {
    if (state.status != GameStatus.feedback) return;

    // Check if game is over
    if (state.isLastQuestion) {
      _finishGame();
      return;
    }

    // Move to next question
    emit(
      state.copyWith(
        status: GameStatus.answering,
        currentIndex: state.currentIndex + 1,
        remainingSeconds: state.mode == QuizMode.timed
            ? _secondsPerQuestion
            : 0,
        clearSelection: true,
      ),
    );

    // Restart timer if timed mode
    if (state.mode == QuizMode.timed) {
      _startTimer();
    }
  }

  /// Timer tick
  void _tickTimer() {
    if (state.status != GameStatus.answering) return;

    if (state.remainingSeconds <= 1) {
      // Time's up - auto select wrong (no answer)
      _timer?.cancel();

      emit(
        state.copyWith(
          status: GameStatus.feedback,
          selectedAnswer: -1, // No answer
          wasCorrect: false,
          remainingSeconds: 0,
        ),
      );
    } else {
      emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
    }
  }

  /// Start timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickTimer());
  }

  /// Finish the game
  Future<void> _finishGame() async {
    _timer?.cancel();

    final elapsedTime = state.startTime != null
        ? DateTime.now().difference(state.startTime!)
        : Duration.zero;

    // Check if new best score
    final isNewBest = await _statsRepository.isNewBestScore(
      state.categoryId,
      state.score,
    );

    // Create result
    final result = QuizResult(
      categoryId: state.categoryId,
      mode: state.mode,
      totalQuestions: state.questions.length,
      correctAnswers: state.correctCount,
      score: state.score,
      xpEarned: QuizResult.calculateXP(
        correct: state.correctCount,
        total: state.questions.length,
        mode: state.mode,
      ),
      timeTaken: elapsedTime,
      completedAt: DateTime.now(),
      isNewBest: isNewBest,
    );

    // Save stats
    final newStats = await _statsRepository.updateStatsAfterGame(
      categoryId: state.categoryId,
      correct: state.correctCount,
      total: state.questions.length,
      score: state.score,
      xp: result.xpEarned,
    );

    // Sync to remote if logged in
    if (_userId != null) {
      await _remoteRepository.syncStats(_userId, newStats);
    }

    emit(
      state.copyWith(
        status: GameStatus.finished,
        elapsedTime: elapsedTime,
        result: result,
      ),
    );
  }

  /// Quit game early
  void quit() {
    _timer?.cancel();
    emit(state.copyWith(status: GameStatus.finished));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
