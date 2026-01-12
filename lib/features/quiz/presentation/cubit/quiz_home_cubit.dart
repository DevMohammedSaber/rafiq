import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quiz_repository.dart';
import '../../data/quiz_stats_repository.dart';
import '../../domain/models/quiz_stats.dart';
import '../../domain/models/quiz_result.dart';
import 'quiz_home_state.dart';

/// Cubit for quiz home screen
class QuizHomeCubit extends Cubit<QuizHomeState> {
  final QuizRepository _quizRepository;
  final QuizStatsRepository _statsRepository;

  QuizHomeCubit({
    QuizRepository? quizRepository,
    QuizStatsRepository? statsRepository,
  }) : _quizRepository = quizRepository ?? QuizRepository(),
       _statsRepository = statsRepository ?? QuizStatsRepository(),
       super(const QuizHomeLoading());

  /// Load categories and stats
  Future<void> load() async {
    emit(const QuizHomeLoading());

    try {
      final results = await Future.wait([
        _quizRepository.loadCategories(),
        _statsRepository.loadStats(),
        _quizRepository.getQuestionCountByCategory(),
      ]);

      final categories = results[0] as List;
      final stats = results[1] as QuizStats;
      final counts = results[2] as Map<String, int>;

      emit(
        QuizHomeLoaded(
          categories: List.from(categories),
          stats: stats,
          questionCounts: counts,
        ),
      );
    } catch (e) {
      emit(QuizHomeError(e.toString()));
    }
  }

  /// Select quiz mode
  void selectMode(QuizMode mode) {
    final currentState = state;
    if (currentState is QuizHomeLoaded) {
      emit(currentState.copyWith(selectedMode: mode));
    }
  }

  /// Select category
  void selectCategory(String? categoryId) {
    final currentState = state;
    if (currentState is QuizHomeLoaded) {
      emit(
        currentState.copyWith(
          selectedCategoryId: categoryId,
          clearCategory: categoryId == null,
        ),
      );
    }
  }

  /// Refresh stats (after game completion)
  Future<void> refreshStats() async {
    final currentState = state;
    if (currentState is QuizHomeLoaded) {
      final stats = await _statsRepository.loadStats();
      emit(currentState.copyWith(stats: stats));
    }
  }
}
