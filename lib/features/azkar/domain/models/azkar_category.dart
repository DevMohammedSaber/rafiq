import 'package:equatable/equatable.dart';

class AZkarCategory extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;

  const AZkarCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  factory AZkarCategory.fromJson(Map<String, dynamic> json) {
    return AZkarCategory(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name_ar': nameAr, 'name_en': nameEn};
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn];
}
