import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/quiz_result.dart';

/// Quiz result page showing score and stats
class QuizResultPage extends StatefulWidget {
  final QuizResult result;

  const QuizResultPage({super.key, required this.result});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Start animations
    _animationController.forward();

    // Play celebration if good score or new best
    if (widget.result.accuracy >= 80 || widget.result.isNewBest) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _celebrationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Result icon with celebration
              _buildResultIcon(context),

              const SizedBox(height: 24),

              // Score
              _buildScoreSection(context),

              const SizedBox(height: 32),

              // Stats grid
              _buildStatsGrid(context),

              const SizedBox(height: 24),

              // XP earned
              _buildXPSection(context),

              const SizedBox(height: 32),

              // New best badge
              if (widget.result.isNewBest) _buildNewBestBadge(context),

              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon(BuildContext context) {
    IconData icon;
    Color color;
    String message;

    if (widget.result.accuracy >= 80) {
      icon = Icons.emoji_events;
      color = Colors.amber;
      message = 'quiz.result_excellent'.tr();
    } else if (widget.result.accuracy >= 60) {
      icon = Icons.thumb_up;
      color = Colors.green;
      message = 'quiz.result_good'.tr();
    } else if (widget.result.accuracy >= 40) {
      icon = Icons.sentiment_satisfied;
      color = Colors.orange;
      message = 'quiz.result_ok'.tr();
    } else {
      icon = Icons.school;
      color = AppColors.primary;
      message = 'quiz.result_practice'.tr();
    }

    return Column(
      children: [
        ScaleTransition(
          scale: _celebrationAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: widget.result.accuracy >= 80
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: color, size: 64),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final displayScore = (widget.result.score * _scoreAnimation.value)
            .round();
        return Column(
          children: [
            Text(
              '$displayScore',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'quiz.points'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.check_circle,
              iconColor: Colors.green,
              value:
                  '${widget.result.correctAnswers}/${widget.result.totalQuestions}',
              label: 'quiz.correct'.tr(),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.pie_chart,
              iconColor: AppColors.primary,
              value: '${widget.result.accuracy.toStringAsFixed(0)}%',
              label: 'quiz.accuracy'.tr(),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.timer,
              iconColor: Colors.orange,
              value: _formatDuration(widget.result.timeTaken),
              label: 'quiz.time'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildXPSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purple),
          const SizedBox(width: 8),
          Text(
            '+${widget.result.xpEarned} XP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBestBadge(BuildContext context) {
    return ScaleTransition(
      scale: _celebrationAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'quiz.new_best'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Replace current result page with new game
              context.pushReplacement(
                '/quiz/game',
                extra: {
                  'categoryId': widget.result.categoryId,
                  'mode': widget.result.mode,
                },
              );
            },
            icon: const Icon(Icons.replay),
            label: Text('quiz.play_again'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Pop back to quiz home (preserves navigation stack)
              context.pop();
            },
            icon: const Icon(Icons.home),
            label: Text('quiz.back_home'.tr()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
