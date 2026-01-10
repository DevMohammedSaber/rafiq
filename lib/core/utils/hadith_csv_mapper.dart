import 'dart:convert';

class HadithCsvMapper {
  static Map<String, dynamic> mapRow(
    List<String> headers,
    List<dynamic> values,
    int index,
  ) {
    final Map<String, dynamic> map = {};

    // Check if headers actually look like data (if values are 2 and headers are 2, and headers[0] is "1")
    bool useIndices =
        headers.length != values.length ||
        (headers.length > 0 && int.tryParse(headers[0].toString()) != null);

    if (useIndices) {
      if (values.length >= 2) {
        map['number'] = values[0];
        map['text_ar'] = values[1];
      } else if (values.length == 1) {
        map['text_ar'] = values[0];
      }
    } else {
      for (int i = 0; i < headers.length; i++) {
        if (i < values.length) {
          map[headers[i].toLowerCase()] = values[i];
        }
      }
    }

    final textAr = _extractTextAr(map);
    final number = _extractNumber(map) ?? (index + 1);
    final chapter = _extractChapter(map);

    return {
      'text_ar': textAr,
      'number': number,
      'chapter': chapter,
      'raw_json': jsonEncode(map),
    };
  }

  static String _extractTextAr(Map<String, dynamic> map) {
    const textKeys = [
      "text",
      "hadith",
      "matn",
      "arabic",
      "hadith_text",
      "text_ar",
    ];
    for (final key in textKeys) {
      if (map.containsKey(key) && map[key].toString().isNotEmpty) {
        return map[key].toString();
      }
    }

    // Fallback: longest non-empty column
    String longest = "";
    map.forEach((key, value) {
      final valStr = value.toString();
      if (valStr.length > longest.length) {
        longest = valStr;
      }
    });
    return longest;
  }

  static int? _extractNumber(Map<String, dynamic> map) {
    const numberKeys = ["number", "hadith_number", "no", "index", "id"];
    for (final key in numberKeys) {
      if (map.containsKey(key)) {
        final val = int.tryParse(map[key].toString());
        if (val != null) return val;
      }
    }
    return null;
  }

  static String? _extractChapter(Map<String, dynamic> map) {
    const chapterKeys = ["chapter", "book", "bab", "section", "kitab"];
    for (final key in chapterKeys) {
      if (map.containsKey(key) && map[key].toString().isNotEmpty) {
        return map[key].toString();
      }
    }
    return null;
  }
}
