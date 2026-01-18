import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rafiq/core/content/content_update_manager.dart';
import 'package:rafiq/features/bootstrap/presentation/cubit/content_bootstrap_cubit.dart';

class MockContentUpdateManager extends Mock implements ContentUpdateManager {}

void main() {
  late MockContentUpdateManager mockManager;
  late StreamController<ContentUpdateProgress> progressController;

  setUp(() {
    mockManager = MockContentUpdateManager();
    // Use sync controller for deterministic testing
    progressController = StreamController<ContentUpdateProgress>.broadcast(
      sync: true,
    );

    when(
      () => mockManager.progressStream,
    ).thenAnswer((_) => progressController.stream);
    when(() => mockManager.dispose()).thenReturn(null);
  });

  tearDown(() {
    progressController.close();
  });

  group('ContentBootstrapCubit', () {
    test('initial state is ContentBootstrapInitial', () {
      final cubit = ContentBootstrapCubit(updateManager: mockManager);
      expect(cubit.state, const ContentBootstrapInitial());
      cubit.close();
    });

    blocTest<ContentBootstrapCubit, ContentBootstrapState>(
      'emits success when updates complete successfully',
      build: () {
        when(() => mockManager.checkForUpdates()).thenAnswer((_) async {
          // Ensure stream events are processed
          await Future.delayed(Duration.zero);
          return true;
        });
        return ContentBootstrapCubit(updateManager: mockManager);
      },
      act: (cubit) {
        cubit.startBootstrap();
        progressController.add(
          const ContentUpdateProgress(
            phase: 'checking',
            currentItem: 'Checking',
            progressPercent: 0.1,
          ),
        );
        progressController.add(
          const ContentUpdateProgress(phase: 'complete', progressPercent: 1.0),
        );
      },
      expect: () => [
        isA<ContentBootstrapLoading>().having(
          (s) => s.message,
          'message',
          'Checking for content updates...',
        ),
        isA<ContentBootstrapLoading>().having(
          (s) => s.progress,
          'progress',
          0.1,
        ),
        const ContentBootstrapComplete(),
      ],
    );

    blocTest<ContentBootstrapCubit, ContentBootstrapState>(
      'emits error when manager stream emits an error',
      build: () {
        when(() => mockManager.checkForUpdates()).thenAnswer((_) async {
          // Wait for stream to be processed before returning failure
          await Future.delayed(Duration(milliseconds: 10));
          return false;
        });
        return ContentBootstrapCubit(updateManager: mockManager);
      },
      act: (cubit) {
        cubit.startBootstrap();
        progressController.add(
          const ContentUpdateProgress(phase: 'error', error: 'Download failed'),
        );
      },
      expect: () => [
        isA<ContentBootstrapLoading>(),
        const ContentBootstrapError(message: 'Download failed'),
      ],
    );
  });
}
