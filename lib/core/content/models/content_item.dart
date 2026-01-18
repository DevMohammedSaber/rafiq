import 'package:equatable/equatable.dart';

enum ContentType { csvGroup, csvSingle, mushafZip, json, sqlite }

enum ContentStatus {
  notDownloaded,
  downloading,
  downloaded,
  updateAvailable,
  error,
}

class ContentItem extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final bool isMandatory;
  final ContentType type;
  final int remoteVersion;
  final int localVersion;
  final int? sizeBytes;
  final ContentStatus status;
  final double progress; // 0..1
  final String? errorMessage;
  // Extra data for handling downloads
  final dynamic metadata;

  const ContentItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.isMandatory,
    required this.type,
    required this.remoteVersion,
    required this.localVersion,
    this.sizeBytes,
    this.status = ContentStatus.notDownloaded,
    this.progress = 0.0,
    this.errorMessage,
    this.metadata,
  });

  bool get isDownloaded => status == ContentStatus.downloaded;
  bool get isUpdateAvailable => status == ContentStatus.updateAvailable;
  bool get isDownloading => status == ContentStatus.downloading;

  ContentItem copyWith({
    ContentStatus? status,
    double? progress,
    int? localVersion,
    String? errorMessage,
  }) {
    return ContentItem(
      id: id,
      titleAr: titleAr,
      titleEn: titleEn,
      isMandatory: isMandatory,
      type: type,
      remoteVersion: remoteVersion,
      localVersion: localVersion ?? this.localVersion,
      sizeBytes: sizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    titleAr,
    titleEn,
    isMandatory,
    type,
    remoteVersion,
    localVersion,
    sizeBytes,
    status,
    progress,
    errorMessage,
    metadata,
  ];
}
