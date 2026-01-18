import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/quran_audio_cubit.dart';
import '../../domain/models/reciter.dart';
import '../../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class QuranAudioSettingsPage extends StatefulWidget {
  const QuranAudioSettingsPage({super.key});

  @override
  State<QuranAudioSettingsPage> createState() => _QuranAudioSettingsPageState();
}

class _QuranAudioSettingsPageState extends State<QuranAudioSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<QuranAudioCubit>().init();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('quran.audio_settings'.tr())),
      body: BlocBuilder<QuranAudioCubit, QuranAudioState>(
        builder: (context, state) {
          if (state is QuranAudioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuranAudioError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<QuranAudioCubit>().init(),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is QuranAudioLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Reciter selection
                Text(
                  'quran.reciter'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ...state.reciters.map(
                  (reciter) => _ReciterCard(
                    reciter: reciter,
                    isSelected: reciter.id == state.selectedReciterId,
                    downloadedCount:
                        state.downloadedSurahs[reciter.id]?.length ?? 0,
                    downloadedSize: state.downloadedSizes[reciter.id] ?? 0,
                    onTap: () => context.read<QuranAudioCubit>().selectReciter(
                      reciter.id,
                    ),
                    onDeleteAll: () =>
                        _showDeleteAllConfirmation(context, reciter),
                  ),
                ),

                const SizedBox(height: 24),

                // Download info for selected reciter
                if (state.selectedReciter != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'quran.downloads'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _DownloadSummaryCard(
                    reciter: state.selectedReciter!,
                    downloadedCount: state.totalDownloadedSurahs,
                    totalSize: _formatBytes(
                      state.selectedReciterDownloadedSize,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Downloaded surahs list
                  if (state
                          .downloadedSurahs[state.selectedReciterId]
                          ?.isNotEmpty ==
                      true) ...[
                    Text(
                      'quran.downloaded_surahs'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.downloadedSurahs[state.selectedReciterId]!
                          .map(
                            (surahId) => Chip(
                              label: Text('$surahId'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _showDeleteSurahConfirmation(
                                context,
                                state.selectedReciterId!,
                                surahId,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_download_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'quran.no_downloads'.tr(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'quran.download_hint'.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context, Reciter reciter) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('quran.delete_all_downloads'.tr()),
        content: Text(
          '${'quran.delete_all_confirm'.tr()} "${reciter.nameEn}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<QuranAudioCubit>().deleteAllForReciter(reciter.id);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteSurahConfirmation(
    BuildContext context,
    String reciterId,
    int surahId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('quran.delete_download'.tr()),
        content: Text('${'quran.delete_surah_confirm'.tr()} $surahId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<QuranAudioCubit>().deleteSurah(reciterId, surahId);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final int downloadedCount;
  final int downloadedSize;
  final VoidCallback onTap;
  final VoidCallback onDeleteAll;

  const _ReciterCard({
    required this.reciter,
    required this.isSelected,
    required this.downloadedCount,
    required this.downloadedSize,
    required this.onTap,
    required this.onDeleteAll,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Reciter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.nameAr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: ui.TextDirection.rtl,
                    ),
                    Text(
                      reciter.nameEn,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (downloadedCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$downloadedCount ${'quran.surahs_downloaded'.tr()} (${_formatBytes(downloadedSize)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button
              if (downloadedCount > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDeleteAll,
                  color: Colors.red,
                  tooltip: 'quran.delete_all_downloads'.tr(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadSummaryCard extends StatelessWidget {
  final Reciter reciter;
  final int downloadedCount;
  final String totalSize;

  const _DownloadSummaryCard({
    required this.reciter,
    required this.downloadedCount,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.headphones, size: 40, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reciter.nameEn,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$downloadedCount/114 ${'quran.surahs'.tr()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalSize,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'quran.downloaded'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
