import 'dart:convert';
import 'package:dio/dio.dart';

class MushafManifest {
  final String baseUrl;
  final List<MushafInfo> mushafs;

  MushafManifest({required this.baseUrl, required this.mushafs});

  factory MushafManifest.fromJson(Map<String, dynamic> json) {
    if (json['mushafs'] == null)
      throw const FormatException("Missing 'mushafs' key in manifest");
    return MushafManifest(
      baseUrl: json['baseUrl'] as String,
      mushafs: (json['mushafs'] as List)
          .map((e) => MushafInfo.fromJson(e))
          .toList(),
    );
  }
}

class MushafInfo {
  final String id;
  final String nameAr;
  final String nameEn;
  final String zipPath;
  final int pageCount;
  final String ext;
  final int padding;
  final int startPage;

  MushafInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.zipPath,
    required this.pageCount,
    required this.ext,
    required this.padding,
    required this.startPage,
  });

  factory MushafInfo.fromJson(Map<String, dynamic> json) {
    return MushafInfo(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      zipPath: json['zipPath'],
      pageCount: json['pageCount'],
      ext: json['ext'],
      padding: json['padding'],
      startPage: json['startPage'] ?? 1,
    );
  }
}

class MushafManifestService {
  final Dio _dio;

  // Using the user's worker URL found in root manifest.json
  // Adjusted to root path based on user's screenshot
  static const String _manifestUrl =
      "https://rafiq-content.m-s-e12300.workers.dev/manifest.json";

  MushafManifestService(this._dio);

  Future<MushafManifest> fetchManifest() async {
    try {
      final response = await _dio.get(_manifestUrl);
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return MushafManifest.fromJson(response.data as Map<String, dynamic>);
        } else if (response.data is String) {
          return MushafManifest.fromJson(jsonDecode(response.data));
        }
      }
      throw Exception('Failed to load manifest');
    } catch (e) {
      // Fallback for development/testing if CDN is not ready or offline
      // This ensures the UI can be tested.
      print("Network manifest failed ($e), returning local fallback.");
      return MushafManifest(
        // Using the user's worker URL even in fallback
        baseUrl: "https://rafiq-content.m-s-e12300.workers.dev",
        mushafs: [
          MushafInfo(
            id: "hafs",
            nameAr: "حفص",
            nameEn: "Hafs",
            zipPath: "hafs.zip",
            pageCount: 604,
            ext: "png",
            padding: 3,
            startPage: 1,
          ),
          MushafInfo(
            id: "hafs-wasat",
            nameAr: "حفص (وسط)",
            nameEn: "Hafs (Wasat)",
            zipPath: "hafs-wasat.zip",
            pageCount: 604,
            ext: "png",
            padding: 3,
            startPage: 1,
          ),
          MushafInfo(
            id: "warsh",
            nameAr: "ورش",
            nameEn: "Warsh",
            zipPath: "warsh.zip",
            pageCount: 604,
            ext: "png",
            padding: 3,
            startPage: 1,
          ),
        ],
      );
    }
  }
}
