import 'package:equatable/equatable.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/daily_question_state.dart';

/// Daily question cubit states
abstract class DailyQuestionCubitState extends Equatable {
  const DailyQuestionCubitState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class DailyQuestionLoading extends DailyQuestionCubitState {
  const DailyQuestionLoading();
}

/// Loaded state with question and answer state
class DailyQuestionLoaded extends DailyQuestionCubitState {
  final QuizQuestion question;
  final DailyQuestionState? savedState;
  final bool canAnswer;

  const DailyQuestionLoaded({
    required this.question,
    this.savedState,
    required this.canAnswer,
  });

  @override
  List<Object?> get props => [question, savedState, canAnswer];

  DailyQuestionLoaded copyWith({
    QuizQuestion? question,
    DailyQuestionState? savedState,
    bool? canAnswer,
    bool clearSavedState = false,
  }) {
    return DailyQuestionLoaded(
      question: question ?? this.question,
      savedState: clearSavedState ? null : (savedState ?? this.savedState),
      canAnswer: canAnswer ?? this.canAnswer,
    );
  }
}

/// Answering state (submitting answer)
class DailyQuestionAnswering extends DailyQuestionCubitState {
  final QuizQuestion question;

  const DailyQuestionAnswering({required this.question});

  @override
  List<Object?> get props => [question];
}

/// Error state
class DailyQuestionError extends DailyQuestionCubitState {
  final String message;

  const DailyQuestionError(this.message);

  @override
  List<Object?> get props => [message];
}
