import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int surahId;
  final int ayahNumber;
  final String textAr;

  const Ayah({
    required this.surahId,
    required this.ayahNumber,
    required this.textAr,
  });

  factory Ayah.fromJson(int surahId, int ayahNumber, String text) {
    return Ayah(surahId: surahId, ayahNumber: ayahNumber, textAr: text);
  }

  String get key => '$surahId:$ayahNumber';

  Map<String, dynamic> toJson() {
    return {'surahId': surahId, 'ayahNumber': ayahNumber, 'textAr': textAr};
  }

  @override
  List<Object?> get props => [surahId, ayahNumber, textAr];
}
