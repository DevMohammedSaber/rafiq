import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/content_config.dart';
import 'content_manifest.dart';

/// Fetches the content manifest from CDN.
class ManifestFetcher {
  final Dio _dio;

  ManifestFetcher({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch the manifest from CDN.
  /// Returns null if fetch fails.
  Future<ContentManifest?> fetchManifest() async {
    try {
      final response = await _dio.get(
        ContentConfig.manifestUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> jsonData;
        if (response.data is String) {
          jsonData =
              json.decode(response.data as String) as Map<String, dynamic>;
        } else {
          jsonData = response.data as Map<String, dynamic>;
        }
        return ContentManifest.fromJson(jsonData);
      }
    } catch (e) {
      // Failed to fetch manifest
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
