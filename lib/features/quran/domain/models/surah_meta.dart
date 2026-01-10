import 'package:equatable/equatable.dart';

class SurahMeta extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final int? firstPage;

  const SurahMeta({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.firstPage,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) {
    return SurahMeta(
      id: json['id'] as int? ?? 0,
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      firstPage: json['firstPage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'firstPage': firstPage,
    };
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, firstPage];
}
