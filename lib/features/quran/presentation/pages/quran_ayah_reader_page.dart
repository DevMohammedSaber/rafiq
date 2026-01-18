import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

import '../../audio/quran_audio_player_service.dart';
import '../../data/quran_repository.dart';
import '../../data/quran_user_data_repository.dart';
import '../../settings/quran_settings_repository.dart';
import '../../domain/models/ayah.dart';
import '../../domain/models/surah.dart';
import '../../../../core/theme/app_colors.dart';

/// Mode 1: Ayah-by-Ayah Text Reader with Audio Synchronized Highlighting
class QuranAyahReaderPage extends StatefulWidget {
  final int surahId;
  final int? scrollToAyah;

  const QuranAyahReaderPage({
    super.key,
    required this.surahId,
    this.scrollToAyah,
  });

  @override
  State<QuranAyahReaderPage> createState() => _QuranAyahReaderPageState();
}

class _QuranAyahReaderPageState extends State<QuranAyahReaderPage> {
  final _quranRepo = QuranRepository();
  final _userDataRepo = QuranUserDataRepository();
  final _settingsRepo = QuranSettingsRepository();
  final _audioService = QuranAudioPlayerService.instance;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  Surah? _surah;
  List<Ayah> _ayahs = [];
  Set<String> _bookmarks = {};
  Set<String> _favorites = {};
  double _fontSize = 24.0;
  String _fontFamily = 'Amiri';
  String _reciterId = 'mishary';
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _audioStateSubscription;
  StreamSubscription? _playerStateSubscription;
  QuranAudioState _audioState = const QuranAudioState();

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioStateSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  void _setupAudioListeners() {
    // Listen to audio state changes
    _audioStateSubscription = _audioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _audioState = state;
        });
      }
    });

    // Listen for playback completion to auto-advance
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      // Only handle completion when:
      // 1. Processing state is completed
      // 2. We have a valid current ayah
      // 3. We're in the current surah
      // 4. Audio was actually playing (not loading)
      if (state.processingState == ProcessingState.completed &&
          _audioState.currentAyah != null &&
          _audioState.currentSurah == widget.surahId &&
          !_audioState.isLoading) {
        _onAyahPlaybackComplete();
      }
    });
  }

  int? _lastCompletedAyah; // Track which ayah we last auto-advanced from
  bool _isAdvancing = false; // Flag to prevent double-triggering

  void _onAyahPlaybackComplete() {
    // Prevent double-triggering
    if (_isAdvancing) return;

    final currentAyahNumber = _audioState.currentAyah;
    if (currentAyahNumber == null) return;

    // Ignore if we already handled this ayah's completion
    if (_lastCompletedAyah == currentAyahNumber) {
      print(
        '[QuranAyahReader] Ignoring duplicate completion for ayah $currentAyahNumber',
      );
      return;
    }

    _isAdvancing = true;
    _lastCompletedAyah = currentAyahNumber;

    print('[QuranAyahReader] Auto-advance from ayah $currentAyahNumber');

    // Find current ayah index in the list
    final currentIndex = _ayahs.indexWhere(
      (a) => a.ayahNumber == currentAyahNumber,
    );

    if (currentIndex >= 0 && currentIndex < _ayahs.length - 1) {
      final nextAyah = _ayahs[currentIndex + 1];
      print('[QuranAyahReader] Next ayah: ${nextAyah.ayahNumber}');

      // Delay to ensure state is updated before playing next
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _playAyah(nextAyah);
          _scrollToAyah(nextAyah.ayahNumber);
        }
        _isAdvancing = false;
      });
    } else {
      // End of surah
      print('[QuranAyahReader] End of surah reached');
      _audioService.stop();
      _isAdvancing = false;
      _lastCompletedAyah = null;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final surah = await _quranRepo.getSurahById(widget.surahId);
      if (surah == null) {
        setState(() {
          _error = 'Surah not found';
          _isLoading = false;
        });
        return;
      }

      final ayahs = await _quranRepo.loadAyahs(widget.surahId);
      final bookmarks = await _userDataRepo.listBookmarks();
      final favorites = await _userDataRepo.listFavorites();
      final settings = await _settingsRepo.loadAll();

      // Debug: log first few ayah numbers to check indexing
      if (ayahs.isNotEmpty) {
        print(
          '[QuranAyahReader] Loaded ${ayahs.length} ayahs for surah ${widget.surahId}',
        );
        print(
          '[QuranAyahReader] First 3 ayah numbers: ${ayahs.take(3).map((a) => a.ayahNumber).toList()}',
        );
      }

      setState(() {
        _surah = surah;
        _ayahs = ayahs;
        _bookmarks = bookmarks;
        _favorites = favorites;
        _fontSize = settings.fontSize;
        _fontFamily = settings.fontFamily;
        _reciterId = settings.reciterId;
        _isLoading = false;
      });

      // Scroll to specific ayah if provided
      if (widget.scrollToAyah != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToAyah(widget.scrollToAyah!);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scrollToAyah(int ayahNumber) {
    final key = _ayahKeys[ayahNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _playAyah(Ayah ayah) async {
    print(
      '[QuranAyahReader] Play tapped for surah:${ayah.surahId} ayah:${ayah.ayahNumber}',
    );

    // Reset completion tracking when user manually selects a new ayah
    _lastCompletedAyah = null;
    _isAdvancing = false;

    if (_audioService.isAyahPlaying(ayah.surahId, ayah.ayahNumber)) {
      await _audioService.stop();
    } else {
      await _audioService.playAyah(
        ayah.surahId,
        ayah.ayahNumber,
        reciterId: _reciterId,
      );
    }
  }

  void _playNextAyah() {
    if (_audioState.currentAyah == null) return;
    final currentIndex = _ayahs.indexWhere(
      (a) => a.ayahNumber == _audioState.currentAyah,
    );
    if (currentIndex >= 0 && currentIndex < _ayahs.length - 1) {
      final nextAyah = _ayahs[currentIndex + 1];
      _playAyah(nextAyah);
      _scrollToAyah(nextAyah.ayahNumber);
    }
  }

  void _playPrevAyah() {
    if (_audioState.currentAyah == null) return;
    final currentIndex = _ayahs.indexWhere(
      (a) => a.ayahNumber == _audioState.currentAyah,
    );
    if (currentIndex > 0) {
      final prevAyah = _ayahs[currentIndex - 1];
      _playAyah(prevAyah);
      _scrollToAyah(prevAyah.ayahNumber);
    }
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    final isNowBookmarked = await _userDataRepo.toggleBookmark(
      ayah.surahId,
      ayah.ayahNumber,
    );
    setState(() {
      if (isNowBookmarked) {
        _bookmarks.add(ayah.key);
      } else {
        _bookmarks.remove(ayah.key);
      }
    });
  }

  Future<void> _toggleFavorite(Ayah ayah) async {
    final isNowFavorite = await _userDataRepo.toggleFavorite(
      ayah.surahId,
      ayah.ayahNumber,
    );
    setState(() {
      if (isNowFavorite) {
        _favorites.add(ayah.key);
      } else {
        _favorites.remove(ayah.key);
      }
    });
  }

  void _shareAyah(Ayah ayah, {Rect? sharePositionOrigin}) {
    final text =
        '${ayah.textAr}\n\n- ${_surah?.nameAr ?? ''} (${ayah.ayahNumber})';
    Share.share(text, sharePositionOrigin: sharePositionOrigin);
  }

  void _copyAyah(Ayah ayah) {
    final text =
        '${ayah.textAr}\n\n- ${_surah?.nameAr ?? ''} (${ayah.ayahNumber})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('common.copied'.tr())));
  }

  void _setLastRead(Ayah ayah) {
    _settingsRepo.setLastReadPosition(ayah.surahId, ayah.ayahNumber);
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(
        fontSize: _fontSize,
        fontFamily: _fontFamily,
        reciterId: _reciterId,
        onFontSizeChanged: (size) {
          setState(() => _fontSize = size);
          _settingsRepo.setFontSize(size);
        },
        onFontFamilyChanged: (family) {
          setState(() => _fontFamily = family);
          _settingsRepo.setFontFamily(family);
        },
        onReciterChanged: (id) {
          setState(() => _reciterId = id);
          _settingsRepo.setReciterId(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _surah != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_surah!.nameAr, style: const TextStyle(fontSize: 18)),
                  Text(
                    _surah!.nameEn,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Text('quran.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'quran.mode_mushaf'.tr(),
            onPressed: () {
              _settingsRepo.setViewMode('mushaf');
              context.go('/quran/mushaf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _audioState.currentSurah == widget.surahId
          ? _buildAudioControls()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _ayahs.length,
      itemBuilder: (context, index) {
        final ayah = _ayahs[index];
        _ayahKeys[ayah.ayahNumber] = GlobalKey();

        final isPlaying = _audioService.isAyahPlaying(
          ayah.surahId,
          ayah.ayahNumber,
        );
        final isCurrentAyah = _audioService.isCurrentAyah(
          ayah.surahId,
          ayah.ayahNumber,
        );

        return _AyahCard(
          key: _ayahKeys[ayah.ayahNumber],
          ayah: ayah,
          fontSize: _fontSize,
          fontFamily: _fontFamily,
          isBookmarked: _bookmarks.contains(ayah.key),
          isFavorite: _favorites.contains(ayah.key),
          isPlaying: isPlaying,
          isHighlighted: isCurrentAyah,
          onTap: () => _setLastRead(ayah),
          onPlay: () => _playAyah(ayah),
          onBookmark: () => _toggleBookmark(ayah),
          onFavorite: () => _toggleFavorite(ayah),
          onShare: (rect) => _shareAyah(ayah, sharePositionOrigin: rect),
          onCopy: () => _copyAyah(ayah),
        );
      },
    );
  }

  Widget _buildAudioControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: _playPrevAyah,
              tooltip: 'quran.prev'.tr(),
            ),
            const SizedBox(width: 8),
            _audioState.isLoading
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _audioState.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 48,
                    ),
                    color: AppColors.primary,
                    onPressed: () {
                      if (_audioState.isPlaying) {
                        _audioService.pause();
                      } else if (_audioState.currentAyah != null) {
                        _audioService.resume();
                      }
                    },
                  ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _playNextAyah,
              tooltip: 'quran.next'.tr(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () => _audioService.stop(),
              tooltip: 'quran.stop'.tr(),
            ),
            const Spacer(),
            Text(
              '${'quran.ayah'.tr()} ${_audioState.currentAyah ?? '-'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onBookmark;
  final VoidCallback onFavorite;
  final Function(Rect?) onShare;
  final VoidCallback onCopy;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.fontFamily,
    required this.isBookmarked,
    required this.isFavorite,
    required this.isPlaying,
    required this.isHighlighted,
    required this.onTap,
    required this.onPlay,
    required this.onBookmark,
    required this.onFavorite,
    required this.onShare,
    required this.onCopy,
  });

  TextStyle _getTextStyle() {
    switch (fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(fontSize: fontSize, height: 2.2);
      case 'Cairo':
        return GoogleFonts.cairo(fontSize: fontSize, height: 1.8);
      case 'Tajawal':
        return GoogleFonts.tajawal(fontSize: fontSize, height: 1.8);
      default:
        return GoogleFonts.amiri(fontSize: fontSize, height: 2.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      color: isHighlighted ? AppColors.primary.withValues(alpha: 0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${ayah.ayahNumber}',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle_outline,
                        ),
                        color: isPlaying ? Colors.red : null,
                        onPressed: onPlay,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        color: isBookmarked ? AppColors.primary : null,
                        onPressed: onBookmark,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite
                              ? FontAwesomeIcons.solidHeart
                              : FontAwesomeIcons.heart,
                          size: 18,
                        ),
                        color: isFavorite ? Colors.red : null,
                        onPressed: onFavorite,
                        visualDensity: VisualDensity.compact,
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                const Icon(Icons.share, size: 18),
                                const SizedBox(width: 8),
                                Text('quran.share'.tr()),
                              ],
                            ),
                            onTap: () {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              final rect = box != null
                                  ? box.localToGlobal(Offset.zero) & box.size
                                  : null;
                              onShare(rect);
                            },
                          ),
                          PopupMenuItem(
                            onTap: onCopy,
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 18),
                                const SizedBox(width: 8),
                                Text('common.copy'.tr()),
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
              // Ayah text
              SelectableText(
                ayah.textAr,
                style: _getTextStyle().copyWith(
                  color: isHighlighted ? AppColors.primary : null,
                ),
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

class _SettingsSheet extends StatefulWidget {
  final double fontSize;
  final String fontFamily;
  final String reciterId;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<String> onReciterChanged;

  const _SettingsSheet({
    required this.fontSize,
    required this.fontFamily,
    required this.reciterId,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onReciterChanged,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late double _fontSize;
  late String _fontFamily;
  late String _reciterId;

  final List<String> _fontFamilies = ['Amiri', 'Cairo', 'Tajawal'];
  final _audioService = QuranAudioPlayerService.instance;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _fontFamily = widget.fontFamily;
    _reciterId = widget.reciterId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'quran.reader_settings'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Font Size
          Text(
            'quran.font_size'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text('${'quran.a'.tr()}-', style: const TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 16,
                  max: 44,
                  divisions: 14,
                  label: _fontSize.toInt().toString(),
                  onChanged: (v) {
                    setState(() => _fontSize = v);
                    widget.onFontSizeChanged(v);
                  },
                ),
              ),
              Text('${'quran.a'.tr()}+', style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),

          // Font Family
          Text(
            'quran.font_family'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _fontFamilies.map((f) {
              return ChoiceChip(
                label: Text(f),
                selected: _fontFamily == f,
                onSelected: (s) {
                  if (s) {
                    setState(() => _fontFamily = f);
                    widget.onFontFamilyChanged(f);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Reciter
          Text(
            'quran.reciter'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(_audioService.availableReciters.map((reciter) {
            return RadioListTile<String>(
              value: reciter.id,
              groupValue: _reciterId,
              title: Text(reciter.nameAr),
              subtitle: Text(reciter.nameEn),
              onChanged: (id) {
                if (id != null) {
                  setState(() => _reciterId = id);
                  widget.onReciterChanged(id);
                }
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          })),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
