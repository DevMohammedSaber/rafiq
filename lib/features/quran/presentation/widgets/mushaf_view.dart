import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/ayah.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class MushafView extends StatefulWidget {
  final Surah surah;
  final List<Ayah> ayahs;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final int? activeAyah;
  final Function(Ayah) onTapAyah;
  final Function(Ayah) onShareAyah;
  final Function(Ayah) onToggleBookmark;
  final Function(Ayah) onToggleFavorite;

  const MushafView({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.fontSize,
    required this.fontFamily,
    required this.bookmarks,
    required this.favorites,
    this.activeAyah,
    required this.onTapAyah,
    required this.onShareAyah,
    required this.onToggleBookmark,
    required this.onToggleFavorite,
  });

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  late TextStyle _baseTextStyle;
  late TextStyle _bismillahStyle;
  final Map<int, String> _arabicNumbersCache = {};

  @override
  void initState() {
    super.initState();
    _updateTextStyles();
  }

  @override
  void didUpdateWidget(MushafView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.fontFamily != widget.fontFamily) {
      _updateTextStyles();
    }
  }

  void _updateTextStyles() {
    _baseTextStyle = _getTextStyle();
    _bismillahStyle = _baseTextStyle.copyWith(
      fontSize: widget.fontSize + 4,
      fontWeight: FontWeight.bold,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // Bismillah (except for Surah At-Tawbah #9)
            if (widget.surah.id != 9)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: _bismillahStyle,
                  textAlign: TextAlign.center,
                  textDirection: ui.TextDirection.rtl,
                ),
              ),

            // Continuous Text - Optimized with caching
            RepaintBoundary(
              child: _buildOptimizedRichText(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedRichText(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textSpans = <InlineSpan>[];
    
    for (final ayah in widget.ayahs) {
      final isBookmarked = widget.bookmarks.contains(ayah.key);
      final isFavorite = widget.favorites.contains(ayah.key);
      final isActive = widget.activeAyah == ayah.ayahNumber;

      // Ayah Text
      textSpans.add(
        TextSpan(
          text: '${ayah.textAr} ',
          style: _baseTextStyle.copyWith(
            backgroundColor: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : null,
            color: isBookmarked ? AppColors.primary : null,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => widget.onTapAyah(ayah),
        ),
      );

      // Ayah Marker - Using WidgetSpan but optimized
      textSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AyahMarker(
            ayahNumber: ayah.ayahNumber,
            isFavorite: isFavorite,
            primaryColor: primaryColor,
            onTap: () => widget.onTapAyah(ayah),
            arabicNumber: _toArabicNumbers(ayah.ayahNumber),
          ),
        ),
      );

      // Spacing
      textSpans.add(const TextSpan(text: '  '));
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: ui.TextDirection.rtl,
      text: TextSpan(children: textSpans),
    );
  }

  TextStyle _getTextStyle() {
    switch (widget.fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(
          fontSize: widget.fontSize,
          height: 2.2,
          color: Colors.black,
        );
      case 'Cairo':
        return GoogleFonts.cairo(
          fontSize: widget.fontSize,
          height: 1.8,
          color: Colors.black,
        );
      case 'Tajawal':
        return GoogleFonts.tajawal(
          fontSize: widget.fontSize,
          height: 1.8,
          color: Colors.black,
        );
      default:
        return GoogleFonts.amiri(
          fontSize: widget.fontSize,
          height: 2.2,
          color: Colors.black,
        );
    }
  }

  String _toArabicNumbers(int number) {
    if (_arabicNumbersCache.containsKey(number)) {
      return _arabicNumbersCache[number]!;
    }
    
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final result = number
        .toString()
        .split('')
        .map((char) => arabicDigits[int.parse(char)])
        .join('');
    
    _arabicNumbersCache[number] = result;
    return result;
  }
}

// Separate widget for ayah marker to improve performance
class _AyahMarker extends StatelessWidget {
  final int ayahNumber;
  final bool isFavorite;
  final Color primaryColor;
  final VoidCallback onTap;
  final String arabicNumber;

  const _AyahMarker({
    required this.ayahNumber,
    required this.isFavorite,
    required this.primaryColor,
    required this.onTap,
    required this.arabicNumber,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(
              color: isFavorite ? Colors.red : primaryColor,
              width: 1,
            ),
            shape: BoxShape.circle,
            color: isFavorite ? Colors.red.withValues(alpha: 0.1) : null,
          ),
          child: Center(
            child: Text(
              arabicNumber,
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
  }
}
