import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/tasbeeh_stats.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';

/// Main Tasbeeh counter page
class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    context.read<TasbeehCubit>().init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    context.read<TasbeehCubit>().increment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tasbeeh.title'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'tasbeeh.presets'.tr(),
            onPressed: () => context.push('/tasbeeh/presets'),
          ),
        ],
      ),
      body: BlocBuilder<TasbeehCubit, TasbeehState>(
        builder: (context, state) {
          if (state is TasbeehLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasbeehError) {
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
                  Text('errors.generic'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TasbeehCubit>().init(),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is TasbeehLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TasbeehLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          // Preset Selector
          _buildPresetSelector(context, state),

          // Main counter area
          Expanded(child: _buildCounterArea(context, state)),

          // Stats section
          _buildStatsSection(context, state),

          // Action buttons
          _buildActionsRow(context, state),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context, TasbeehLoaded state) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.presets.length,
        itemBuilder: (context, index) {
          final preset = state.presets[index];
          final isSelected = preset.id == state.selected.id;
          final color = preset.colorHex != null
              ? Color(int.parse(preset.colorHex!.replaceFirst('#', '0xFF')))
              : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                preset.getTitle(context.locale.languageCode),
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              onSelected: (selected) {
                if (selected && !isSelected) {
                  _showSwitchConfirmation(context, state, preset.id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showSwitchConfirmation(
    BuildContext context,
    TasbeehLoaded state,
    String newPresetId,
  ) {
    if (state.count == 0) {
      context.read<TasbeehCubit>().selectPreset(newPresetId);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbeeh.confirm_switch_title'.tr()),
        content: Text('tasbeeh.confirm_switch_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TasbeehCubit>().selectPreset(newPresetId);
            },
            child: Text('common.continue'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterArea(BuildContext context, TasbeehLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current dhikr name
          Text(
            state.selected.getTitle(context.locale.languageCode),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Big tap area with counter
          GestureDetector(
            onTap: _onTap,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: _buildCounterCircle(context, state),
            ),
          ),

          const SizedBox(height: 24),

          // Goal progress
          _buildGoalProgress(context, state),
        ],
      ),
    );
  }

  Widget _buildCounterCircle(BuildContext context, TasbeehLoaded state) {
    final color = state.selected.colorHex != null
        ? Color(int.parse(state.selected.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: state.progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Count display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.count.toString(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (state.goalReached)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'tasbeeh.goal_reached'.tr(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(BuildContext context, TasbeehLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'tasbeeh.goal'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(width: 8),
        Text(
          '${state.count} / ${state.goal}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, TasbeehLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Today and Streak row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.today,
                  label: 'tasbeeh.today_total'.tr(),
                  value: state.stats.todayTotal.toString(),
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'tasbeeh.streak'.tr(),
                  value: '${state.stats.streak} ${'tasbeeh.days'.tr()}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini chart for last 7 days
          _buildMiniChart(context, state.stats.last7Days),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart(BuildContext context, List<DailyCount> data) {
    final maxCount = data.fold<int>(
      1,
      (max, d) => d.count > max ? d.count : max,
    );

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((day) {
          final height = maxCount > 0 ? (day.count / maxCount) * 40 : 0.0;
          final isToday = day.date == TasbeehStats.todayKey;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height.clamp(4.0, 40.0),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.dayName.substring(0, 1),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? AppColors.primary
                        : Theme.of(context).hintColor,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, TasbeehLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Haptic toggle
          _buildToggleButton(
            context,
            icon: Icons.vibration,
            label: 'tasbeeh.haptic'.tr(),
            isEnabled: state.hapticEnabled,
            onPressed: () => context.read<TasbeehCubit>().toggleHaptic(),
          ),
          const SizedBox(width: 8),
          // Sound toggle (placeholder - shows but does nothing special)
          _buildToggleButton(
            context,
            icon: Icons.volume_up,
            label: 'tasbeeh.sound'.tr(),
            isEnabled: state.soundEnabled,
            onPressed: () => context.read<TasbeehCubit>().toggleSound(),
          ),
          const Spacer(),
          // Undo button
          IconButton.outlined(
            icon: const Icon(Icons.undo),
            tooltip: 'tasbeeh.undo'.tr(),
            onPressed: state.count > 0
                ? () => context.read<TasbeehCubit>().decrement()
                : null,
          ),
          const SizedBox(width: 8),
          // Reset button
          IconButton.outlined(
            icon: const Icon(Icons.refresh),
            tooltip: 'tasbeeh.reset'.tr(),
            onPressed: state.count > 0
                ? () => _showResetConfirmation(context)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isEnabled
            ? AppColors.primary.withValues(alpha: 0.1)
            : null,
        side: BorderSide(
          color: isEnabled ? AppColors.primary : Theme.of(context).dividerColor,
        ),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: isEnabled ? AppColors.primary : Theme.of(context).hintColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isEnabled ? AppColors.primary : Theme.of(context).hintColor,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbeeh.confirm_reset_title'.tr()),
        content: Text('tasbeeh.confirm_reset_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TasbeehCubit>().reset();
            },
            child: Text('tasbeeh.reset'.tr()),
          ),
        ],
      ),
    );
  }
}
