import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/daily_question_repository.dart';
import '../../domain/models/daily_question_state.dart';
import 'daily_question_state.dart';

/// Cubit for daily question feature
class DailyQuestionCubit extends Cubit<DailyQuestionCubitState> {
  final DailyQuestionRepository _repository;

  DailyQuestionCubit({DailyQuestionRepository? repository})
    : _repository = repository ?? DailyQuestionRepository(),
      super(const DailyQuestionLoading());

  /// Load today's question and saved state
  Future<void> load() async {
    emit(const DailyQuestionLoading());

    try {
      final question = await _repository.getTodayQuestion();
      final savedState = await _repository.getSavedState();

      // Check if user can answer
      bool canAnswer = true;
      if (savedState != null) {
        // User can only answer if saved state is not for today's question
        final isToday = savedState.dayKey == _repository.todayKey;
        final isSameQuestion = savedState.questionId == question.id;
        canAnswer = !(isToday && isSameQuestion);
      }

      emit(
        DailyQuestionLoaded(
          question: question,
          savedState: canAnswer ? null : savedState,
          canAnswer: canAnswer,
        ),
      );
    } catch (e) {
      emit(DailyQuestionError(e.toString()));
    }
  }

  /// Answer MCQ question
  Future<void> answerMcq(int index) async {
    final currentState = state;
    if (currentState is! DailyQuestionLoaded || !currentState.canAnswer) {
      return;
    }

    final question = currentState.question;
    emit(DailyQuestionAnswering(question: question));

    try {
      final isCorrect = question.isCorrect(index);
      final answer = DailyQuestionAnswer(type: 'mcq', value: index);

      await _repository.saveAnswer(
        questionId: question.id,
        answer: answer,
        isCorrect: isCorrect,
      );

      final savedState = DailyQuestionState(
        dayKey: _repository.todayKey,
        questionId: question.id,
        type: 'mcq',
        selectedIndex: index,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
      );

      emit(
        DailyQuestionLoaded(
          question: question,
          savedState: savedState,
          canAnswer: false,
        ),
      );
    } catch (e) {
      emit(DailyQuestionError(e.toString()));
    }
  }

  /// Answer True/False question
  Future<void> answerTf(bool value) async {
    final currentState = state;
    if (currentState is! DailyQuestionLoaded || !currentState.canAnswer) {
      return;
    }

    final question = currentState.question;
    emit(DailyQuestionAnswering(question: question));

    try {
      final selectedIndex = value ? 0 : 1; // True = 0, False = 1
      final isCorrect = question.isCorrect(selectedIndex);
      final answer = DailyQuestionAnswer(type: 'tf', value: value);

      await _repository.saveAnswer(
        questionId: question.id,
        answer: answer,
        isCorrect: isCorrect,
      );

      final savedState = DailyQuestionState(
        dayKey: _repository.todayKey,
        questionId: question.id,
        type: 'tf',
        selectedBool: value,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
      );

      emit(
        DailyQuestionLoaded(
          question: question,
          savedState: savedState,
          canAnswer: false,
        ),
      );
    } catch (e) {
      emit(DailyQuestionError(e.toString()));
    }
  }
}
