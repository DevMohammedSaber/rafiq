import 'package:equatable/equatable.dart';

/// Tasbeeh preset model for zikr/dhikr counting
class TasbeehPreset extends Equatable {
  /// Unique identifier
  final String id;

  /// Arabic title
  final String titleAr;

  /// English title (optional)
  final String? titleEn;

  /// Goal count for this preset
  final int goal;

  /// Whether this is a default preset (cannot be deleted)
  final bool isDefault;

  /// Color hex code (optional, for UI)
  final String? colorHex;

  const TasbeehPreset({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.goal,
    this.isDefault = false,
    this.colorHex,
  });

  /// Default presets
  static List<TasbeehPreset> get defaults => const [
    TasbeehPreset(
      id: 'subhanallah',
      titleAr: 'سبحان الله',
      titleEn: 'SubhanAllah',
      goal: 33,
      isDefault: true,
      colorHex: '#4CAF50',
    ),
    TasbeehPreset(
      id: 'alhamdulillah',
      titleAr: 'الحمد لله',
      titleEn: 'Alhamdulillah',
      goal: 33,
      isDefault: true,
      colorHex: '#2196F3',
    ),
    TasbeehPreset(
      id: 'allahuakbar',
      titleAr: 'الله أكبر',
      titleEn: 'Allahu Akbar',
      goal: 34,
      isDefault: true,
      colorHex: '#9C27B0',
    ),
    TasbeehPreset(
      id: 'subhanallahwabihamdihi',
      titleAr: 'سبحان الله وبحمده',
      titleEn: 'SubhanAllah wa bihamdihi',
      goal: 100,
      isDefault: true,
      colorHex: '#FF9800',
    ),
    TasbeehPreset(
      id: 'lailahaillallah',
      titleAr: 'لا إله إلا الله',
      titleEn: 'La ilaha illallah',
      goal: 100,
      isDefault: true,
      colorHex: '#E91E63',
    ),
  ];

  /// Get localized title based on language code
  String getTitle(String languageCode) {
    if (languageCode == 'ar') {
      return titleAr;
    }
    return titleEn ?? titleAr;
  }

  factory TasbeehPreset.fromJson(Map<String, dynamic> json) {
    return TasbeehPreset(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String?,
      goal: json['goal'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      colorHex: json['colorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'goal': goal,
      'isDefault': isDefault,
      'colorHex': colorHex,
    };
  }

  TasbeehPreset copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    int? goal,
    bool? isDefault,
    String? colorHex,
  }) {
    return TasbeehPreset(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      goal: goal ?? this.goal,
      isDefault: isDefault ?? this.isDefault,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, titleAr, titleEn, goal, isDefault, colorHex];
}
