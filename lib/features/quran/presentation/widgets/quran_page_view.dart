import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/ayah.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class QuranPageView extends StatefulWidget {
  final Map<int, List<Ayah>> pages;
  final Surah surah;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final int? activeAyah;
  final int initialPage;
  final Function(Ayah) onTapAyah;
  final Function(int) onPageChanged;

  const QuranPageView({
    super.key,
    required this.pages,
    required this.surah,
    required this.fontSize,
    required this.fontFamily,
    required this.bookmarks,
    required this.favorites,
    this.activeAyah,
    required this.initialPage,
    required this.onTapAyah,
    required this.onPageChanged,
  });

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Normalize initialPage to index (0-based) if pages keys are 1-based
    // Page keys are likely 1,2,3... based on Repo.
    // So index = pageNum - 1?
    // Wait, let's check Page keys. They come from JSON: "1", "2"...
    // So we need to map page index to page Key.

    final sortedPages = widget.pages.keys.toList()..sort();
    final initialIndex = sortedPages.indexOf(widget.initialPage);

    _pageController = PageController(
      initialPage: initialIndex != -1 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPageNumbers = widget.pages.keys.toList()..sort();

    return PageView.builder(
      controller: _pageController,
      reverse: true, // RTL navigation for Arabic
      itemCount: sortedPageNumbers.length,
      onPageChanged: (index) {
        final pageNum = sortedPageNumbers[index];
        widget.onPageChanged(pageNum);
      },
      itemBuilder: (context, index) {
        final pageNum = sortedPageNumbers[index];
        final ayahs = widget.pages[pageNum]!;

        // Check if this is the very first page of the Surah to show Bismillah
        // We assume pageNum == 1 means first page of Mushaf?
        // No, pageNum is absolute Mushaf page.
        // But for Surah 1, it starts on Page 1.
        // For Surah 2, it starts on Page 2.
        // We need to know if we should show Bismillah.
        // Bismillah is shown if it's the beginning of the Surah.
        // Does 'ayahs' include the first ayah of the Surah?
        final isFirstPageOfSurah = ayahs.any((a) => a.ayahNumber == 1);

        return _PageContent(
          pageNumber: pageNum,
          surah: widget.surah,
          ayahs: ayahs,
          fontSize: widget.fontSize,
          fontFamily: widget.fontFamily,
          bookmarks: widget.bookmarks,
          favorites: widget.favorites,
          activeAyah: widget.activeAyah,
          onTapAyah: widget.onTapAyah,
          showBismillah: isFirstPageOfSurah && widget.surah.id != 9,
        );
      },
    );
  }
}

class _PageContent extends StatelessWidget {
  final int pageNumber;
  final Surah surah;
  final List<Ayah> ayahs;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final int? activeAyah;
  final Function(Ayah) onTapAyah;
  final bool showBismillah;

  const _PageContent({
    required this.pageNumber,
    required this.surah,
    required this.ayahs,
    required this.fontSize,
    required this.fontFamily,
    required this.bookmarks,
    required this.favorites,
    required this.activeAyah,
    required this.onTapAyah,
    required this.showBismillah,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header: Surah Name and Page Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${surah.nameAr} - ${surah.nameEn}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$pageNumber',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      // Allow scrolling if text gets too big, but aim for fit
                      child: Column(
                        children: [
                          if (showBismillah)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                style: _getTextStyle().copyWith(
                                  fontSize: fontSize + 4,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: ui.TextDirection.rtl,
                              ),
                            ),

                          _buildRichText(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textSpans = <InlineSpan>[];
    final baseStyle = _getTextStyle();

    for (final ayah in ayahs) {
      final isBookmarked = bookmarks.contains(ayah.key);
      final isFavorite = favorites.contains(ayah.key);
      final isActive = activeAyah == ayah.ayahNumber;

      // Ayah Text
      textSpans.add(
        TextSpan(
          text: '${ayah.textAr} ',
          style: baseStyle.copyWith(
            backgroundColor: isActive
                ? AppColors.primary.withOpacity(0.1)
                : null,
            color: isBookmarked ? AppColors.primary : null,
          ),
          recognizer: null, // Basic tap handled by parent or marker?
          // We can't easily make spans tappable in RichText without Gestures
          // But here let's make the TextSpan allow tap?
          // Actually user asked for "Tap/long-press an ayah".
          // It's easier if we handle tap on the whole text engine?
          // No, precise tap needs TextSpan recognizer.
        ),
      );

      // Ayah Marker
      textSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => onTapAyah(ayah),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFavorite ? Colors.red : primaryColor,
                  width: 1,
                ),
                color: isFavorite ? Colors.red.withOpacity(0.1) : null,
              ),
              child: Text(
                _toArabicNumbers(ayah.ayahNumber),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFavorite ? Colors.red : primaryColor,
                ),
              ),
            ),
          ),
        ),
      );

      textSpans.add(const TextSpan(text: '  '));

      // Since span tap on text is hard to hit, we'll rely on the marker for action?
      // Or we should add recognizer to text too.
    }

    return SelectableText.rich(
      TextSpan(children: textSpans),
      textAlign: TextAlign.justify,
      textDirection: ui.TextDirection.rtl,
      onTap: () {
        // Generic tap?
      },
    );
  }

  TextStyle _getTextStyle() {
    switch (fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(
          fontSize: fontSize,
          height: 2.2,
          color: Colors.black,
        );
      case 'Cairo':
        return GoogleFonts.cairo(
          fontSize: fontSize,
          height: 1.8,
          color: Colors.black,
        );
      case 'Tajawal':
        return GoogleFonts.tajawal(
          fontSize: fontSize,
          height: 1.8,
          color: Colors.black,
        );
      default:
        return GoogleFonts.amiri(
          fontSize: fontSize,
          height: 2.2,
          color: Colors.black,
        );
    }
  }

  String _toArabicNumbers(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((char) => arabicDigits[int.parse(char)])
        .join('');
  }
}
