import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/quiz_question.dart';
import '../cubit/quiz_game_cubit.dart';
import '../cubit/quiz_game_state.dart';

/// Quiz game page with questions and timer
class QuizGamePage extends StatefulWidget {
  const QuizGamePage({super.key});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    // Start the game
    context.read<QuizGameCubit>().start();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('quiz.title'.tr()),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showQuitDialog(context),
          ),
        ),
        body: BlocConsumer<QuizGameCubit, QuizGameState>(
          listener: (context, state) {
            if (state.status == GameStatus.feedback) {
              _feedbackController.forward(from: 0);
            }
            if (state.status == GameStatus.finished && state.result != null) {
              // Navigate to result page
              context.pushReplacement('/quiz/result', extra: state.result);
            }
          },
          builder: (context, state) {
            if (state.status == GameStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.questions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'quiz.no_questions'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            return _buildGameContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, QuizGameState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress and timer row
            _buildProgressRow(context, state),

            const SizedBox(height: 24),

            // Question card
            Expanded(child: _buildQuestionCard(context, state)),

            const SizedBox(height: 16),

            // Options
            _buildOptions(context, state),

            const SizedBox(height: 16),

            // Next button (only in feedback state)
            if (state.status == GameStatus.feedback)
              _buildNextButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, QuizGameState state) {
    return Row(
      children: [
        // Progress text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            state.progressText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),

        const Spacer(),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${state.score}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),

        // Timer (if timed mode)
        if (state.hasTimer) ...[
          const SizedBox(width: 12),
          _buildTimer(context, state),
        ],
      ],
    );
  }

  Widget _buildTimer(BuildContext context, QuizGameState state) {
    final isLow = state.remainingSeconds <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLow ? AppColors.error : AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isLow ? AppColors.error : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${state.remainingSeconds}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLow ? AppColors.error : AppColors.primary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizGameState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getDifficultyColor(
                question.difficulty,
              ).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getDifficultyText(question.difficulty),
              style: TextStyle(
                color: _getDifficultyColor(question.difficulty),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Question text
          Text(
            question.getQuestion(context.locale.languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          // Feedback animation
          if (state.status == GameStatus.feedback) ...[
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _feedbackAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.wasCorrect == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.wasCorrect == true ? Icons.check : Icons.close,
                  color: state.wasCorrect == true
                      ? Colors.green
                      : AppColors.error,
                  size: 48,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context, QuizGameState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final options = question.getOptions(context.locale.languageCode);

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return _buildOptionButton(context, state, index, option, question);
      }).toList(),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    QuizGameState state,
    int index,
    String option,
    QuizQuestion question,
  ) {
    final isSelected = state.selectedAnswer == index;
    final isCorrect =
        state.status == GameStatus.feedback &&
        index == question.correctAnswerIndex;
    final isWrong =
        state.status == GameStatus.feedback &&
        isSelected &&
        state.wasCorrect == false;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (state.status == GameStatus.feedback) {
      if (isCorrect) {
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isWrong) {
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      } else {
        backgroundColor = Theme.of(context).colorScheme.surface;
        borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.3);
        textColor = Theme.of(context).hintColor;
      }
    } else {
      backgroundColor = isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surface;
      borderColor = isSelected
          ? AppColors.primary
          : Theme.of(context).dividerColor.withValues(alpha: 0.3);
      textColor = isSelected
          ? AppColors.primary
          : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: state.status == GameStatus.answering
              ? () => context.read<QuizGameCubit>().selectAnswer(index)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (state.status == GameStatus.feedback && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (state.status == GameStatus.feedback && isWrong)
                  const Icon(Icons.cancel, color: AppColors.error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, QuizGameState state) {
    final isLast = state.isLastQuestion;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.read<QuizGameCubit>().next(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isLast ? 'quiz.finish'.tr() : 'quiz.next'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return AppColors.error;
    }
  }

  String _getDifficultyText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'quiz.easy'.tr();
      case Difficulty.medium:
        return 'quiz.medium'.tr();
      case Difficulty.hard:
        return 'quiz.hard'.tr();
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldQuit = await _showQuitDialog(context);
    return shouldQuit ?? false;
  }

  Future<bool?> _showQuitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('quiz.quit_title'.tr()),
        content: Text('quiz.quit_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<QuizGameCubit>().quit();
              context.pop();
            },
            child: Text('quiz.quit'.tr()),
          ),
        ],
      ),
    );
  }
}
