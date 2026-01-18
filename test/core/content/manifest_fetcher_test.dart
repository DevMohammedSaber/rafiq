import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:rafiq/core/content/manifest_fetcher.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ManifestFetcher fetcher;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    fetcher = ManifestFetcher(dio: mockDio);
  });

  group('ManifestFetcher', () {
    const jsonString = '''
      {
        "baseUrl": "https://example.com",
        "datasets": {
          "quran": {
            "version": 1,
            "path": "quran.csv",
            "format": "csv",
            "apply": "reimport_sqlite"
          },
          "azkar": {
            "version": 2,
            "format": "multi_file",
            "apply": "replace_file",
            "files": [
              {"id": "morning", "path": "azkar/morning.csv"}
            ]
          }
        }
      }
    ''';

    test('fetches and parses manifest correctly', () async {
      // Arrange
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: jsonString,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Act
      final manifest = await fetcher.fetchManifest();

      // Assert
      expect(manifest, isNotNull);
      expect(manifest!.baseUrl, 'https://example.com');

      // Check Quran
      expect(manifest.quran, isNotNull);
      expect(manifest.quran!.version, 1);

      // Check Azkar
      expect(manifest.datasets['azkar'], isNotNull);
      final azkar = manifest.datasets['azkar']!;
      expect(azkar.version, 2);
      expect(azkar.isMultiFile, true);
      expect(azkar.files, hasLength(1));
    });

    test('returns null on error', () async {
      // Arrange
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      // Act
      final manifest = await fetcher.fetchManifest();

      // Assert
      expect(manifest, isNull);
    });
  });
}
