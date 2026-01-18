import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rafiq/features/quran/audio/quran_ayah_audio_service.dart';
import 'package:rafiq/features/quran/data/quran_user_data_repository.dart';
import '../cubit/quran_reader_cubit.dart';
import '../../domain/models/ayah.dart';
import '../../../../core/theme/app_colors.dart';

import 'dart:ui' as ui;

class QuranReaderPage extends StatefulWidget {
  final int surahId;
  final int? scrollToAyah;

  const QuranReaderPage({super.key, required this.surahId, this.scrollToAyah});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  // Audio state
  final QuranAyahAudioService _audioService = QuranAyahAudioService.instance;
  String? _playingAyahKey; // "surah:ayah"
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    // Load data
    context.read<QuranReaderCubit>().loadSurah(
      widget.surahId,
      scrollToAyah: widget.scrollToAyah,
    );

    // Audio listener
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        if (mounted && _playingAyahKey != null) {
          setState(() {
            _playingAyahKey = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerStateSubscription?.cancel();
    _audioService
        .stop(); // Stop audio when leaving text mode? Maybe. Use judgement.
    super.dispose();
  }

  void _playAyah(Ayah ayah) async {
    final key = "${ayah.surahId}:${ayah.ayahNumber}";
    if (_playingAyahKey == key) {
      // Stop
      await _audioService.stop();
      setState(() {
        _playingAyahKey = null;
      });
    } else {
      // Play
      setState(() {
        _playingAyahKey = key;
      });
      await _audioService.playAyah(ayah.surahId, ayah.ayahNumber);
    }
  }

  void _scrollToAyah(int ayahNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _ayahKeys[ayahNumber];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<QuranReaderCubit, QuranReaderState>(
          builder: (context, state) {
            if (state is QuranReaderLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.surah.nameAr,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    state.surah.nameEn,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }
            return const Text("");
          },
        ),
        actions: [
          // Switch Mode Button
          IconButton(
            icon: const Icon(Icons.menu_book), // Icon for Mushaf
            tooltip: "quran.mode_mushaf".tr(),
            onPressed: () async {
              // Switch to Mushaf
              await QuranUserDataRepository().setQuranViewMode("mushaf_images");
              if (context.mounted) {
                GoRouter.of(context).go('/quran/mushaf');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<QuranReaderCubit, QuranReaderState>(
        listener: (context, state) {
          if (state is QuranReaderLoaded) {
            if (widget.scrollToAyah != null) {
              // Determine if we need to scroll. Simple auto-scroll on first load.
              // For now relying on user interaction or simple scroll on build completion
              Future.delayed(const Duration(milliseconds: 300), () {
                _scrollToAyah(widget.scrollToAyah!);
              });
            }
          }
        },
        builder: (context, state) {
          if (state is QuranReaderLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuranReaderError) {
            return Center(child: Text(state.message));
          }
          if (state is QuranReaderLoaded) {
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.ayahs.length,
              itemBuilder: (context, index) {
                final ayah = state.ayahs[index];
                _ayahKeys[ayah.ayahNumber] = GlobalKey();
                final key = "${ayah.surahId}:${ayah.ayahNumber}";
                final isPlaying = _playingAyahKey == key;

                return _AyahCard(
                  key: _ayahKeys[ayah.ayahNumber],
                  ayah: ayah,
                  fontSize: state.fontSize,
                  fontFamily: state.fontFamily,
                  isBookmarked: state.bookmarks.contains(ayah.key),
                  isFavorite: state.favorites.contains(ayah.key),
                  isPlaying: isPlaying,
                  onTap: () =>
                      context.read<QuranReaderCubit>().setLastRead(ayah),
                  onBookmark: () =>
                      context.read<QuranReaderCubit>().toggleBookmark(ayah),
                  onFavorite: () =>
                      context.read<QuranReaderCubit>().toggleFavorite(ayah),
                  onPlay: () => _playAyah(ayah),
                  onViewInMushaf: () {
                    // Deep link to Mushaf Page
                    // We need page number. Ayah model has it?
                    final page = ayah.page;
                    if (page != null) {
                      QuranUserDataRepository().setQuranViewMode(
                        "mushaf_images",
                      );
                      context.go(
                        '/quran/mushaf?page=$page',
                      ); // Pass page as query param
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Page not found")),
                      );
                    }
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    // Reuse existing or simplify.
    final cubit = context.read<QuranReaderCubit>();
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const _ReaderSettingsSheet()),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final String fontFamily;
  final bool isBookmarked;
  final bool isFavorite;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onFavorite;
  final VoidCallback onPlay;
  final VoidCallback onViewInMushaf;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.fontFamily,
    required this.isBookmarked,
    required this.isFavorite,
    required this.isPlaying,
    required this.onTap,
    required this.onBookmark,
    required this.onFavorite,
    required this.onPlay,
    required this.onViewInMushaf,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;
    switch (fontFamily) {
      case 'Amiri':
        textStyle = GoogleFonts.amiri(fontSize: fontSize, height: 2.2);
        break;
      case 'Cairo':
        textStyle = GoogleFonts.cairo(fontSize: fontSize, height: 1.8);
        break;
      case 'Tajawal':
        textStyle = GoogleFonts.tajawal(fontSize: fontSize, height: 1.8);
        break;
      default:
        textStyle = GoogleFonts.amiri(fontSize: fontSize, height: 2.2);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPlaying
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      "${ayah.ayahNumber}",
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle_outline,
                        ),
                        onPressed: onPlay,
                        color: isPlaying ? Colors.red : null,
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        onPressed: onBookmark,
                        color: isBookmarked ? AppColors.primary : null,
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite
                              ? FontAwesomeIcons.solidHeart
                              : FontAwesomeIcons.heart,
                          size: 18,
                        ),
                        onPressed: onFavorite,
                        color: isFavorite ? Colors.red : null,
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: onViewInMushaf,
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book, size: 18),
                                const SizedBox(width: 8),
                                Text("quran.open_in_mushaf".tr()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ayah.textAr,
                style: textStyle,
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    // Simplified Settings
    final List<String> fontFamilies = ['Amiri', 'Cairo', 'Tajawal'];

    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      builder: (context, state) {
        if (state is! QuranReaderLoaded) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "quran.font_size".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: state.fontSize,
                min: 16,
                max: 44,
                divisions: 14,
                label: state.fontSize.toString(),
                onChanged: (v) =>
                    context.read<QuranReaderCubit>().setFontSize(v),
              ),
              const SizedBox(height: 16),
              Text(
                "quran.font_family".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: fontFamilies
                    .map(
                      (f) => ChoiceChip(
                        label: Text(f),
                        selected: state.fontFamily == f,
                        onSelected: (s) {
                          if (s)
                            context.read<QuranReaderCubit>().setFontFamily(f);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
