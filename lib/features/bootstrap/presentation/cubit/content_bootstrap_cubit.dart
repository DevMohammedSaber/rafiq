import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/content/content_update_manager.dart';

part 'content_bootstrap_state.dart';

/// Cubit for managing content bootstrap process.
class ContentBootstrapCubit extends Cubit<ContentBootstrapState> {
  final ContentUpdateManager _updateManager;
  StreamSubscription<ContentUpdateProgress>? _progressSubscription;

  ContentBootstrapCubit({ContentUpdateManager? updateManager})
    : _updateManager = updateManager ?? ContentUpdateManager(),
      super(const ContentBootstrapInitial());

  /// Start the bootstrap process
  Future<void> startBootstrap() async {
    emit(
      const ContentBootstrapLoading(
        message: 'Checking for content updates...',
        progress: 0.0,
      ),
    );

    // Listen to progress updates
    _progressSubscription = _updateManager.progressStream.listen((progress) {
      if (progress.isError) {
        emit(ContentBootstrapError(message: progress.error ?? 'Unknown error'));
      } else if (progress.isComplete) {
        emit(const ContentBootstrapComplete());
      } else {
        emit(
          ContentBootstrapLoading(
            message: progress.currentItem,
            progress: progress.progressPercent,
            phase: progress.phase,
          ),
        );
      }
    });

    // Start update check
    final success = await _updateManager.checkForUpdates();

    if (!success && state is! ContentBootstrapError) {
      emit(
        const ContentBootstrapError(
          message:
              'Failed to download content. Please check your internet connection.',
        ),
      );
    }
  }

  /// Retry bootstrap after error
  Future<void> retry() async {
    await startBootstrap();
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _updateManager.dispose();
    return super.close();
  }
}
