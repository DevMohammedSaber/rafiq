import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq/features/quran/mushaf/data/mushaf_zip_installer.dart';
import 'package:rafiq/features/quran/data/quran_user_data_repository.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:rafiq/features/quran/mushaf/presentation/pages/mushaf_store_page.dart';

class MushafReaderPage extends StatefulWidget {
  final int? initialPage; // 1..604

  const MushafReaderPage({super.key, this.initialPage});

  @override
  State<MushafReaderPage> createState() => _MushafReaderPageState();
}

class _MushafReaderPageState extends State<MushafReaderPage> {
  final _userDataRepo = QuranUserDataRepository();
  final _installer = MushafZipInstaller(Dio());

  late PageController _pageController;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _pagesPath;
  String? _error;
  bool _isOverlayVisible = true;

  @override
  void initState() {
    super.initState();
    // Default to page 1 if not provided
    _currentPage = widget.initialPage ?? 1;
    // We reverse the controller because Quran is RTL (Page 1 is rightmost)
    // But PageView.builder with RTL direction handles standard indexing?
    // Usually with Quran PageView:
    // Index 0 -> Page 1? Or Index 0 -> Page 604?
    // Let's assume standard LTR index 0 -> Page 1, but we use Directionality RTL.
    // If RTL, index 0 is on right. So Page 1 (Right) -> Index 0. Correct.
    _pageController = PageController(initialPage: _currentPage - 1);

    _init();
  }

  void _init() async {
    try {
      final mushafId = await _userDataRepo.getSelectedMushafId();
      if (mushafId == null) {
        // No mushaf selected
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
      setState(() {
        _pagesPath = path;
        _isLoading = false;
      });

      // Save initial read
      _saveLastRead(_currentPage);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _redirectToStore() {
    // Navigate to store, replace current?
    // Or show message. User said "If user tries to use Mushaf mode without installed mushaf: show an explanation + Open Mushaf Store button."
    setState(() {
      _error = "not_installed";
      _isLoading = false;
    });
  }

  void _saveLastRead(int page) {
    // TODO: Persist last read page globally if needed
    // _userDataRepo.setLastReadPage(page);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error == "not_installed") {
      return Scaffold(
        appBar: AppBar(title: Text("quran.mode_mushaf".tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("quran.not_downloaded".tr()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MushafStorePage()),
                  ).then((_) => _init());
                },
                child: Text("quran.mushaf_store".tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text("Error: $_error")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Reader
          GestureDetector(
            onTap: () {
              setState(() {
                _isOverlayVisible = !_isOverlayVisible;
              });
              if (_isOverlayVisible) {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              } else {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
              }
            },
            child: PhotoViewGallery.builder(
              itemCount: 604,
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              reverse:
                  true, // To make swipe direction natural for RTL (Right to Left swipes forward)
              // Wait, if Directionality is RTL, then index 0 is Right.
              // Next page (index 1) is to the Left. Swipe Right-to-Left moves to index 1.
              // So regular PageView in RTL works.
              // BUT PhotoViewGallery might ignore Directionality?
              // Let's test. Usually 'reverse: true' makes it start from right?
              // If I use Directionality(textDirection: RTL), PageView puts 0 on Right.
              builder: (context, index) {
                // index 0 -> Page 1
                final pageNum = index + 1;
                final imagePath = p.join(
                  _pagesPath!,
                  "$pageNum".padLeft(3, '0') + ".png",
                ); // or jpg, ensure generic?
                // Installer flattens to 001.png.
                // We validated existence.

                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(imagePath)),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                });
                _saveLastRead(_currentPage);
              },
              loadingBuilder: (context, event) => const Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),

          // Overlay
          if (_isOverlayVisible) ...[
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.7),
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                title: Text("${"quran.page".tr()} $_currentPage / 604"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.grid_view),
                    onPressed: () {
                      _showJumpDialog();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Bar (Slider)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text("1", style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 1,
                        max: 604,
                        divisions: 604,
                        onChanged: (val) {
                          _jumpToPage(val.toInt());
                        },
                      ),
                    ),
                    Text("604", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _jumpToPage(int page) {
    if (page < 1 || page > 604) return;
    setState(() {
      _currentPage = page;
    });
    _pageController.jumpToPage(page - 1);
  }

  void _showJumpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("quran.goto_page".tr()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "1 - 604"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final p = int.tryParse(controller.text);
              if (p != null) {
                _jumpToPage(p);
              }
              Navigator.pop(context);
            },
            child: Text("Go"),
          ),
        ],
      ),
    );
  }
}
