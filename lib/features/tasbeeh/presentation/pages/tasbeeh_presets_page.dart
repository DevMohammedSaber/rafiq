import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/tasbeeh_preset.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';

/// Tasbeeh presets management page
class TasbeehPresetsPage extends StatelessWidget {
  const TasbeehPresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('tasbeeh.presets'.tr()), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPresetDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TasbeehCubit, TasbeehState>(
        builder: (context, state) {
          if (state is TasbeehLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasbeehLoaded) {
            return _buildPresetsList(context, state);
          }

          return Center(child: Text('errors.generic'.tr()));
        },
      ),
    );
  }

  Widget _buildPresetsList(BuildContext context, TasbeehLoaded state) {
    // Separate default and custom presets
    final defaultPresets = state.presets.where((p) => p.isDefault).toList();
    final customPresets = state.presets.where((p) => !p.isDefault).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default presets section
        _buildSectionHeader(context, 'tasbeeh.default_presets'.tr()),
        const SizedBox(height: 8),
        ...defaultPresets.map((p) => _buildPresetTile(context, p, state)),

        const SizedBox(height: 24),

        // Custom presets section
        _buildSectionHeader(context, 'tasbeeh.custom_presets'.tr()),
        const SizedBox(height: 8),
        if (customPresets.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'tasbeeh.no_custom_presets'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddPresetDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text('tasbeeh.add_preset'.tr()),
                ),
              ],
            ),
          )
        else
          ...customPresets.map((p) => _buildPresetTile(context, p, state)),

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildPresetTile(
    BuildContext context,
    TasbeehPreset preset,
    TasbeehLoaded state,
  ) {
    final isSelected = preset.id == state.selected.id;
    final color = preset.colorHex != null
        ? Color(int.parse(preset.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? color
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          context.read<TasbeehCubit>().selectPreset(preset.id);
          Navigator.pop(context);
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              preset.goal.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          preset.getTitle(context.locale.languageCode),
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null),
        ),
        subtitle: preset.titleEn != null && context.locale.languageCode == 'ar'
            ? Text(
                preset.titleEn!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
            if (!preset.isDefault) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditPresetDialog(context, preset),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _showDeleteConfirmation(context, preset),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context) {
    final titleArController = TextEditingController();
    final titleEnController = TextEditingController();
    final goalController = TextEditingController(text: '33');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbeeh.add_preset'.tr()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleArController,
                decoration: InputDecoration(
                  labelText: 'tasbeeh.title_ar'.tr(),
                  hintText: 'e.g., استغفر الله',
                ),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'tasbeeh.title_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleEnController,
                decoration: InputDecoration(
                  labelText: 'tasbeeh.title_en'.tr(),
                  hintText: 'e.g., Astaghfirullah (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: goalController,
                decoration: InputDecoration(labelText: 'tasbeeh.goal'.tr()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'tasbeeh.goal_required'.tr();
                  }
                  final goal = int.tryParse(value);
                  if (goal == null || goal <= 0) {
                    return 'tasbeeh.goal_invalid'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<TasbeehCubit>().addPreset(
                  titleAr: titleArController.text.trim(),
                  titleEn: titleEnController.text.trim().isNotEmpty
                      ? titleEnController.text.trim()
                      : null,
                  goal: int.parse(goalController.text),
                );
                Navigator.pop(ctx);
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, TasbeehPreset preset) {
    final titleArController = TextEditingController(text: preset.titleAr);
    final titleEnController = TextEditingController(text: preset.titleEn ?? '');
    final goalController = TextEditingController(text: preset.goal.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbeeh.edit_preset'.tr()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleArController,
                decoration: InputDecoration(labelText: 'tasbeeh.title_ar'.tr()),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'tasbeeh.title_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleEnController,
                decoration: InputDecoration(labelText: 'tasbeeh.title_en'.tr()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: goalController,
                decoration: InputDecoration(labelText: 'tasbeeh.goal'.tr()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'tasbeeh.goal_required'.tr();
                  }
                  final goal = int.tryParse(value);
                  if (goal == null || goal <= 0) {
                    return 'tasbeeh.goal_invalid'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedPreset = preset.copyWith(
                  titleAr: titleArController.text.trim(),
                  titleEn: titleEnController.text.trim().isNotEmpty
                      ? titleEnController.text.trim()
                      : null,
                  goal: int.parse(goalController.text),
                );
                context.read<TasbeehCubit>().updatePreset(updatedPreset);
                Navigator.pop(ctx);
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TasbeehPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbeeh.delete_preset'.tr()),
        content: Text(
          'tasbeeh.delete_confirm'.tr(
            args: [preset.getTitle(context.locale.languageCode)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TasbeehCubit>().deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
