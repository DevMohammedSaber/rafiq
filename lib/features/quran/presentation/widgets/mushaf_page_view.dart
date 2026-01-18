import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/models/ayah.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;
import '../../data/mushaf_data_repository.dart';
import '../../presentation/cubit/quran_reader_cubit.dart';

class MushafPageView extends StatefulWidget {
  final int totalPages;
  final int initialPage;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final Function(Ayah) onTapAyah;
  final Function(int) onPageChanged;
  final QuranReaderCubit cubit;

  const MushafPageView({
    super.key,
    required this.totalPages,
    required this.initialPage,
    required this.fontSize,
    required this.fontFamily,
    required this.bookmarks,
    required this.favorites,
    required this.onTapAyah,
    required this.onPageChanged,
    required this.cubit,
  });

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  final MushafDataRepository _mushafRepo = MushafDataRepository();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _mushafRepo.loadIndex();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! MushafReaderLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageView.builder(
          controller: _pageController,
          reverse: true,
          itemCount: widget.totalPages,
          onPageChanged: (index) {
            final pageNum = index + 1;
            setState(() {});
            widget.onPageChanged(pageNum);
            widget.cubit.jumpToPage(pageNum);
            widget.cubit.loadPageIfNeeded(pageNum);
            if (pageNum > 1) {
              widget.cubit.loadPageIfNeeded(pageNum - 1);
            }
            if (pageNum < widget.totalPages) {
              widget.cubit.loadPageIfNeeded(pageNum + 1);
            }
          },
          itemBuilder: (context, index) {
            final pageNum = index + 1;
            final pageAyahs = state.loadedPages[pageNum];

            if (pageAyahs == null) {
              widget.cubit.loadPageIfNeeded(pageNum);
              return const Center(child: CircularProgressIndicator());
            }

            return _PageContent(
              pageNumber: pageNum,
              ayahs: pageAyahs,
              fontSize: widget.fontSize,
              fontFamily: widget.fontFamily,
              bookmarks: widget.bookmarks,
              favorites: widget.favorites,
              onTapAyah: widget.onTapAyah,
              mushafRepo: _mushafRepo,
            );
          },
        );
      },
    );
  }
}

class _PageContent extends StatelessWidget {
  final int pageNumber;
  final List<Ayah> ayahs;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final Function(Ayah) onTapAyah;
  final MushafDataRepository mushafRepo;

  const _PageContent({
    required this.pageNumber,
    required this.ayahs,
    required this.fontSize,
    required this.fontFamily,
    required this.bookmarks,
    required this.favorites,
    required this.onTapAyah,
    required this.mushafRepo,
  });

  @override
  Widget build(BuildContext context) {
    if (ayahs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final firstAyah = ayahs.first;
    String? surahName;

    return FutureBuilder(
      future: mushafRepo.getSurahMeta(firstAyah.surahId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          surahName = snapshot.data!.nameAr;
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _PageHeader(pageNumber: pageNumber, surahName: surahName),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: SingleChildScrollView(
                      child: _buildRichText(context),
                    ),
                  ),
                ),
                _PageFooter(pageNumber: pageNumber),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichText(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textSpans = <InlineSpan>[];

    for (final ayah in ayahs) {
      final isBookmarked = bookmarks.contains(ayah.key);
      final isFavorite = favorites.contains(ayah.key);

      textSpans.add(
        TextSpan(
          text: '${ayah.textAr} ',
          style: _getTextStyle().copyWith(
            color: isBookmarked ? AppColors.primary : null,
          ),
        ),
      );

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
    }

    return SelectableText.rich(
      TextSpan(children: textSpans),
      textAlign: TextAlign.justify,
      textDirection: ui.TextDirection.rtl,
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

class _PageHeader extends StatelessWidget {
  final int pageNumber;
  final String? surahName;

  const _PageHeader({required this.pageNumber, this.surahName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (surahName != null)
            Text(
              surahName!,
              style: Theme.of(context).textTheme.bodyMedium,
              textDirection: ui.TextDirection.rtl,
            )
          else
            const SizedBox.shrink(),
          Text(
            '${"quran.page_number".tr()} $pageNumber',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  final int pageNumber;

  const _PageFooter({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Text(
          pageNumber.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
