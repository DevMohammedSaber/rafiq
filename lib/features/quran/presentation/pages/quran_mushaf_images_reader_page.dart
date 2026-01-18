import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../mushaf/data/mushaf_zip_installer.dart';
import '../../settings/quran_settings_repository.dart';
import '../../data/quran_user_data_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Mode 2: Mushaf Images Reader with tap-to-toggle immersive UI
class QuranMushafImagesReaderPage extends StatefulWidget {
  final int? initialPage;

  const QuranMushafImagesReaderPage({super.key, this.initialPage});

  @override
  State<QuranMushafImagesReaderPage> createState() =>
      _QuranMushafImagesReaderPageState();
}

class _QuranMushafImagesReaderPageState
    extends State<QuranMushafImagesReaderPage> {
  final _settingsRepo = QuranSettingsRepository();
  final _userDataRepo = QuranUserDataRepository();
  final _installer = MushafZipInstaller(Dio());

  late PageController _pageController;
  int _currentPage = 1;
  final int _totalPages = 604;
  bool _isLoading = true;
  String? _pagesPath;
  String? _error;
  bool _isOverlayVisible = true;
  Set<String> _bookmarkedPages = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 1;
    _pageController = PageController(initialPage: _currentPage - 1);
    _init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final mushafId = await _settingsRepo.getSelectedMushafId();
      if (mushafId == null) {
        if (mounted) {
          _redirectToStore();
        }
        return;
      }

      final installed = await _installer.isMushafInstalled(mushafId);
      if (!installed) {
        if (mounted) _redirectToStore();
        return;
      }

      final path = await _installer.getMushafPagesPath(mushafId);

      // Load last read page if no initial page provided
      int startPage = widget.initialPage ?? 1;
      if (widget.initialPage == null) {
        final lastPage = await _settingsRepo.getLastMushafPage();
        if (lastPage != null) {
          startPage = lastPage;
        }
      }

      // Load bookmarks
      final bookmarks = await _userDataRepo.listBookmarks();
      final pageBookmarks = bookmarks
          .where((b) => b.startsWith('page:'))
          .toSet();

      setState(() {
        _pagesPath = path;
        _currentPage = startPage.clamp(1, _totalPages);
        _bookmarkedPages = pageBookmarks;
        _isLoading = false;
      });

      // Update page controller
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage - 1);
      } else {
        _pageController = PageController(initialPage: _currentPage - 1);
      }

      _saveLastRead(_currentPage);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _redirectToStore() {
    setState(() {
      _error = 'not_installed';
      _isLoading = false;
    });
  }

  void _saveLastRead(int page) {
    _settingsRepo.setLastMushafPage(page);
  }

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });

    if (_isOverlayVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  void _jumpToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _pageController.jumpToPage(page - 1);
    _saveLastRead(page);
  }

  void _showJumpDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('quran.jump_to_page'.tr()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              _jumpToPage(page);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _jumpToPage(page);
              }
              Navigator.pop(context);
            },
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePageBookmark() async {
    final key = 'page:$_currentPage';
    if (_bookmarkedPages.contains(key)) {
      // Remove bookmark
      await _userDataRepo.removeBookmarkAyah(
        0,
        _currentPage,
      ); // Using ayah=page for simplicity
      setState(() {
        _bookmarkedPages.remove(key);
      });
    } else {
      // Add bookmark
      await _userDataRepo.addBookmarkAyah(0, _currentPage);
      setState(() {
        _bookmarkedPages.add(key);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error == 'not_installed') {
      return Scaffold(
        appBar: AppBar(title: Text('quran.mode_mushaf'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 64,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'quran.not_downloaded'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'quran.download_mushaf_hint'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/quran/mushaf/store').then((_) => _init());
                  },
                  icon: const Icon(Icons.download),
                  label: Text('quran.mushaf_store'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _init,
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final isBookmarked = _bookmarkedPages.contains('page:$_currentPage');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mushaf Reader (PhotoViewGallery)
          GestureDetector(
            onTap: _toggleOverlay,
            child: PhotoViewGallery.builder(
              itemCount: _totalPages,
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              reverse: true, // RTL: Page 1 is on the right
              builder: (context, index) {
                final pageNum = index + 1;
                final imagePath = _getImagePath(pageNum);

                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(imagePath)),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'page_$pageNum'),
                );
              },
              onPageChanged: (index) {
                final pageNum = index + 1;
                setState(() {
                  _currentPage = pageNum;
                });
                _saveLastRead(pageNum);
              },
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: event?.expectedTotalBytes != null
                        ? event!.cumulativeBytesLoaded /
                              event.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),

          // Hint for hidden tools (shown briefly)
          if (!_isOverlayVisible)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isOverlayVisible ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'quran.tools_hidden_hint'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),

          // Top Bar
          if (_isOverlayVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                currentPage: _currentPage,
                totalPages: _totalPages,
                isBookmarked: isBookmarked,
                onBack: () => Navigator.of(context).pop(),
                onJump: _showJumpDialog,
                onBookmark: _togglePageBookmark,
                onSettings: () => _showSettingsSheet(),
              ),
            ),

          // Bottom Slider
          if (_isOverlayVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomSlider(
                currentPage: _currentPage,
                totalPages: _totalPages,
                onPageChanged: _jumpToPage,
              ),
            ),
        ],
      ),
    );
  }

  String _getImagePath(int pageNum) {
    // Try different extensions
    final baseName = pageNum.toString().padLeft(3, '0');
    final pngPath = p.join(_pagesPath!, '$baseName.png');
    final jpgPath = p.join(_pagesPath!, '$baseName.jpg');

    if (File(pngPath).existsSync()) return pngPath;
    if (File(jpgPath).existsSync()) return jpgPath;
    return pngPath; // Default
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MushafSettingsSheet(
        onChangeMushaf: () {
          Navigator.pop(context);
          context.push('/quran/mushaf/store').then((_) => _init());
        },
        onSwitchToText: () {
          Navigator.pop(context);
          _settingsRepo.setViewMode('text');
          context.go('/quran/text/1');
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onJump;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;

  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.onBack,
    required this.onJump,
    required this.onBookmark,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onJump,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${'quran.page'.tr()} $currentPage / $totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppColors.primary : Colors.white,
                ),
                onPressed: onBookmark,
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSlider extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _BottomSlider({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('1', style: const TextStyle(color: Colors.white)),
              Expanded(
                child: Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Slider(
                    value: currentPage.toDouble(),
                    min: 1,
                    max: totalPages.toDouble(),
                    divisions: totalPages - 1,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.white30,
                    onChanged: (val) => onPageChanged(val.toInt()),
                  ),
                ),
              ),
              Text('$totalPages', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafSettingsSheet extends StatelessWidget {
  final VoidCallback onChangeMushaf;
  final VoidCallback onSwitchToText;

  const _MushafSettingsSheet({
    required this.onChangeMushaf,
    required this.onSwitchToText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          ListTile(
            leading: const Icon(Icons.download),
            title: Text('quran.mushaf_store'.tr()),
            subtitle: Text('quran.change_mushaf'.tr()),
            onTap: onChangeMushaf,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text('quran.mode_text'.tr()),
            subtitle: Text('quran.switch_to_text'.tr()),
            onTap: onSwitchToText,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
