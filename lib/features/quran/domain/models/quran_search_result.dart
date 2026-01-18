import 'package:equatable/equatable.dart';

/// Model representing a search result from Quran ayah search.
class QuranSearchResult extends Equatable {
  final int surahId;
  final int ayahNumber;
  final String ayahKey;
  final String text;
  final String surahNameAr;
  final String surahNameEn;
  final String? highlightedSnippet;
  final int? page;

  const QuranSearchResult({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahKey,
    required this.text,
    required this.surahNameAr,
    required this.surahNameEn,
    this.highlightedSnippet,
    this.page,
  });

  factory QuranSearchResult.fromMap(Map<String, dynamic> map) {
    return QuranSearchResult(
      surahId: map['surah'] as int,
      ayahNumber: map['ayah'] as int,
      ayahKey: '${map['surah']}:${map['ayah']}',
      text: map['text'] as String,
      surahNameAr: map['surah_name_ar'] as String? ?? '',
      surahNameEn: map['surah_name_en'] as String? ?? '',
      highlightedSnippet: map['snippet'] as String?,
      page: map['page'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    ayahKey,
    text,
    surahNameAr,
    surahNameEn,
    highlightedSnippet,
    page,
  ];
}
