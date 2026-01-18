import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/content_config.dart';

/// Manages local cache paths for downloaded content.
class ContentCachePaths {
  ContentCachePaths._();

  static Directory? _documentsDir;
  static Directory? _contentDir;
  static Directory? _dbDir;

  /// Initialize paths (call once at app start)
  static Future<void> init() async {
    _documentsDir = await getApplicationDocumentsDirectory();
    _contentDir = Directory('${_documentsDir!.path}/${ContentConfig.cacheDir}');
    _dbDir = Directory('${_documentsDir!.path}/${ContentConfig.dbDir}');

    // Ensure directories exist
    if (!await _contentDir!.exists()) {
      await _contentDir!.create(recursive: true);
    }
    if (!await _dbDir!.exists()) {
      await _dbDir!.create(recursive: true);
    }
  }

  /// Get documents directory
  static Directory get documentsDir {
    if (_documentsDir == null) {
      throw StateError('ContentCachePaths not initialized. Call init() first.');
    }
    return _documentsDir!;
  }

  /// Get content cache directory
  static Directory get contentDir {
    if (_contentDir == null) {
      throw StateError('ContentCachePaths not initialized. Call init() first.');
    }
    return _contentDir!;
  }

  /// Get database directory
  static Directory get dbDir {
    if (_dbDir == null) {
      throw StateError('ContentCachePaths not initialized. Call init() first.');
    }
    return _dbDir!;
  }

  // Quran paths
  static String get quranCsvPath => '${contentDir.path}/quran/quran.csv';
  static String get quranDbPath => '${dbDir.path}/quran.db';
  static String quranDbVersionedPath(int version) =>
      '${dbDir.path}/quran_v$version.db';

  // Azkar paths
  static String get azkarDir => '${contentDir.path}/azkar';
  static String azkarFilePath(String fileName) =>
      '${contentDir.path}/azkar/$fileName';
  static String get azkarDbPath => '${dbDir.path}/azkar.db';

  // Hadith paths
  static String get hadithDir => '${contentDir.path}/hadith';
  static String hadithBookDir(String bookId) =>
      '${contentDir.path}/hadith/$bookId';
  static String hadithCsvPath(String bookId, String csvName) =>
      '${contentDir.path}/hadith/$bookId/$csvName';
  static String get hadithDbPath => '${dbDir.path}/hadith.db';
  static String hadithDbVersionedPath(int version) =>
      '${dbDir.path}/hadith_v$version.db';

  // Quiz paths
  static String get quizDir => '${contentDir.path}/quiz';
  static String get quizJsonPath => '${contentDir.path}/quiz/questions.json';

  /// Ensure a directory exists for a file path
  static Future<void> ensureDirectoryExists(String filePath) async {
    final dir = Directory(filePath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Delete a file if it exists
  static Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}
