import 'package:equatable/equatable.dart';

/// Represents a downloadable tafsir/translation package.
class TafsirPackage extends Equatable {
  final String id;
  final String type; // 'tafsir' or 'translation'
  final String nameAr;
  final String nameEn;
  final String language;
  final int version;
  final String format;
  final String url;
  final String sha256;
  final double sizeMb;
  final String? descriptionAr;
  final String? descriptionEn;

  const TafsirPackage({
    required this.id,
    required this.type,
    required this.nameAr,
    required this.nameEn,
    required this.language,
    required this.version,
    required this.format,
    required this.url,
    required this.sha256,
    required this.sizeMb,
    this.descriptionAr,
    this.descriptionEn,
  });

  factory TafsirPackage.fromJson(Map<String, dynamic> json) {
    return TafsirPackage(
      id: json['id'] as String,
      type: json['type'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      language: json['language'] as String? ?? 'ar',
      version: json['version'] as int? ?? 1,
      format: json['format'] as String? ?? 'json',
      url: json['url'] as String,
      sha256: json['sha256'] as String? ?? '',
      sizeMb: (json['size_mb'] as num?)?.toDouble() ?? 0.0,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name_ar': nameAr,
      'name_en': nameEn,
      'language': language,
      'version': version,
      'format': format,
      'url': url,
      'sha256': sha256,
      'size_mb': sizeMb,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
    };
  }

  bool get isTafsir => type == 'tafsir';
  bool get isTranslation => type == 'translation';

  @override
  List<Object?> get props => [
    id,
    type,
    nameAr,
    nameEn,
    language,
    version,
    format,
    url,
    sha256,
    sizeMb,
  ];
}

/// Represents tafsir/translation text for a specific ayah.
class TafsirText extends Equatable {
  final String packageId;
  final int surahId;
  final int ayahNumber;
  final String text;

  const TafsirText({
    required this.packageId,
    required this.surahId,
    required this.ayahNumber,
    required this.text,
  });

  factory TafsirText.fromJson(Map<String, dynamic> json, String packageId) {
    return TafsirText(
      packageId: packageId,
      surahId: json['surah_id'] as int? ?? json['surah'] as int? ?? 0,
      ayahNumber: json['ayah_number'] as int? ?? json['ayah'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [packageId, surahId, ayahNumber, text];
}

/// Download progress for a package.
class PackageDownloadProgress {
  final String packageId;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final String? error;

  const PackageDownloadProgress({
    required this.packageId,
    required this.progress,
    required this.status,
    this.error,
  });
}

enum DownloadStatus { idle, downloading, verifying, completed, error }
