import 'dart:async';
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
import '../widgets/mushaf_page_view.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';
import '../../data/mushaf_data_repository.dart';
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
  bool _hasRestoredScroll = false;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsCubit>().state;
    String viewMode = 'card';
    if (settingsState is SettingsLoaded) {
      viewMode = settingsState.settings.quranSettings.viewMode;
    }

    _scrollController.addListener(_onScroll);

    if (viewMode == 'page') {
      context.read<QuranReaderCubit>().loadMushaf();
    } else {
      context.read<QuranReaderCubit>().loadSurah(
        widget.surahId,
        scrollToAyah: widget.scrollToAyah,
      );
    }
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _saveScrollPositionDebounced();
    }
  }

  Timer? _saveScrollTimer;
  void _saveScrollPositionDebounced() {
    _saveScrollTimer?.cancel();
    _saveScrollTimer = Timer(const Duration(milliseconds: 500), () {
      _saveScrollPosition();
    });
  }

  void _saveScrollPosition() {
    if (!_scrollController.hasClients) return;

    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      final currentSettings = settingsState.settings;
      final quranSettings = currentSettings.quranSettings;
      final scrollPosition = _scrollController.offset;

      final updatedScrollPositions = Map<int, double>.from(
        quranSettings.scrollPositions,
      );
      updatedScrollPositions[widget.surahId] = scrollPosition;

      final newQuranSettings = quranSettings.copyWith(
        scrollPositions: updatedScrollPositions,
      );

      context.read<SettingsCubit>().saveSettings(
        currentSettings.copyWith(quranSettings: newQuranSettings),
        skipNotificationReschedule: true,
      );
    }
  }

  void _restoreScrollPosition() {
    if (_hasRestoredScroll) return;

    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      final savedPosition =
          settingsState.settings.quranSettings.scrollPositions[widget.surahId];

      if (savedPosition != null && savedPosition > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && !_hasRestoredScroll) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            final positionToRestore = savedPosition > maxScroll
                ? maxScroll
                : savedPosition;
            _scrollController.jumpTo(positionToRestore);
            _hasRestoredScroll = true;
          }
        });
      } else {
        _hasRestoredScroll = true;
      }
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
            if (state is QuranReaderLoaded && viewMode == 'card') {
              if (state.activeAyah != null && widget.scrollToAyah != null) {
                _scrollToAyah(state.activeAyah!);
                _hasRestoredScroll = true;
              } else if (!_hasRestoredScroll && widget.scrollToAyah == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _restoreScrollPosition();
                });
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

            if (state is MushafReaderLoaded && viewMode == 'page') {
              return Scaffold(
                appBar: _buildMushafAppBar(context, state),
                body: MushafPageView(
                  totalPages: state.totalPages,
                  initialPage: state.currentPage,
                  fontSize: state.fontSize,
                  fontFamily: state.fontFamily,
                  bookmarks: state.bookmarks,
                  favorites: state.favorites,
                  onTapAyah: (ayah) =>
                      _showMushafAyahActions(context, ayah, state),
                  onPageChanged: (pageNum) {
                    context.read<QuranReaderCubit>().jumpToPage(pageNum);
                  },
                  cubit: context.read<QuranReaderCubit>(),
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
                        onShareAyah: (ayah) {
                          final RenderBox? box =
                              context.findRenderObject() as RenderBox?;
                          context.read<QuranReaderCubit>().shareAyah(
                            ayah,
                            sharePositionOrigin: box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : null,
                          );
                        },
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
                              final RenderBox? box =
                                  context.findRenderObject() as RenderBox?;
                              context.read<QuranReaderCubit>().shareAyah(
                                ayah,
                                sharePositionOrigin: box != null
                                    ? box.localToGlobal(Offset.zero) & box.size
                                    : null,
                              );
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

  PreferredSizeWidget _buildMushafAppBar(
    BuildContext context,
    MushafReaderLoaded state,
  ) {
    return AppBar(
      title: Text("quran.open_mushaf".tr()),
      actions: [
        IconButton(
          icon: const Icon(Icons.numbers),
          tooltip: "quran.goto_page".tr(),
          onPressed: () => _showGoToPageDialog(context, state),
        ),
        IconButton(
          icon: const Icon(Icons.list),
          tooltip: "quran.goto_surah".tr(),
          onPressed: () => _showSurahListDialog(context, state),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: "quran.goto_ayah".tr(),
          onPressed: () => _showGoToAyahDialog(context, state),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: "quran.page_number".tr(),
          onPressed: () => _showPageSlider(context, state),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showMushafSettingsSheet(context, state),
        ),
      ],
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
                        // For bottom sheet, we can use the sheet's own context or just null
                        // but it's better to provide something.
                        final RenderBox? box =
                            context.findRenderObject() as RenderBox?;
                        context.read<QuranReaderCubit>().shareAyah(
                          ayah,
                          sharePositionOrigin: box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null,
                        );
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

extension _MushafNavigationMethods on _QuranReaderPageState {
  void _showGoToPageDialog(BuildContext context, MushafReaderLoaded state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("quran.goto_page".tr()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "quran.page_number_hint".tr(),
            labelText: "quran.page_number".tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              final pageNum = int.tryParse(controller.text);
              if (pageNum != null &&
                  pageNum >= 1 &&
                  pageNum <= state.totalPages) {
                context.read<QuranReaderCubit>().jumpToPage(pageNum);
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("quran.invalid_page".tr())),
                );
              }
            },
            child: Text("common.continue".tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showSurahListDialog(
    BuildContext context,
    MushafReaderLoaded state,
  ) async {
    final mushafRepo = MushafDataRepository();
    await mushafRepo.loadIndex();
    final surahs = await mushafRepo.getSurahs();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "quran.goto_surah".tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(surah.id.toString())),
                    title: Text(
                      surah.nameAr,
                      textDirection: ui.TextDirection.rtl,
                    ),
                    subtitle: Text(surah.nameEn),
                    onTap: () {
                      context.read<QuranReaderCubit>().jumpToSurah(surah.id);
                      Navigator.pop(sheetContext);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoToAyahDialog(BuildContext context, MushafReaderLoaded state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("quran.goto_ayah".tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "quran.ayah_input_hint".tr(),
            labelText: "quran.ayah_input_hint".tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              final input = controller.text.trim();
              final parts = input.split(':');
              if (parts.length == 2) {
                final surahId = int.tryParse(parts[0]);
                final ayahNumber = int.tryParse(parts[1]);
                if (surahId != null && ayahNumber != null) {
                  context.read<QuranReaderCubit>().jumpToAyah(
                    surahId,
                    ayahNumber,
                  );
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("quran.invalid_ayah_format".tr())),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("quran.invalid_ayah_format".tr())),
                );
              }
            },
            child: Text("common.continue".tr()),
          ),
        ],
      ),
    );
  }

  void _showPageSlider(BuildContext context, MushafReaderLoaded state) {
    double sliderValue = state.currentPage.toDouble();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${"quran.page_number".tr()} ${sliderValue.toInt()}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: sliderValue,
                min: 1,
                max: state.totalPages.toDouble(),
                divisions: state.totalPages - 1,
                label: sliderValue.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    sliderValue = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text("common.cancel".tr()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QuranReaderCubit>().jumpToPage(
                        sliderValue.toInt(),
                      );
                      Navigator.pop(sheetContext);
                    },
                    child: Text("common.continue".tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMushafAyahActions(
    BuildContext context,
    Ayah ayah,
    MushafReaderLoaded state,
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
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
            builder: (context, currentState) {
              if (currentState is! MushafReaderLoaded) {
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
                        '${"quran.surah".tr()} ${ayah.surahId} - ${"quran.ayahs".tr()} ${ayah.ayahNumber}',
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
                        cubit.toggleBookmark(ayah);
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
                        cubit.toggleFavorite(ayah);
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

  void _showMushafSettingsSheet(
    BuildContext context,
    MushafReaderLoaded state,
  ) {
    final cubit = context.read<QuranReaderCubit>();
    final List<String> fontFamilies = ['Amiri', 'Cairo', 'Tajawal'];

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
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  "quran.font_size".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('quran.a'.tr(), style: const TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: state.fontSize,
                        min: 16,
                        max: 40,
                        divisions: 12,
                        label: state.fontSize.toInt().toString(),
                        onChanged: (value) {
                          cubit.setMushafFontSize(value);
                        },
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "quran.font_family".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: fontFamilies.map((family) {
                    final isSelected = state.fontFamily == family;
                    return ChoiceChip(
                      label: Text(_getLocalizedFontNameForMushaf(family)),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) {
                          cubit.setMushafFontFamily(family);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLocalizedFontNameForMushaf(String fontFamily) {
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
}
