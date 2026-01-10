import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int surahId;
  final int ayahNumber;
  final String textAr;
  final int? page;

  const Ayah({
    required this.surahId,
    required this.ayahNumber,
    required this.textAr,
    this.page,
  });

  factory Ayah.fromJson(int surahId, int ayahNumber, String text, {int? page}) {
    return Ayah(
      surahId: surahId,
      ayahNumber: ayahNumber,
      textAr: text,
      page: page,
    );
  }

  String get key => '$surahId:$ayahNumber';

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'ayahNumber': ayahNumber,
      'textAr': textAr,
      'page': page,
    };
  }

  @override
  List<Object?> get props => [surahId, ayahNumber, textAr, page];
}
