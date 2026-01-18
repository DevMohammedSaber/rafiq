import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/content_config.dart';
import 'content_cache_paths.dart';
import 'content_manifest.dart';
import 'manifest_fetcher.dart';
import 'models/content_item.dart';

// Feature Data Sources
import '../../features/quran/data/quran_database_cdn.dart';
import '../../features/hadith/data/hadith_database_cdn.dart';
import '../../features/azkar/data/azkar_database_cdn.dart';
import '../../features/quran/mushaf/data/mushaf_manifest_service.dart';
import '../../features/quran/mushaf/data/mushaf_zip_installer.dart';

/// Service to handle granular content downloads and updates.
class ContentDownloadService {
  final Dio _dio;
  final ManifestFetcher _manifestFetcher;
  // We use MushafManifestService to fetch mushaf manifest,
  // but we might need to point it to the correct URL if it's not default.
  final MushafManifestService _mushafManifestFetcher;
  final MushafZipInstaller _mushafInstaller;

  final StreamController<ContentItem> _itemProgressController =
      StreamController<ContentItem>.broadcast();

  ContentDownloadService({Dio? dio})
    : _dio = dio ?? Dio(),
      _manifestFetcher = ManifestFetcher(dio: dio),
      _mushafManifestFetcher = MushafManifestService(dio ?? Dio()),
      _mushafInstaller = MushafZipInstaller(dio ?? Dio());

  Stream<ContentItem> get itemProgressStream => _itemProgressController.stream;

  /// Fetch all available content items with their current status.
  Future<List<ContentItem>> getAvailableContent() async {
    final prefs = await SharedPreferences.getInstance();
    final items = <ContentItem>[];

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);

    ContentManifest? manifest;
    if (isOnline) {
      manifest = await _manifestFetcher.fetchManifest();
    }

    // 1. Quran (Mandatory)
    final localQuranVer = prefs.getInt(ContentConfig.prefKeyQuranVersion) ?? 0;
    final remoteQuran = manifest?.quran;

    items.add(
      ContentItem(
        id: 'quran',
        titleAr: 'القرآن الكريم',
        titleEn: 'Noble Quran',
        isMandatory: true,
        type: ContentType.csvSingle,
        remoteVersion: remoteQuran?.version ?? 0,
        localVersion: localQuranVer,
        status: _determineStatus(localQuranVer, remoteQuran?.version),
        metadata: remoteQuran,
      ),
    );

    // 2. Azkar (Optional)
    final localAzkarVer = prefs.getInt(ContentConfig.prefKeyAzkarVersion) ?? 0;
    final remoteAzkar = manifest?.azkar;

    items.add(
      ContentItem(
        id: 'azkar',
        titleAr: 'الأذكار',
        titleEn: 'Azkar',
        isMandatory: false,
        type: ContentType.csvGroup,
        remoteVersion: remoteAzkar?.version ?? 0,
        localVersion: localAzkarVer,
        status: _determineStatus(localAzkarVer, remoteAzkar?.version),
        metadata: remoteAzkar,
      ),
    );

    // 3. Hadith (Optional)
    final localHadithVer =
        prefs.getInt(ContentConfig.prefKeyHadithVersion) ?? 0;
    final remoteHadith = manifest?.hadithPlain;

    items.add(
      ContentItem(
        id: 'hadith',
        titleAr: 'الحديث الشريف',
        titleEn: 'Hadith',
        isMandatory: false,
        type: ContentType.csvGroup,
        remoteVersion: remoteHadith?.version ?? 0,
        localVersion: localHadithVer,
        status: _determineStatus(localHadithVer, remoteHadith?.version),
        metadata: remoteHadith,
      ),
    );

    // 4. Quiz (Optional)
    final remoteQuiz = manifest?.quiz;
    if (remoteQuiz != null) {
      // Assuming quiz version tracking isn't fully implemented in config yet,
      // we can check a generic key or just treat as optional download.
      // For now, let's skip rigorous version check for quiz if key missing.
      items.add(
        ContentItem(
          id: 'quiz',
          titleAr: 'المسابقات',
          titleEn: 'Quiz',
          isMandatory: false,
          type: ContentType.json,
          remoteVersion: remoteQuiz.version,
          localVersion: 0, // TODO: Implement quiz local version
          status: ContentStatus.notDownloaded, // Default for now
          metadata: remoteQuiz,
        ),
      );
    }

    // 5. Mushafs (Optional Group)
    // We need to fetch mushaf manifest separately
    if (isOnline) {
      try {
        final mushafManifest = await _mushafManifestFetcher.fetchManifest();
        for (var m in mushafManifest.mushafs) {
          final isInstalled = await _mushafInstaller.isMushafInstalled(m.id);
          items.add(
            ContentItem(
              id: 'mushaf_${m.id}',
              titleAr: 'مصحف ${m.nameAr}',
              titleEn: 'Mushaf ${m.nameEn}',
              isMandatory: false,
              type: ContentType.mushafZip,
              remoteVersion: 1, // Mushafs usually static or versioned in zip
              localVersion: isInstalled ? 1 : 0,
              status: isInstalled
                  ? ContentStatus.downloaded
                  : ContentStatus.notDownloaded,
              metadata: m,
            ),
          );
        }
      } catch (e) {
        // Ignore mushaf manifest error, maybe just skip them
      }
    }

    return items;
  }

  ContentStatus _determineStatus(int local, int? remote) {
    if (local > 0) {
      if (remote != null && remote > local) {
        return ContentStatus.updateAvailable;
      }
      return ContentStatus.downloaded;
    }
    return ContentStatus.notDownloaded;
  }

  /// Download list of items by ID
  Future<void> downloadSelected(List<ContentItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    for (final item in items) {
      // Skip if already downloaded and no update
      if (item.status == ContentStatus.downloaded) continue;

      _updateItemStatus(item, ContentStatus.downloading, 0.0);

      try {
        if (item.id == 'quran') {
          await _downloadQuran(item, prefs);
        } else if (item.id == 'azkar') {
          await _downloadAzkar(item, prefs);
        } else if (item.id == 'hadith') {
          await _downloadHadith(item, prefs);
        } else if (item.type == ContentType.mushafZip &&
            item.metadata is MushafInfo) {
          await _downloadMushaf(item, item.metadata as MushafInfo);
        } else if (item.id == 'quiz') {
          await _downloadQuiz(item, prefs);
        }

        _updateItemStatus(item, ContentStatus.downloaded, 1.0);
      } catch (e) {
        _updateItemStatus(item, ContentStatus.error, 0.0, error: e.toString());
        // For strict failure flow, maybe rethrow?
        // But we want to process others.
      }
    }

    // Check if mandatory content is ready
    final quranReady = prefs.getInt(ContentConfig.prefKeyQuranVersion) ?? 0;
    if (quranReady > 0) {
      await prefs.setBool(ContentConfig.prefKeyContentReady, true);
    }
  }

  void _updateItemStatus(
    ContentItem item,
    ContentStatus status,
    double progress, {
    String? error,
  }) {
    final newItem = item.copyWith(
      status: status,
      progress: progress,
      errorMessage: error,
    );
    _itemProgressController.add(newItem);
  }

  Future<void> _downloadQuran(ContentItem item, SharedPreferences prefs) async {
    final dataset = item.metadata as DatasetEntry;
    final csvPath = ContentCachePaths.quranCsvPath;
    await ContentCachePaths.ensureDirectoryExists(csvPath);

    final url = ContentConfig.getContentUrl(dataset.path!);
    await _downloadFile(url, csvPath, (p) {
      _updateItemStatus(
        item,
        ContentStatus.downloading,
        p * 0.5,
      ); // 50% download
    });

    // Import
    await QuranDatabaseCdn.instance.importFromCsv(csvPath, (current, total) {
      final p = 0.5 + (current / total * 0.5);
      _updateItemStatus(item, ContentStatus.downloading, p);
    });

    await prefs.setInt(ContentConfig.prefKeyQuranVersion, dataset.version);
  }

  Future<void> _downloadAzkar(ContentItem item, SharedPreferences prefs) async {
    final dataset = item.metadata as DatasetEntry;

    // Download
    if (dataset.isMultiFile && dataset.files != null) {
      int count = 0;
      for (final file in dataset.files!) {
        final localPath = ContentCachePaths.azkarFilePath(
          file.path.split('/').last,
        );
        await ContentCachePaths.ensureDirectoryExists(localPath);
        final url = ContentConfig.getContentUrl(file.path);

        await _downloadFile(url, localPath, (p) {
          // Micro progress for files
        });
        count++;
        _updateItemStatus(
          item,
          ContentStatus.downloading,
          (count / dataset.files!.length) * 0.5,
        );
      }
    } else if (dataset.path != null) {
      final localPath = ContentCachePaths.azkarFilePath(
        dataset.path!.split('/').last,
      );
      await ContentCachePaths.ensureDirectoryExists(localPath);
      final url = ContentConfig.getContentUrl(dataset.path!);
      await _downloadFile(url, localPath, (p) {
        _updateItemStatus(item, ContentStatus.downloading, p * 0.5);
      });
    }

    // Import
    await AzkarDatabaseCdn.instance.importFromCsvDirectory(
      ContentCachePaths.azkarDir,
      (current, total) {
        final p = 0.5 + (current / total * 0.5);
        _updateItemStatus(item, ContentStatus.downloading, p);
      },
    );

    await prefs.setInt(ContentConfig.prefKeyAzkarVersion, dataset.version);
  }

  Future<void> _downloadHadith(
    ContentItem item,
    SharedPreferences prefs,
  ) async {
    final dataset = item.metadata as DatasetEntry;

    if (dataset.isMultiCsv && dataset.books != null) {
      int count = 0;
      for (final book in dataset.books!) {
        final bookDir = ContentCachePaths.hadithBookDir(book.id);
        await ContentCachePaths.ensureDirectoryExists('$bookDir/${book.csv}');
        final url = ContentConfig.getContentUrl(
          '${dataset.basePath}/${book.id}/${book.csv}',
        );
        final localPath = ContentCachePaths.hadithCsvPath(book.id, book.csv);

        await _downloadFile(url, localPath, (p) {});

        count++;
        _updateItemStatus(
          item,
          ContentStatus.downloading,
          (count / dataset.books!.length) * 0.5,
        );
      }
    }

    // Import
    await HadithDatabaseCdn.instance.importFromBooks(
      dataset.books ?? [],
      ContentCachePaths.hadithDir,
      (current, total) {
        final p = 0.5 + (current / total * 0.5);
        _updateItemStatus(item, ContentStatus.downloading, p);
      },
    );

    await prefs.setInt(ContentConfig.prefKeyHadithVersion, dataset.version);
  }

  Future<void> _downloadMushaf(ContentItem item, MushafInfo info) async {
    // URL construction might reside in MushafManifestService, but let's assume standard pattern or provided in info
    // Wait, MushafInfo doesn't have full URL, just zipPath.
    // We need base URL.
    final baseUrl = ContentConfig.baseUrl; // Or from manifest
    // Actually, MushafManifest has baseUrl.
    // We should pass baseUrl with metadata or just use global
    final url = "$baseUrl/${info.zipPath}";

    await _mushafInstaller.installMushaf(
      info.id,
      url,
      onProgress: (p, stage) {
        // p is 0..1
        _updateItemStatus(item, ContentStatus.downloading, p);
      },
    );
  }

  Future<void> _downloadQuiz(ContentItem item, SharedPreferences prefs) async {
    final dataset = item.metadata as DatasetEntry;
    final jsonPath = ContentCachePaths.quizJsonPath;
    await ContentCachePaths.ensureDirectoryExists(jsonPath);

    final url = ContentConfig.getContentUrl(
      dataset.path ?? 'quiz/questions.json',
    );
    await _downloadFile(url, jsonPath, (p) {
      _updateItemStatus(item, ContentStatus.downloading, p);
    });

    // Quiz typically JSON, no separate SQLite import needed if using direct JSON reading,
    // or implement quiz database import if requested.
    // For now, we just track version.
    await prefs.setInt('content_version_quiz', dataset.version);
  }

  Future<void> _downloadFile(
    String url,
    String savePath,
    Function(double) onProgress,
  ) async {
    await _dio.download(
      url,
      savePath,
      options: Options(receiveTimeout: ContentConfig.downloadTimeout),
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );
  }

  void dispose() {
    _itemProgressController.close();
    _dio.close();
  }
}
