import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../domain/models/reciter.dart';

/// Repository for managing Quran audio downloads and local storage.
class QuranAudioRepository {
  static const String _manifestPath = 'assets/quran/reciters_manifest.json';
  static const String _audioDir = 'quran_audio';

  List<Reciter>? _cachedReciters;

  /// List all available reciters from manifest.
  Future<List<Reciter>> listReciters() async {
    if (_cachedReciters != null) return _cachedReciters!;

    try {
      final jsonString = await rootBundle.loadString(_manifestPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final recitersList = data['reciters'] as List<dynamic>? ?? [];

      _cachedReciters = recitersList
          .map((r) => Reciter.fromJson(r as Map<String, dynamic>))
          .toList();

      return _cachedReciters!;
    } catch (e) {
      return [];
    }
  }

  /// Get a specific reciter by ID.
  Future<Reciter?> getReciter(String reciterId) async {
    final reciters = await listReciters();
    try {
      return reciters.firstWhere((r) => r.id == reciterId);
    } catch (e) {
      return null;
    }
  }

  /// Get the local path for a surah audio file.
  Future<String> getLocalSurahPath(String reciterId, int surahId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/$_audioDir/$reciterId');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final paddedSurah = surahId.toString().padLeft(3, '0');
    return '${audioDir.path}/$paddedSurah.mp3';
  }

  /// Check if a surah audio is downloaded.
  Future<bool> isDownloaded(String reciterId, int surahId) async {
    final path = await getLocalSurahPath(reciterId, surahId);
    return File(path).existsSync();
  }

  /// Get download info for a surah.
  Future<SurahDownloadInfo> getSurahDownloadInfo(
    String reciterId,
    int surahId,
  ) async {
    final path = await getLocalSurahPath(reciterId, surahId);
    final file = File(path);
    final exists = await file.exists();

    return SurahDownloadInfo(
      reciterId: reciterId,
      surahId: surahId,
      isDownloaded: exists,
      localPath: exists ? path : null,
      sizeBytes: exists ? await file.length() : null,
    );
  }

  /// Download a surah audio with progress.
  Stream<AudioDownloadProgress> downloadSurah(
    String reciterId,
    int surahId,
  ) async* {
    yield AudioDownloadProgress(
      reciterId: reciterId,
      surahId: surahId,
      progress: 0.0,
      status: AudioDownloadStatus.downloading,
    );

    try {
      final reciter = await getReciter(reciterId);
      if (reciter == null) {
        throw Exception('Reciter not found');
      }

      final url = reciter.getSurahUrl(surahId);
      final localPath = await getLocalSurahPath(reciterId, surahId);

      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final file = File(localPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          yield AudioDownloadProgress(
            reciterId: reciterId,
            surahId: surahId,
            progress: progress,
            status: AudioDownloadStatus.downloading,
          );
        }
      }

      await sink.close();
      client.close();

      yield AudioDownloadProgress(
        reciterId: reciterId,
        surahId: surahId,
        progress: 1.0,
        status: AudioDownloadStatus.completed,
      );
    } catch (e) {
      yield AudioDownloadProgress(
        reciterId: reciterId,
        surahId: surahId,
        progress: 0.0,
        status: AudioDownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Delete a downloaded surah audio.
  Future<void> deleteSurah(String reciterId, int surahId) async {
    final path = await getLocalSurahPath(reciterId, surahId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get list of downloaded surahs for a reciter.
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/$_audioDir/$reciterId');

    if (!await audioDir.exists()) {
      return [];
    }

    final files = await audioDir.list().toList();
    final downloadedSurahs = <int>[];

    for (final file in files) {
      if (file is File && file.path.endsWith('.mp3')) {
        final fileName = file.path.split('/').last;
        final surahId = int.tryParse(fileName.replaceAll('.mp3', ''));
        if (surahId != null) {
          downloadedSurahs.add(surahId);
        }
      }
    }

    downloadedSurahs.sort();
    return downloadedSurahs;
  }

  /// Get total size of downloaded audio for a reciter.
  Future<int> getDownloadedSize(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/$_audioDir/$reciterId');

    if (!await audioDir.exists()) {
      return 0;
    }

    int totalSize = 0;
    final files = await audioDir.list().toList();

    for (final file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  /// Delete all downloaded audio for a reciter.
  Future<void> deleteAllForReciter(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/$_audioDir/$reciterId');

    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }

  /// Get or create the streaming URL for a surah.
  Future<String> getStreamingUrl(String reciterId, int surahId) async {
    // Check if downloaded first
    final isLocal = await isDownloaded(reciterId, surahId);
    if (isLocal) {
      return await getLocalSurahPath(reciterId, surahId);
    }

    // Return remote URL for streaming
    final reciter = await getReciter(reciterId);
    if (reciter == null) {
      throw Exception('Reciter not found');
    }

    return reciter.getSurahUrl(surahId);
  }

  /// Clear all cached reciters.
  void clearCache() {
    _cachedReciters = null;
  }
}
