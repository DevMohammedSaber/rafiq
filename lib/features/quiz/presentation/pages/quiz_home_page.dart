import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/app_card.dart';
import '../../domain/models/quiz_category.dart';
import '../../domain/models/quiz_result.dart';
import '../cubit/quiz_home_cubit.dart';
import '../cubit/quiz_home_state.dart';

/// Quiz home page with category selection and stats
class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<QuizHomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('quiz.title'.tr()), centerTitle: true),
      body: BlocBuilder<QuizHomeCubit, QuizHomeState>(
        builder: (context, state) {
          if (state is QuizHomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuizHomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<QuizHomeCubit>().load(),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is QuizHomeLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, QuizHomeLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          _buildStatsCard(context, state),

          const SizedBox(height: 24),

          // Mode selection
          Text(
            'quiz.select_mode'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildModeSelector(context, state),

          const SizedBox(height: 24),

          // Category selection
          Text(
            'quiz.select_category'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(context, state),

          const SizedBox(height: 24),

          // Start button
          _buildStartButton(context, state),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, QuizHomeLoaded state) {
    final stats = state.stats;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Streak
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                label: 'quiz.streak'.tr(),
                value: '${stats.streakDays}',
                subtitle: 'quiz.days'.tr(),
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            // Best Score
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                label: 'quiz.best_score'.tr(),
                value: '${stats.bestScore}',
                subtitle: 'quiz.points'.tr(),
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            // Total Games
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.games,
                iconColor: AppColors.primary,
                label: 'quiz.games'.tr(),
                value: '${stats.totalGames}',
                subtitle: 'quiz.played'.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, QuizHomeLoaded state) {
    return Row(
      children: [
        _buildModeChip(
          context,
          mode: QuizMode.quick,
          label: 'quiz.mode_quick'.tr(),
          icon: Icons.bolt,
          isSelected: state.selectedMode == QuizMode.quick,
        ),
        const SizedBox(width: 8),
        _buildModeChip(
          context,
          mode: QuizMode.timed,
          label: 'quiz.mode_timed'.tr(),
          icon: Icons.timer,
          isSelected: state.selectedMode == QuizMode.timed,
        ),
        const SizedBox(width: 8),
        _buildModeChip(
          context,
          mode: QuizMode.practice,
          label: 'quiz.mode_practice'.tr(),
          icon: Icons.school,
          isSelected: state.selectedMode == QuizMode.practice,
        ),
      ],
    );
  }

  Widget _buildModeChip(
    BuildContext context, {
    required QuizMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<QuizHomeCubit>().selectMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).hintColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, QuizHomeLoaded state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: state.categories.length,
      itemBuilder: (context, index) {
        final category = state.categories[index];
        final isSelected = state.selectedCategoryId == category.id;
        final questionCount = state.questionCounts[category.id] ?? 0;

        return _buildCategoryCard(
          context,
          category: category,
          isSelected: isSelected,
          questionCount: questionCount,
          bestScore: state.stats.bestScoreByCategory[category.id],
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required QuizCategory category,
    required bool isSelected,
    required int questionCount,
    int? bestScore,
  }) {
    return GestureDetector(
      onTap: () => context.read<QuizHomeCubit>().selectCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? category.color
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.iconData,
                      color: category.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.getName(context.locale.languageCode),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$questionCount ${'quiz.questions'.tr()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            // Best score badge
            if (bestScore != null && bestScore > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$bestScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Selection checkmark
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, QuizHomeLoaded state) {
    final canStart = state.selectedCategoryId != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canStart ? () => _startGame(context, state) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow),
            const SizedBox(width: 8),
            Text(
              'quiz.start'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, QuizHomeLoaded state) async {
    if (state.selectedCategoryId == null) return;

    await context.push(
      '/quiz/game',
      extra: {
        'categoryId': state.selectedCategoryId,
        'mode': state.selectedMode,
      },
    );

    // Refresh stats when returning from game
    if (mounted) {
      context.read<QuizHomeCubit>().refreshStats();
    }
  }
}
