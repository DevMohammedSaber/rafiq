import 'package:equatable/equatable.dart';

class Zikr extends Equatable {
  final String id;
  final String categoryId;
  final String titleAr;
  final String titleEn;
  final String textAr;
  final String textEn;
  final int repeat;
  final String? sourceAr;
  final String? sourceEn;

  const Zikr({
    required this.id,
    required this.categoryId,
    required this.titleAr,
    required this.titleEn,
    required this.textAr,
    required this.textEn,
    this.repeat = 1,
    this.sourceAr,
    this.sourceEn,
  });

  factory Zikr.fromJson(Map<String, dynamic> json) {
    return Zikr(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String,
      textAr: json['text_ar'] as String,
      textEn: json['text_en'] as String,
      repeat: (json['repeat'] as num?)?.toInt() ?? 1,
      sourceAr: json['source_ar'] as String?,
      sourceEn: json['source_en'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'text_ar': textAr,
      'text_en': textEn,
      'repeat': repeat,
      'source_ar': sourceAr,
      'source_en': sourceEn,
    };
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    titleAr,
    titleEn,
    textAr,
    textEn,
    repeat,
    sourceAr,
    sourceEn,
  ];
}
