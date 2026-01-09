import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../cubit/quran_reader_cubit.dart';
import '../../domain/models/ayah.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/mushaf_view.dart';
import '../widgets/quran_page_view.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';
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
  String? _lastKnownViewMode; // Preserve viewMode during loading states

  @override
  void initState() {
    super.initState();
    context.read<QuranReaderCubit>().loadSurah(
      widget.surahId,
      scrollToAyah: widget.scrollToAyah,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        String viewMode = 'card';

        if (settingsState is SettingsLoaded) {
          viewMode = settingsState.settings.quranSettings.viewMode;
          _lastKnownViewMode = viewMode; // Store the last known viewMode
        } else if (_lastKnownViewMode != null) {
          // Use the last known viewMode during loading to prevent flickering
          viewMode = _lastKnownViewMode!;
        }

        return BlocConsumer<QuranReaderCubit, QuranReaderState>(
          listener: (context, state) {
            if (state is QuranReaderLoaded && state.activeAyah != null) {
              if (viewMode == 'card') {
                _scrollToAyah(state.activeAyah!);
              }
            }
          },
          builder: (context, state) {
            if (state is QuranReaderLoading) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is QuranReaderError) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text(state.message),
                    ],
                  ),
                ),
              );
            }

            if (state is QuranReaderLoaded) {
              if (viewMode == 'page' && state.pages != null) {
                // Determine initial page
                int initialPage = 1;
                if (state.activeAyah != null) {
                  // Find the page containing activeAyah
                  for (final entry in state.pages!.entries) {
                    if (entry.value.any(
                      (a) => a.ayahNumber == state.activeAyah,
                    )) {
                      initialPage = entry.key;
                      break;
                    }
                  }
                } else if (state.pages!.isNotEmpty) {
                  initialPage = state.pages!.keys.first;
                }

                return Scaffold(
                  appBar: _buildAppBar(context, state, viewMode),
                  body: QuranPageView(
                    pages: state.pages!,
                    surah: state.surah,
                    fontSize: state.fontSize,
                    fontFamily: state.fontFamily,
                    bookmarks: state.bookmarks,
                    favorites: state.favorites,
                    activeAyah: state.activeAyah,
                    initialPage: initialPage,
                    onTapAyah: (ayah) => _showAyahActions(context, ayah, state),
                    onPageChanged: (pageNum) {
                      // Find first ayah of this page and set as last read
                      final pageAyahs = state.pages![pageNum];
                      if (pageAyahs != null && pageAyahs.isNotEmpty) {
                        context.read<QuranReaderCubit>().setLastRead(
                          pageAyahs.first,
                        );
                      }
                    },
                  ),
                );
              }

              return Scaffold(
                appBar: _buildAppBar(context, state, viewMode),
                body: viewMode == 'mushaf'
                    ? MushafView(
                        surah: state.surah,
                        ayahs: state.ayahs,
                        fontSize: state.fontSize,
                        fontFamily: state.fontFamily,
                        bookmarks: state.bookmarks,
                        favorites: state.favorites,
                        activeAyah: state.activeAyah,
                        onTapAyah: (ayah) =>
                            _showAyahActions(context, ayah, state),
                        onShareAyah: (ayah) =>
                            context.read<QuranReaderCubit>().shareAyah(ayah),
                        onToggleBookmark: (ayah) => context
                            .read<QuranReaderCubit>()
                            .toggleBookmark(ayah),
                        onToggleFavorite: (ayah) => context
                            .read<QuranReaderCubit>()
                            .toggleFavorite(ayah),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.ayahs.length,
                        itemBuilder: (context, index) {
                          final ayah = state.ayahs[index];
                          _ayahKeys[ayah.ayahNumber] = GlobalKey();

                          return _AyahCard(
                            key: _ayahKeys[ayah.ayahNumber],
                            ayah: ayah,
                            fontSize: state.fontSize,
                            fontFamily: state.fontFamily,
                            isBookmarked: state.bookmarks.contains(ayah.key),
                            isFavorite: state.favorites.contains(ayah.key),
                            isActive: state.activeAyah == ayah.ayahNumber,
                            onTap: () {
                              context.read<QuranReaderCubit>().setLastRead(
                                ayah,
                              );
                            },
                            onBookmark: () {
                              context.read<QuranReaderCubit>().toggleBookmark(
                                ayah,
                              );
                            },
                            onFavorite: () {
                              context.read<QuranReaderCubit>().toggleFavorite(
                                ayah,
                              );
                            },
                            onShare: () {
                              context.read<QuranReaderCubit>().shareAyah(ayah);
                            },
                          );
                        },
                      ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    QuranReaderLoaded state,
    String viewMode,
  ) {
    IconData viewIcon;
    switch (viewMode) {
      case 'card':
        viewIcon = Icons.view_list; // Icon to switch FROM card (to mushaf/page)
        break;
      case 'mushaf':
        viewIcon = Icons.menu_book;
        break;
      case 'page':
        viewIcon = Icons.auto_stories;
        break;
      default:
        viewIcon = Icons.view_list;
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state.surah.nameAr, style: const TextStyle(fontSize: 18)),
          Text(
            state.surah.nameEn,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(viewIcon),
          tooltip: "quran.view_mode".tr(),
          onPressed: () => _toggleViewMode(context, viewMode),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettingsSheet(context, state),
        ),
      ],
    );
  }

  void _toggleViewMode(BuildContext context, String currentMode) {
    final newMode = switch (currentMode) {
      'card' => 'mushaf',
      'mushaf' => 'page',
      'page' => 'card',
      _ => 'card',
    };
    final settingsCubit = context.read<SettingsCubit>();
    if (settingsCubit.state is SettingsLoaded) {
      final currentSettings = (settingsCubit.state as SettingsLoaded).settings;
      final newQuranSettings = currentSettings.quranSettings.copyWith(
        viewMode: newMode,
      );
      settingsCubit.saveSettings(
        currentSettings.copyWith(quranSettings: newQuranSettings),
        skipNotificationReschedule:
            true, // View mode change shouldn't trigger notifications
      );
    }
  }

  void _showAyahActions(
    BuildContext context,
    Ayah ayah,
    QuranReaderLoaded state,
  ) {
    final cubit = context.read<QuranReaderCubit>();

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Provide the cubit to the sheet context
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
            builder: (context, currentState) {
              if (currentState is! QuranReaderLoaded) {
                return const SizedBox.shrink();
              }

              final isBookmarked = currentState.bookmarks.contains(ayah.key);
              final isFavorite = currentState.favorites.contains(ayah.key);

              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        '${currentState.surah.nameAr} - ${"quran.ayahs".tr()} ${ayah.ayahNumber}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? AppColors.primary : null,
                      ),
                      title: Text("quran.bookmark".tr()),
                      onTap: () {
                        context.read<QuranReaderCubit>().toggleBookmark(ayah);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        isFavorite
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: isFavorite ? Colors.red : null,
                      ),
                      title: Text("quran.favorite".tr()),
                      onTap: () {
                        context.read<QuranReaderCubit>().toggleFavorite(ayah);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: Text("quran.share".tr()),
                      onTap: () {
                        context.read<QuranReaderCubit>().shareAyah(ayah);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context, QuranReaderLoaded state) {
    final cubit = context.read<QuranReaderCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: const _ReaderSettingsSheet(),
        );
      },
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final String fontFamily;
  final bool isBookmarked;
  final bool isFavorite;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.fontFamily,
    required this.isBookmarked,
    required this.isFavorite,
    required this.isActive,
    required this.onTap,
    required this.onBookmark,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;

    switch (fontFamily) {
      case 'Amiri':
        textStyle = GoogleFonts.amiri(fontSize: fontSize, height: 2.0);
        break;
      case 'Cairo':
        textStyle = GoogleFonts.cairo(fontSize: fontSize, height: 1.8);
        break;
      case 'Tajawal':
        textStyle = GoogleFonts.tajawal(fontSize: fontSize, height: 1.8);
        break;
      default:
        textStyle = GoogleFonts.amiri(fontSize: fontSize, height: 2.0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ayah number badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ayah.ayahNumber.toString(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? AppColors.primary : null,
                          size: 20,
                        ),
                        onPressed: onBookmark,
                        tooltip: "quran.bookmark".tr(),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite
                              ? FontAwesomeIcons.solidHeart
                              : FontAwesomeIcons.heart,
                          color: isFavorite ? Colors.red : null,
                          size: 18,
                        ),
                        onPressed: onFavorite,
                        tooltip: "quran.favorite".tr(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: onShare,
                        tooltip: "quran.share".tr(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ayah text
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
    final List<String> fontFamilies = ['Amiri', 'Cairo', 'Tajawal'];

    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      builder: (context, state) {
        if (state is! QuranReaderLoaded) {
          return const SizedBox.shrink();
        }

        final fontSize = state.fontSize;
        final fontFamily = state.fontFamily;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              Text(
                "quran.reader_settings".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Font size slider
              Text(
                "quran.font_size".tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('quran.a'.tr(), style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 16,
                      max: 40,
                      divisions: 12,
                      label: fontSize.toInt().toString(),
                      onChanged: (value) {
                        // Update cubit state (this also saves, but with skipNotificationReschedule)
                        context.read<QuranReaderCubit>().setFontSize(value);
                      },
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 28)),
                ],
              ),

              const SizedBox(height: 24),

              // Font family selector
              Text(
                "quran.font_family".tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: fontFamilies.map((family) {
                  final isSelected = fontFamily == family;
                  return ChoiceChip(
                    label: Text(_getLocalizedFontName(family)),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) {
                        context.read<QuranReaderCubit>().setFontFamily(family);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Text(
                "quran.view_mode".tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'card',
                    label: Text("quran.view_mode_card".tr()),
                    icon: const Icon(Icons.view_list),
                  ),
                  ButtonSegment(
                    value: 'mushaf',
                    label: Text("quran.view_mode_mushaf".tr()),
                    icon: const Icon(Icons.menu_book),
                  ),
                  ButtonSegment(
                    value: 'page',
                    label: Text("quran.view_mode_page".tr()),
                    icon: const Icon(Icons.auto_stories),
                  ),
                ],
                selected: {
                  (context.watch<SettingsCubit>().state is SettingsLoaded)
                      ? (context.watch<SettingsCubit>().state as SettingsLoaded)
                            .settings
                            .quranSettings
                            .viewMode
                      : 'card',
                },
                // Wait, QuranReaderState doesn't have viewMode. It's in Settings.
                // We need to access settings here.
                // Actually this sheet is wrapped in BlocProvider value=cubit.
                // But we need SettingsCubit to read current mode, or pass it in.
                // _ReaderSettingsSheet is inside QuranReaderPage which has BlocBuilder<SettingsCubit>.
                // We need to fetch SettingsCubit inside here.
                onSelectionChanged: (Set<String> newSelection) {
                  final newMode = newSelection.first;
                  final settingsCubit = context.read<SettingsCubit>();
                  // Call save logic similar to toggle
                  if (settingsCubit.state is SettingsLoaded) {
                    final current =
                        (settingsCubit.state as SettingsLoaded).settings;
                    final newQuran = current.quranSettings.copyWith(
                      viewMode: newMode,
                    );
                    settingsCubit.saveSettings(
                      current.copyWith(quranSettings: newQuran),
                      skipNotificationReschedule: true,
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: _getTextStyle(fontSize, fontFamily),
                  textAlign: TextAlign.center,
                  textDirection: ui.TextDirection.rtl,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _getLocalizedFontName(String fontFamily) {
    switch (fontFamily) {
      case 'Amiri':
        return "quran.amiri".tr();
      case 'Cairo':
        return "quran.cairo".tr();
      case 'Tajawal':
        return "quran.tajawal".tr();
      default:
        return fontFamily;
    }
  }

  TextStyle _getTextStyle(double fontSize, String fontFamily) {
    switch (fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(fontSize: fontSize, height: 2.0);
      case 'Cairo':
        return GoogleFonts.cairo(fontSize: fontSize, height: 1.8);
      case 'Tajawal':
        return GoogleFonts.tajawal(fontSize: fontSize, height: 1.8);
      default:
        return GoogleFonts.amiri(fontSize: fontSize, height: 2.0);
    }
  }
}
