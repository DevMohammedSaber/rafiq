import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../cubit/quran_audio_cubit.dart';
import '../../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

/// Bottom sheet for audio controls in the Quran reader.
class AudioControlBottomSheet extends StatelessWidget {
  final int surahId;
  final String surahNameAr;
  final String surahNameEn;

  const AudioControlBottomSheet({
    super.key,
    required this.surahId,
    required this.surahNameAr,
    required this.surahNameEn,
  });

  static void show(
    BuildContext context, {
    required int surahId,
    required String surahNameAr,
    required String surahNameEn,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<QuranAudioCubit>(),
        child: AudioControlBottomSheet(
          surahId: surahId,
          surahNameAr: surahNameAr,
          surahNameEn: surahNameEn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioCubit, QuranAudioState>(
      builder: (context, state) {
        if (state is QuranAudioLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! QuranAudioLoaded) {
          return const SizedBox.shrink();
        }

        final selectedReciter = state.selectedReciter;
        final isDownloaded =
            selectedReciter != null &&
            state.isSurahDownloaded(selectedReciter.id, surahId);
        final isDownloading =
            state.downloadingReciterId == selectedReciter?.id &&
            state.downloadingSurahId == surahId;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Text(
                'quran.audio'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$surahNameAr - $surahNameEn',
                style: Theme.of(context).textTheme.bodyMedium,
                textDirection: ui.TextDirection.rtl,
              ),

              const SizedBox(height: 24),

              // Reciter info
              if (selectedReciter != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedReciter.nameAr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                            Text(
                              selectedReciter.nameEn,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/quran/audio-settings');
                        },
                        child: Text('common.change'.tr()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Download progress
              if (isDownloading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: state.downloadProgress,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(state.downloadProgress * 100).toInt()}% - ${'quran.downloading'.tr()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text('quran.play'.tr()),
                subtitle: Text(
                  isDownloaded
                      ? 'quran.play_offline'.tr()
                      : 'quran.play_stream'.tr(),
                ),
                onTap: () {
                  // Play audio (would integrate with audio player)
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('quran.playing'.tr())));
                },
              ),

              if (!isDownloaded && !isDownloading && selectedReciter != null)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text('quran.download'.tr()),
                  subtitle: Text('quran.download_for_offline'.tr()),
                  onTap: () {
                    context.read<QuranAudioCubit>().downloadSurah(
                      selectedReciter.id,
                      surahId,
                    );
                  },
                ),

              if (isDownloaded)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'quran.delete_download'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    context.read<QuranAudioCubit>().deleteSurah(
                      selectedReciter.id,
                      surahId,
                    );
                    Navigator.pop(context);
                  },
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('quran.open_audio_settings'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/quran/audio-settings');
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
