import 'dart:convert';

class HadithBook {
  final String id;
  final String titleAr;
  final String titleEn;
  final int totalCount;
  final bool hasTashkeel;

  HadithBook({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.totalCount,
    required this.hasTashkeel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'total_count': totalCount,
      'has_tashkeel': hasTashkeel ? 1 : 0,
    };
  }

  factory HadithBook.fromMap(Map<String, dynamic> map) {
    return HadithBook(
      id: map['id'],
      titleAr: map['title_ar'],
      titleEn: map['title_en'],
      totalCount: map['total_count'],
      hasTashkeel: map['has_tashkeel'] == 1,
    );
  }
}

class HadithItem {
  final String uid;
  final String bookId;
  final int? number;
  final String? chapter;
  final String textAr;
  final String rawJson;
  final String searchText;

  HadithItem({
    required this.uid,
    required this.bookId,
    this.number,
    this.chapter,
    required this.textAr,
    required this.rawJson,
    required this.searchText,
  });

  Map<String, dynamic> get metadata => jsonDecode(rawJson);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'book_id': bookId,
      'number': number,
      'chapter': chapter,
      'text_ar': textAr,
      'raw_json': rawJson,
      'search_text': searchText,
    };
  }

  factory HadithItem.fromMap(Map<String, dynamic> map) {
    return HadithItem(
      uid: map['uid'],
      bookId: map['book_id'],
      number: map['number'],
      chapter: map['chapter'],
      textAr: map['text_ar'],
      rawJson: map['raw_json'],
      searchText: map['search_text'],
    );
  }
}
