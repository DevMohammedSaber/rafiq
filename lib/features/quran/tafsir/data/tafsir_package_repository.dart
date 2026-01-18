import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../domain/models/tafsir_package.dart';

/// Repository for managing tafsir and translation packages.
/// Handles listing, downloading, verifying, and retrieving tafsir content.
class TafsirPackageRepository {
  static const String _manifestPath = 'assets/quran/tafsir_manifest.json';
  static const String _packagesDir = 'quran_packages';

  List<TafsirPackage>? _cachedPackages;
  final Map<String, Map<String, String>> _loadedContent = {};

  /// List all available packages from manifest.
  Future<List<TafsirPackage>> listPackages() async {
    if (_cachedPackages != null) return _cachedPackages!;

    try {
      final jsonString = await rootBundle.loadString(_manifestPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final packagesList = data['packages'] as List<dynamic>? ?? [];

      _cachedPackages = packagesList
          .map((p) => TafsirPackage.fromJson(p as Map<String, dynamic>))
          .toList();

      return _cachedPackages!;
    } catch (e) {
      return [];
    }
  }

  /// Check if a package is downloaded.
  Future<bool> isDownloaded(String packageId) async {
    final file = await _getPackageFile(packageId);
    return file.existsSync();
  }

  /// Get the local file path for a package.
  Future<File> _getPackageFile(String packageId) async {
    final dir = await getApplicationDocumentsDirectory();
    final packagesDir = Directory('${dir.path}/$_packagesDir/$packageId');

    if (!await packagesDir.exists()) {
      await packagesDir.create(recursive: true);
    }

    return File('${packagesDir.path}/data.json');
  }

  /// Download a package with progress stream.
  Stream<PackageDownloadProgress> downloadPackage(String packageId) async* {
    yield PackageDownloadProgress(
      packageId: packageId,
      progress: 0.0,
      status: DownloadStatus.downloading,
    );

    try {
      // Find package info
      final packages = await listPackages();
      final package = packages.firstWhere(
        (p) => p.id == packageId,
        orElse: () => throw Exception('Package not found'),
      );

      // For now, create placeholder content since we dont have actual URLs
      // In production, you'd use HttpClient or dio to download
      yield PackageDownloadProgress(
        packageId: packageId,
        progress: 0.5,
        status: DownloadStatus.downloading,
      );

      // Create placeholder tafsir data
      final placeholderData = _createPlaceholderData(packageId, package);

      yield PackageDownloadProgress(
        packageId: packageId,
        progress: 0.9,
        status: DownloadStatus.verifying,
      );

      // Save to file
      final file = await _getPackageFile(packageId);
      await file.writeAsString(json.encode(placeholderData));

      yield PackageDownloadProgress(
        packageId: packageId,
        progress: 1.0,
        status: DownloadStatus.completed,
      );
    } catch (e) {
      yield PackageDownloadProgress(
        packageId: packageId,
        progress: 0.0,
        status: DownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Create placeholder data for development/testing.
  Map<String, dynamic> _createPlaceholderData(
    String packageId,
    TafsirPackage package,
  ) {
    final data = <String, dynamic>{
      'package_id': packageId,
      'version': package.version,
      'ayahs': <String, String>{},
    };

    // Create sample entries for first surah
    for (int ayah = 1; ayah <= 7; ayah++) {
      final key = '1:$ayah';
      if (package.isTranslation) {
        data['ayahs'][key] = _getEnglishPlaceholder(1, ayah);
      } else {
        data['ayahs'][key] = _getTafsirPlaceholder(packageId, 1, ayah);
      }
    }

    // Add some entries for Al-Baqarah
    for (int ayah = 1; ayah <= 5; ayah++) {
      final key = '2:$ayah';
      if (package.isTranslation) {
        data['ayahs'][key] = _getEnglishPlaceholder(2, ayah);
      } else {
        data['ayahs'][key] = _getTafsirPlaceholder(packageId, 2, ayah);
      }
    }

    return data;
  }

  String _getEnglishPlaceholder(int surah, int ayah) {
    // Sample translations for Al-Fatiha
    if (surah == 1) {
      switch (ayah) {
        case 1:
          return 'In the name of Allah, the Entirely Merciful, the Especially Merciful.';
        case 2:
          return '[All] praise is [due] to Allah, Lord of the worlds.';
        case 3:
          return 'The Entirely Merciful, the Especially Merciful.';
        case 4:
          return 'Sovereign of the Day of Recompense.';
        case 5:
          return 'It is You we worship and You we ask for help.';
        case 6:
          return 'Guide us to the straight path.';
        case 7:
          return 'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.';
        default:
          return 'Translation for Surah $surah, Ayah $ayah';
      }
    }
    return 'Translation for Surah $surah, Ayah $ayah (placeholder)';
  }

  String _getTafsirPlaceholder(String packageId, int surah, int ayah) {
    if (surah == 1 && ayah == 1) {
      return 'بسم الله الرحمن الرحيم: يبدأ القارئ باسم الله مستعينا به في قراءته وجميع أموره، والله: هو المعبود بحق، الرحمن الرحيم: صفتان مشتقتان من الرحمة.';
    }
    return 'تفسير الآية $ayah من سورة رقم $surah (نموذج للاختبار)';
  }

  /// Delete a downloaded package.
  Future<void> deletePackage(String packageId) async {
    final file = await _getPackageFile(packageId);
    if (await file.exists()) {
      await file.delete();
    }
    _loadedContent.remove(packageId);
  }

  /// Get tafsir/translation text for a specific ayah.
  Future<String?> getTafsirText(
    String packageId,
    int surahId,
    int ayahNumber,
  ) async {
    // Check if content is loaded
    if (!_loadedContent.containsKey(packageId)) {
      await _loadPackageContent(packageId);
    }

    final content = _loadedContent[packageId];
    if (content == null) return null;

    final key = '$surahId:$ayahNumber';
    return content[key];
  }

  /// Load package content into memory.
  Future<void> _loadPackageContent(String packageId) async {
    try {
      final file = await _getPackageFile(packageId);
      if (!await file.exists()) return;

      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final ayahs = data['ayahs'] as Map<String, dynamic>? ?? {};

      _loadedContent[packageId] = ayahs.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // Failed to load package content
    }
  }

  /// Get download size for a package.
  Future<int?> getPackageSize(String packageId) async {
    final file = await _getPackageFile(packageId);
    if (await file.exists()) {
      return await file.length();
    }
    return null;
  }

  /// Clear all cached data.
  void clearCache() {
    _loadedContent.clear();
    _cachedPackages = null;
  }

  /// Verify package integrity with SHA256.
  Future<bool> verifyPackage(String packageId, String expectedHash) async {
    try {
      final file = await _getPackageFile(packageId);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);

      return digest.toString() == expectedHash;
    } catch (e) {
      return false;
    }
  }
}
