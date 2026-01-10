import 'package:equatable/equatable.dart';
import 'ayah.dart';

class MushafPage extends Equatable {
  final int page;
  final List<MushafPageItem> items;

  const MushafPage({
    required this.page,
    required this.items,
  });

  factory MushafPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => MushafPageItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MushafPage(
      page: json['page'] as int? ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  List<Ayah> toAyahs() {
    return items.map((item) {
      return Ayah(
        surahId: item.surah,
        ayahNumber: item.ayah,
        textAr: item.text,
      );
    }).toList();
  }

  @override
  List<Object?> get props => [page, items];
}

class MushafPageItem extends Equatable {
  final int surah;
  final int ayah;
  final String text;

  const MushafPageItem({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  factory MushafPageItem.fromJson(Map<String, dynamic> json) {
    return MushafPageItem(
      surah: json['surah'] as int? ?? 0,
      ayah: json['ayah'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'text': text,
    };
  }

  String get ayahKey => '$surah:$ayah';

  @override
  List<Object?> get props => [surah, ayah, text];
}
