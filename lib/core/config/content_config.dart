/// CDN configuration for content delivery.
/// All app content (Quran, Azkar, Hadith) is fetched from Cloudflare R2 + Worker.
class ContentConfig {
  ContentConfig._();

  /// Base URL for the Cloudflare Worker CDN
  static const String baseUrl = 'https://rafiq-content.m-s-e12300.workers.dev';

  /// Manifest file path (relative to baseUrl)
  static const String manifestPath = 'manifest.json';

  /// Full manifest URL
  static String get manifestUrl => '$baseUrl/$manifestPath';

  /// Build full URL for a content path
  static String getContentUrl(String relativePath) {
    return '$baseUrl/$relativePath';
  }

  /// Content cache directory name under app documents
  static const String cacheDir = 'content';

  /// Database directory name under app documents
  static const String dbDir = 'db';

  /// SharedPreferences keys for version tracking
  static const String prefKeyQuranVersion = 'content_version_quran';
  static const String prefKeyAzkarVersion = 'content_version_azkar';
  static const String prefKeyHadithVersion = 'content_version_hadith_plain';
  static const String prefKeyContentReady = 'content_ready';

  /// Timeout for downloads
  static const Duration downloadTimeout = Duration(minutes: 5);

  /// Chunk size for batch database imports
  static const int importBatchSize = 500;
}
