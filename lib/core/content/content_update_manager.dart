import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/content_config.dart';
import 'content_cache_paths.dart';
import 'content_manifest.dart';
import 'manifest_fetcher.dart';
import '../../features/quran/data/quran_database_cdn.dart';
import '../../features/hadith/data/hadith_database_cdn.dart';
import '../../features/azkar/data/azkar_database_cdn.dart';

/// Progress information for content updates.
class ContentUpdateProgress {
  final String phase;
  final String currentItem;
  final int current;
  final int total;
  final double progressPercent;
  final String? error;

  const ContentUpdateProgress({
    required this.phase,
    this.currentItem = '',
    this.current = 0,
    this.total = 0,
    this.progressPercent = 0.0,
    this.error,
  });

  bool get isError => error != null;
  bool get isComplete => phase == 'complete';
}

/// Manages content updates from CDN.
/// Downloads, caches, and imports content into local databases.
class ContentUpdateManager {
  final Dio _dio;
  final ManifestFetcher _manifestFetcher;
  final StreamController<ContentUpdateProgress> _progressController =
      StreamController<ContentUpdateProgress>.broadcast();

  ContentManifest? _manifest;

  ContentUpdateManager({Dio? dio})
    : _dio = dio ?? Dio(),
      _manifestFetcher = ManifestFetcher(dio: dio);

  /// Stream of update progress
  Stream<ContentUpdateProgress> get progressStream =>
      _progressController.stream;

  /// Check if content is ready for offline use
  Future<bool> isContentReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(ContentConfig.prefKeyContentReady) ?? false;
  }

  /// Check for updates and download/import if needed.
  /// Returns true if all content is ready.
  Future<bool> checkForUpdates() async {
    try {
      _emitProgress('checking', 'Checking for updates...');

      // Fetch manifest
      _manifest = await _manifestFetcher.fetchManifest();
      if (_manifest == null) {
        // If no network and content exists, we are OK
        if (await isContentReady()) {
          _emitProgress('complete', 'Content ready (offline)');
          return true;
        }
        _emitError('Failed to fetch manifest and no cached content');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Check Quran
      final quranDataset = _manifest!.quran;
      if (quranDataset != null) {
        final localVersion =
            prefs.getInt(ContentConfig.prefKeyQuranVersion) ?? 0;
        if (quranDataset.version > localVersion) {
          await _updateQuran(quranDataset, prefs);
        }
      }

      // Check Azkar
      final azkarDataset = _manifest!.azkar;
      if (azkarDataset != null) {
        final localVersion =
            prefs.getInt(ContentConfig.prefKeyAzkarVersion) ?? 0;
        if (azkarDataset.version > localVersion) {
          await _updateAzkar(azkarDataset, prefs);
        }
      }

      // Check Hadith
      final hadithDataset = _manifest!.hadithPlain;
      if (hadithDataset != null) {
        final localVersion =
            prefs.getInt(ContentConfig.prefKeyHadithVersion) ?? 0;
        if (hadithDataset.version > localVersion) {
          await _updateHadith(hadithDataset, prefs);
        }
      }

      // Mark content as ready
      await prefs.setBool(ContentConfig.prefKeyContentReady, true);
      _emitProgress('complete', 'All content ready');
      return true;
    } catch (e) {
      _emitError('Update failed: $e');
      // If we have cached content, still return true
      return await isContentReady();
    }
  }

  /// Update Quran content
  Future<void> _updateQuran(
    DatasetEntry dataset,
    SharedPreferences prefs,
  ) async {
    _emitProgress(
      'downloading',
      'Downloading Quran data...',
      current: 0,
      total: 100,
    );

    final csvPath = ContentCachePaths.quranCsvPath;
    await ContentCachePaths.ensureDirectoryExists(csvPath);

    // Download CSV
    final url = ContentConfig.getContentUrl(dataset.path!);
    await _downloadFile(url, csvPath, 'Quran');

    _emitProgress(
      'importing',
      'Importing Quran data...',
      current: 50,
      total: 100,
    );

    // Import to database
    await QuranDatabaseCdn.instance.importFromCsv(csvPath, _onImportProgress);

    // Update version
    await prefs.setInt(ContentConfig.prefKeyQuranVersion, dataset.version);
    _emitProgress(
      'importing',
      'Quran import complete',
      current: 100,
      total: 100,
    );
  }

  /// Update Azkar content
  Future<void> _updateAzkar(
    DatasetEntry dataset,
    SharedPreferences prefs,
  ) async {
    _emitProgress(
      'downloading',
      'Downloading Azkar data...',
      current: 0,
      total: 100,
    );

    if (dataset.isMultiFile && dataset.files != null) {
      // Download multiple files
      int filesDownloaded = 0;
      for (final file in dataset.files!) {
        final localPath = ContentCachePaths.azkarFilePath(
          file.path.split('/').last,
        );
        await ContentCachePaths.ensureDirectoryExists(localPath);
        final url = ContentConfig.getContentUrl(file.path);
        await _downloadFile(url, localPath, file.id);
        filesDownloaded++;
        _emitProgress(
          'downloading',
          'Downloaded ${file.id}',
          current: filesDownloaded,
          total: dataset.files!.length,
        );
      }
    } else if (dataset.path != null) {
      // Single file
      final localPath = ContentCachePaths.azkarFilePath(
        dataset.path!.split('/').last,
      );
      await ContentCachePaths.ensureDirectoryExists(localPath);
      final url = ContentConfig.getContentUrl(dataset.path!);
      await _downloadFile(url, localPath, 'Azkar');
    }

    _emitProgress(
      'importing',
      'Importing Azkar data...',
      current: 50,
      total: 100,
    );

    // Import to database
    await AzkarDatabaseCdn.instance.importFromCsvDirectory(
      ContentCachePaths.azkarDir,
      _onImportProgress,
    );

    // Update version
    await prefs.setInt(ContentConfig.prefKeyAzkarVersion, dataset.version);
    _emitProgress(
      'importing',
      'Azkar import complete',
      current: 100,
      total: 100,
    );
  }

  /// Update Hadith content
  Future<void> _updateHadith(
    DatasetEntry dataset,
    SharedPreferences prefs,
  ) async {
    _emitProgress(
      'downloading',
      'Downloading Hadith data...',
      current: 0,
      total: 100,
    );

    if (dataset.isMultiCsv && dataset.books != null) {
      // Download all book CSVs
      int booksDownloaded = 0;
      for (final book in dataset.books!) {
        final bookDir = ContentCachePaths.hadithBookDir(book.id);
        await ContentCachePaths.ensureDirectoryExists('$bookDir/${book.csv}');

        final url = ContentConfig.getContentUrl(
          '${dataset.basePath}/${book.id}/${book.csv}',
        );
        final localPath = ContentCachePaths.hadithCsvPath(book.id, book.csv);
        await _downloadFile(url, localPath, book.id);

        booksDownloaded++;
        _emitProgress(
          'downloading',
          'Downloaded ${book.id}',
          current: booksDownloaded,
          total: dataset.books!.length,
        );
      }
    }

    _emitProgress(
      'importing',
      'Importing Hadith data...',
      current: 50,
      total: 100,
    );

    // Import to database
    await HadithDatabaseCdn.instance.importFromBooks(
      dataset.books ?? [],
      ContentCachePaths.hadithDir,
      _onImportProgress,
    );

    // Update version
    await prefs.setInt(ContentConfig.prefKeyHadithVersion, dataset.version);
    _emitProgress(
      'importing',
      'Hadith import complete',
      current: 100,
      total: 100,
    );
  }

  /// Download a file from URL to local path
  Future<void> _downloadFile(
    String url,
    String localPath,
    String itemName,
  ) async {
    try {
      await _dio.download(
        url,
        localPath,
        options: Options(receiveTimeout: ContentConfig.downloadTimeout),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = (received / total * 100).toInt();
            _emitProgress('downloading', 'Downloading $itemName: $percent%');
          }
        },
      );
    } catch (e) {
      throw Exception('Failed to download $itemName: $e');
    }
  }

  void _onImportProgress(int current, int total) {
    final percent = total > 0 ? (current / total * 100).toInt() : 0;
    _emitProgress(
      'importing',
      'Importing... $percent%',
      current: current,
      total: total,
    );
  }

  void _emitProgress(
    String phase,
    String item, {
    int current = 0,
    int total = 0,
  }) {
    final percent = total > 0 ? current / total : 0.0;
    _progressController.add(
      ContentUpdateProgress(
        phase: phase,
        currentItem: item,
        current: current,
        total: total,
        progressPercent: percent,
      ),
    );
  }

  void _emitError(String error) {
    _progressController.add(
      ContentUpdateProgress(phase: 'error', error: error),
    );
  }

  /// Force re-download all content
  Future<void> forceRedownload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ContentConfig.prefKeyQuranVersion);
    await prefs.remove(ContentConfig.prefKeyAzkarVersion);
    await prefs.remove(ContentConfig.prefKeyHadithVersion);
    await prefs.remove(ContentConfig.prefKeyContentReady);
    await checkForUpdates();
  }

  void dispose() {
    _progressController.close();
    _manifestFetcher.dispose();
    _dio.close();
  }
}
