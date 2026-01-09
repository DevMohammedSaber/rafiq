import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int id;
  final String index;
  final String nameEn;
  final String nameAr;
  final int ayahCount;
  final String place;
  final String type;

  const Surah({
    required this.id,
    required this.index,
    required this.nameEn,
    required this.nameAr,
    required this.ayahCount,
    required this.place,
    required this.type,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final indexStr = json['index'] as String? ?? '001';
    return Surah(
      id: int.tryParse(indexStr) ?? 1,
      index: indexStr,
      nameEn: json['title'] as String? ?? '',
      nameAr: json['titleAr'] as String? ?? '',
      ayahCount: json['count'] as int? ?? 0,
      place: json['place'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'title': nameEn,
      'titleAr': nameAr,
      'count': ayahCount,
      'place': place,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [
    id,
    index,
    nameEn,
    nameAr,
    ayahCount,
    place,
    type,
  ];
}
