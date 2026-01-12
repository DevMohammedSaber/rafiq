import 'package:equatable/equatable.dart';
import '../../domain/models/quiz_category.dart';
import '../../domain/models/quiz_stats.dart';
import '../../domain/models/quiz_result.dart';

/// Quiz home states
abstract class QuizHomeState extends Equatable {
  const QuizHomeState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class QuizHomeLoading extends QuizHomeState {
  const QuizHomeLoading();
}

/// Loaded state with categories and stats
class QuizHomeLoaded extends QuizHomeState {
  final List<QuizCategory> categories;
  final QuizStats stats;
  final Map<String, int> questionCounts;
  final QuizMode selectedMode;
  final String? selectedCategoryId;

  const QuizHomeLoaded({
    required this.categories,
    required this.stats,
    required this.questionCounts,
    this.selectedMode = QuizMode.quick,
    this.selectedCategoryId,
  });

  @override
  List<Object?> get props => [
    categories,
    stats,
    questionCounts,
    selectedMode,
    selectedCategoryId,
  ];

  QuizHomeLoaded copyWith({
    List<QuizCategory>? categories,
    QuizStats? stats,
    Map<String, int>? questionCounts,
    QuizMode? selectedMode,
    String? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return QuizHomeLoaded(
      categories: categories ?? this.categories,
      stats: stats ?? this.stats,
      questionCounts: questionCounts ?? this.questionCounts,
      selectedMode: selectedMode ?? this.selectedMode,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }
}

/// Error state
class QuizHomeError extends QuizHomeState {
  final String message;

  const QuizHomeError(this.message);

  @override
  List<Object?> get props => [message];
}
