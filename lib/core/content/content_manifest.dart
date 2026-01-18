/// Models for the content manifest structure.
import 'package:equatable/equatable.dart';

/// Root manifest containing all datasets.
class ContentManifest extends Equatable {
  final String baseUrl;
  final Map<String, DatasetEntry> datasets;

  const ContentManifest({required this.baseUrl, required this.datasets});

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    final datasetsJson = json['datasets'] as Map<String, dynamic>? ?? {};
    final datasets = <String, DatasetEntry>{};

    datasetsJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        datasets[key] = DatasetEntry.fromJson(key, value);
      }
    });

    return ContentManifest(
      baseUrl: json['baseUrl'] as String? ?? '',
      datasets: datasets,
    );
  }

  DatasetEntry? get quran => datasets['quran'];
  DatasetEntry? get azkar => datasets['azkar'];
  DatasetEntry? get hadithPlain => datasets['hadith_plain'];
  DatasetEntry? get quiz => datasets['quiz'];

  @override
  List<Object?> get props => [baseUrl, datasets];
}

/// A single dataset entry in the manifest.
class DatasetEntry extends Equatable {
  final String id;
  final int version;
  final String format;
  final String apply;
  final String? path;
  final String? basePath;
  final List<HadithBookEntry>? books;
  final List<AzkarFileEntry>? files;
  final String sha256;

  const DatasetEntry({
    required this.id,
    required this.version,
    required this.format,
    required this.apply,
    this.path,
    this.basePath,
    this.books,
    this.files,
    required this.sha256,
  });

  factory DatasetEntry.fromJson(String id, Map<String, dynamic> json) {
    List<HadithBookEntry>? books;
    if (json['books'] is List) {
      books = (json['books'] as List)
          .map((b) => HadithBookEntry.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    List<AzkarFileEntry>? files;
    if (json['files'] is List) {
      files = (json['files'] as List)
          .map((f) => AzkarFileEntry.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return DatasetEntry(
      id: id,
      version: json['version'] as int? ?? 1,
      format: json['format'] as String? ?? 'csv',
      apply: json['apply'] as String? ?? 'replace_file',
      path: json['path'] as String?,
      basePath: json['basePath'] as String?,
      books: books,
      files: files,
      sha256: json['sha256'] as String? ?? '',
    );
  }

  bool get isMultiCsv => format == 'multi_csv';
  bool get isMultiFile => format == 'multi_file';
  bool get requiresSqliteImport => apply == 'reimport_sqlite';

  @override
  List<Object?> get props => [
    id,
    version,
    format,
    apply,
    path,
    basePath,
    books,
    files,
    sha256,
  ];
}

/// Entry for a hadith book within the hadith_plain dataset.
class HadithBookEntry extends Equatable {
  final String id;
  final String csv;

  const HadithBookEntry({required this.id, required this.csv});

  factory HadithBookEntry.fromJson(Map<String, dynamic> json) {
    return HadithBookEntry(
      id: json['id'] as String? ?? '',
      csv: json['csv'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, csv];
}

/// Entry for an azkar file within the azkar dataset.
class AzkarFileEntry extends Equatable {
  final String id;
  final String path;

  const AzkarFileEntry({required this.id, required this.path});

  factory AzkarFileEntry.fromJson(Map<String, dynamic> json) {
    return AzkarFileEntry(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, path];
}
