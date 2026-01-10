class ArabicNormalizer {
  static const String alefHamzaAbove = '\u0622';
  static const String alefHamzaBelow = '\u0623';
  static const String alefMaddaAbove = '\u0625';
  static const String alefPlain = '\u0627';
  static const String yaa = '\u064a';
  static const String alefMaqsuura = '\u0649';
  static const String taaMarbuuta = '\u0629';
  static const String haa = '\u0647';

  static String normalize(String input) {
    if (input.isEmpty) return input;

    String text = input;

    // Remove diacritics (tashkeel)
    text = text.replaceAll(RegExp(r'[\u064b-\u0652]'), '');

    // Normalize Alef
    text = text.replaceAll(
      RegExp('[$alefHamzaAbove$alefHamzaBelow$alefMaddaAbove]'),
      alefPlain,
    );

    // Normalize Yaa / Alef Maqsuura
    text = text.replaceAll(alefMaqsuura, yaa);

    // Normalize Taa Marbuuta / Haa
    text = text.replaceAll(taaMarbuuta, haa);

    return text.trim();
  }
}
