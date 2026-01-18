import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MushafZipInstaller {
  final Dio _dio;

  MushafZipInstaller(this._dio);

  Future<void> installMushaf(
    String mushafId,
    String zipUrl, {
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final mushafDir = Directory(p.join(docDir.path, 'mushaf', mushafId));
      final zipFile = File(p.join(mushafDir.path, 'temp.zip'));
      final pagesDir = Directory(p.join(mushafDir.path, 'pages'));

      if (await mushafDir.exists()) {
        await mushafDir.delete(recursive: true);
      }
      await mushafDir.create(recursive: true);
      await pagesDir.create(recursive: true);

      // 1. Download
      onProgress(0.0, "downloading");
      await _dio.download(
        zipUrl,
        zipFile.path,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            onProgress(count / total * 0.5, "downloading");
          }
        },
      );

      // 2. Extract
      onProgress(0.5, "extracting");
      await _extractZip(zipFile, pagesDir, (val) {
        onProgress(0.5 + (val * 0.4), "extracting");
      });

      // 3. Verify
      onProgress(0.9, "verifying");
      if (!await _verifyInstallation(pagesDir)) {
        throw Exception("Verification failed: Missing key pages.");
      }

      // 4. Mark installed
      await _createInstalledFile(mushafDir);

      // Cleanup
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      onProgress(1.0, "done");
    } catch (e) {
      // Cleanup on failure
      final docDir = await getApplicationDocumentsDirectory();
      final mushafDir = Directory(p.join(docDir.path, 'mushaf', mushafId));
      if (await mushafDir.exists()) {
        await mushafDir.delete(recursive: true);
      }
      throw e;
    }
  }

  Future<bool> isMushafInstalled(String mushafId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final installedFile = File(
      p.join(docDir.path, 'mushaf', mushafId, 'installed.json'),
    );
    return installedFile.exists();
  }

  Future<String?> getMushafPagesPath(String mushafId) async {
    if (!await isMushafInstalled(mushafId)) return null;
    final docDir = await getApplicationDocumentsDirectory();
    return p.join(docDir.path, 'mushaf', mushafId, 'pages');
  }

  Future<void> _extractZip(
    File zipFile,
    Directory targetDir,
    Function(double) onExtractProgress,
  ) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    int total = archive.length;
    int count = 0;

    for (final file in archive) {
      if (file.isFile) {
        var filename = p.basename(file.name); // Flatten structure
        final ext = p.extension(filename).toLowerCase();

        // Normalize filename: 1.png -> 001.png
        if (ext == '.png' || ext == '.jpg' || ext == '.jpeg') {
          final nameWithoutExt = p.basenameWithoutExtension(filename);
          final number = int.tryParse(nameWithoutExt);
          if (number != null) {
            filename = "${number.toString().padLeft(3, '0')}$ext";
          }

          final data = file.content as List<int>;
          File(p.join(targetDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }
      count++;
      if (count % 10 == 0) {
        onExtractProgress(count / total);
      }
    }
  }

  Future<bool> _verifyInstallation(Directory pagesDir) async {
    // Check for 001.png and 604.png as robust enough check
    final f1 = File(p.join(pagesDir.path, '001.png'));
    final f604 = File(p.join(pagesDir.path, '604.png'));

    // Maybe checking jpg too
    final f1jpg = File(p.join(pagesDir.path, '001.jpg'));
    final f604jpg = File(p.join(pagesDir.path, '604.jpg'));

    final valid =
        (await f1.exists() || await f1jpg.exists()) &&
        (await f604.exists() || await f604jpg.exists());

    if (!valid) {
      // Debugging: list what IS there
      try {
        final files = pagesDir
            .listSync()
            .map((e) => p.basename(e.path))
            .take(5)
            .toList();
        print("Verification failed. Found files: $files");
        if (files.isEmpty) print("Verification failed. Directory is empty.");
      } catch (e) {
        print("Verification failed. Error listing files: $e");
      }
    }

    return valid;
  }

  Future<void> _createInstalledFile(Directory mushafDir) async {
    final f = File(p.join(mushafDir.path, 'installed.json'));
    final data = {
      "installed": true,
      "installedAt": DateTime.now().toIso8601String(),
    };
    await f.writeAsString(jsonEncode(data));
  }

  /// Delete a downloaded mushaf to free storage
  Future<void> deleteMushaf(String mushafId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final mushafDir = Directory(p.join(docDir.path, 'mushaf', mushafId));
    if (await mushafDir.exists()) {
      await mushafDir.delete(recursive: true);
    }
  }
}
