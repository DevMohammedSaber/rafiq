import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/app_card.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/daily_question_state.dart';
import '../cubit/daily_question_cubit.dart';
import '../cubit/daily_question_state.dart';

/// Daily Question Card for Home Screen
class DailyQuestionCard extends StatelessWidget {
  const DailyQuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyQuestionCubit, DailyQuestionCubitState>(
      builder: (context, state) {
        if (state is DailyQuestionLoading) {
          return _buildLoadingCard(context);
        }

        if (state is DailyQuestionError) {
          return _buildErrorCard(context, state.message);
        }

        if (state is DailyQuestionAnswering) {
          return _buildAnsweringCard(context, state.question);
        }

        if (state is DailyQuestionLoaded) {
          return _buildQuestionCard(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'quiz.question_of_the_day'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'quiz.question_of_the_day'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'errors.generic'.tr(),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<DailyQuestionCubit>().load(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnsweringCard(BuildContext context, QuizQuestion question) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Text(
              question.getQuestion(context.locale.languageCode),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, DailyQuestionLoaded state) {
    final question = state.question;
    final savedState = state.savedState;
    final canAnswer = state.canAnswer;
    final langCode = context.locale.languageCode;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, showAnswered: !canAnswer),

            const SizedBox(height: 16),

            // Question text
            Text(
              question.getQuestion(langCode),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Answer options or result
            if (canAnswer)
              _buildAnswerOptions(context, question)
            else if (savedState != null)
              _buildAnswerResult(context, question, savedState),

            const SizedBox(height: 12),

            // Open Quiz button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/quiz'),
                icon: const Icon(Icons.quiz, size: 18),
                label: Text('quiz.open_quiz'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool showAnswered = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'quiz.question_of_the_day'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (showAnswered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text(
                  'quiz.answered'.tr(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerOptions(BuildContext context, QuizQuestion question) {
    if (question.type == QuestionType.trueFalse) {
      return _buildTrueFalseOptions(context);
    } else {
      return _buildMcqOptions(context, question);
    }
  }

  Widget _buildMcqOptions(BuildContext context, QuizQuestion question) {
    final options = question.getOptions(context.locale.languageCode);

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  context.read<DailyQuestionCubit>().answerMcq(index),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.read<DailyQuestionCubit>().answerTf(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('quiz.true'.tr()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.read<DailyQuestionCubit>().answerTf(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('quiz.false'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerResult(
    BuildContext context,
    QuizQuestion question,
    DailyQuestionState savedState,
  ) {
    final langCode = context.locale.languageCode;
    final options = question.getOptions(langCode);
    final correctIndex = question.correctAnswerIndex;
    final explanation = question.getExplanation(langCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: savedState.isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                savedState.isCorrect ? Icons.check_circle : Icons.cancel,
                color: savedState.isCorrect ? Colors.green : AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                savedState.isCorrect
                    ? 'quiz.correct'.tr()
                    : 'quiz.incorrect'.tr(),
                style: TextStyle(
                  color: savedState.isCorrect ? Colors.green : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // User's answer
        if (savedState.type == 'mcq' && savedState.selectedIndex != null) ...[
          Text(
            'quiz.your_answer'.tr(),
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            options[savedState.selectedIndex!],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: savedState.isCorrect ? Colors.green : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (savedState.type == 'tf' &&
            savedState.selectedBool != null) ...[
          Text(
            'quiz.your_answer'.tr(),
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            savedState.selectedBool! ? 'quiz.true'.tr() : 'quiz.false'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: savedState.isCorrect ? Colors.green : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // Correct answer (if wrong)
        if (!savedState.isCorrect) ...[
          const SizedBox(height: 8),
          Text(
            'quiz.correct_answer'.tr(),
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (savedState.type == 'mcq')
            Text(
              options[correctIndex],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              question.correctBool == true
                  ? 'quiz.true'.tr()
                  : 'quiz.false'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],

        // Explanation
        if (explanation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.explanation'.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
