import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../settings/quran_settings_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Entry page for Quran feature with mode toggle (Text / Mushaf)
class QuranEntryPage extends StatefulWidget {
  const QuranEntryPage({super.key});

  @override
  State<QuranEntryPage> createState() => _QuranEntryPageState();
}

class _QuranEntryPageState extends State<QuranEntryPage> {
  final _settingsRepo = QuranSettingsRepository();
  String _selectedMode = 'text';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await _settingsRepo.getViewMode();
    if (mounted) {
      setState(() {
        _selectedMode = mode;
        _isLoading = false;
      });
    }
  }

  void _navigateToMode(String mode) async {
    await _settingsRepo.setViewMode(mode);
    if (!mounted) return;

    if (mode == 'mushaf') {
      // Check if mushaf is installed
      final mushafId = await _settingsRepo.getSelectedMushafId();
      if (!mounted) return;

      if (mushafId == null) {
        // Navigate to store first
        context.push('/quran/mushaf/store');
      } else {
        context.push('/quran/mushaf');
      }
    } else {
      context.push('/quran/text/1');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('quran.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/quran/search'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selection Cards
            Text(
              'quran.select_mode'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Text Mode Card
            _ModeCard(
              icon: Icons.text_fields,
              title: 'quran.mode_text'.tr(),
              description: 'quran.mode_text_desc'.tr(),
              isSelected: _selectedMode == 'text',
              onTap: () => _navigateToMode('text'),
            ),
            const SizedBox(height: 16),

            // Mushaf Mode Card
            _ModeCard(
              icon: Icons.menu_book,
              title: 'quran.mode_mushaf'.tr(),
              description: 'quran.mode_mushaf_desc'.tr(),
              isSelected: _selectedMode == 'mushaf',
              onTap: () => _navigateToMode('mushaf'),
            ),

            const Spacer(),

            // Quick Actions
            Text(
              'quran.quick_actions'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.play_arrow,
                    label: 'quran.continue_reading'.tr(),
                    onTap: () => _resumeLastRead(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.download,
                    label: 'quran.mushaf_store'.tr(),
                    onTap: () => context.push('/quran/mushaf/store'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resumeLastRead() async {
    final settings = await _settingsRepo.loadAll();

    if (!mounted) return;

    if (settings.viewMode == 'mushaf') {
      final page = settings.lastMushafPage;
      if (page != null) {
        context.push('/quran/mushaf?page=$page');
      } else {
        context.push('/quran/mushaf');
      }
    } else {
      final surahId = settings.lastReadSurahId;
      final ayah = settings.lastReadAyahNumber;
      if (surahId != null) {
        if (ayah != null) {
          context.push('/quran/text/$surahId?ayah=$ayah');
        } else {
          context.push('/quran/text/$surahId');
        }
      } else {
        // Default to Al-Fatihah
        context.push('/quran/text/1');
      }
    }
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
