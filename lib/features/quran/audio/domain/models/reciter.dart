import 'package:equatable/equatable.dart';

/// Represents a Quran reciter.
class Reciter extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String style;
  final String baseUrl;
  final String fileFormat;
  final String quality;
  final double totalSizeMb;

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.style,
    required this.baseUrl,
    required this.fileFormat,
    required this.quality,
    required this.totalSizeMb,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      style: json['style'] as String? ?? 'Murattal',
      baseUrl: json['base_url'] as String,
      fileFormat: json['file_format'] as String? ?? '{surah_padded}.mp3',
      quality: json['quality'] as String? ?? '128kbps',
      totalSizeMb: (json['total_size_mb'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'style': style,
      'base_url': baseUrl,
      'file_format': fileFormat,
      'quality': quality,
      'total_size_mb': totalSizeMb,
    };
  }

  /// Get the URL for a specific surah.
  String getSurahUrl(int surahId) {
    final paddedSurah = surahId.toString().padLeft(3, '0');
    final fileName = fileFormat.replaceAll('{surah_padded}', paddedSurah);
    return '$baseUrl/$fileName';
  }

  @override
  List<Object?> get props => [
    id,
    nameAr,
    nameEn,
    style,
    baseUrl,
    fileFormat,
    quality,
    totalSizeMb,
  ];
}

/// Represents download status for a surah audio.
class SurahDownloadInfo extends Equatable {
  final String reciterId;
  final int surahId;
  final bool isDownloaded;
  final String? localPath;
  final int? sizeBytes;

  const SurahDownloadInfo({
    required this.reciterId,
    required this.surahId,
    required this.isDownloaded,
    this.localPath,
    this.sizeBytes,
  });

  @override
  List<Object?> get props => [
    reciterId,
    surahId,
    isDownloaded,
    localPath,
    sizeBytes,
  ];
}

/// Audio download progress.
class AudioDownloadProgress {
  final String reciterId;
  final int surahId;
  final double progress; // 0.0 to 1.0
  final AudioDownloadStatus status;
  final String? error;

  const AudioDownloadProgress({
    required this.reciterId,
    required this.surahId,
    required this.progress,
    required this.status,
    this.error,
  });
}

enum AudioDownloadStatus { idle, downloading, completed, error }

/// Audio playback state.
class AudioPlaybackState extends Equatable {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? currentReciterId;
  final int? currentSurahId;

  const AudioPlaybackState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.currentReciterId,
    this.currentSurahId,
  });

  AudioPlaybackState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    String? currentReciterId,
    int? currentSurahId,
  }) {
    return AudioPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      currentReciterId: currentReciterId ?? this.currentReciterId,
      currentSurahId: currentSurahId ?? this.currentSurahId,
    );
  }

  @override
  List<Object?> get props => [
    isPlaying,
    position,
    duration,
    speed,
    currentReciterId,
    currentSurahId,
  ];
}
