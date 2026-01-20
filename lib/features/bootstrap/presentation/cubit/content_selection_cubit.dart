import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/content/content_download_service.dart';
import '../../../../core/content/models/content_item.dart';
import '../../../../core/config/content_config.dart';
import '../../../../core/content/content_update_event_bus.dart';

part 'content_selection_state.dart';

class ContentSelectionCubit extends Cubit<ContentSelectionState> {
  final ContentDownloadService _downloadService;
  StreamSubscription<ContentItem>? _progressSubscription;

  ContentSelectionCubit({ContentDownloadService? downloadService})
    : _downloadService = downloadService ?? ContentDownloadService(),
      super(ContentSelectionInitial());

  Future<void> loadAvailableContent() async {
    emit(ContentSelectionLoading());
    try {
      final items = await _downloadService.getAvailableContent();

      // Default selection: Mandatory items + Recommended/Optional?
      // User requirements: Quran MANDATORY (checked disabled). Others OPTIONAL.
      final selectedIds = <String>{};
      for (var item in items) {
        if (item.isMandatory) {
          selectedIds.add(item.id);
        }
      }

      emit(ContentSelectionReady(items: items, selectedIds: selectedIds));
    } catch (e) {
      emit(ContentSelectionError(e.toString()));
    }
  }

  void toggleSelection(String id) {
    if (state is ContentSelectionReady) {
      final currentState = state as ContentSelectionReady;

      // Find item
      final item = currentState.items.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception("Item not found"),
      );

      if (item.isMandatory) return; // Cannot toggle mandatory

      final newSelected = Set<String>.from(currentState.selectedIds);
      if (newSelected.contains(id)) {
        newSelected.remove(id);
      } else {
        newSelected.add(id);
      }

      emit(currentState.copyWith(selectedIds: newSelected));
    }
  }

  Future<void> downloadSelected() async {
    if (state is! ContentSelectionReady) return;
    final currentState = state as ContentSelectionReady;

    final itemsToDownload = currentState.items
        .where((i) => currentState.selectedIds.contains(i.id))
        .toList();

    emit(
      ContentSelectionDownloading(
        items: currentState.items, // Keep all items to show progress
        downloadingIds: currentState.selectedIds,
      ),
    );

    // Listen to progress
    _progressSubscription?.cancel();
    _progressSubscription = _downloadService.itemProgressStream.listen((
      updatedItem,
    ) {
      if (state is ContentSelectionDownloading) {
        final currentDownloadingMsg = state as ContentSelectionDownloading;
        final newItems = currentDownloadingMsg.items.map((i) {
          return i.id == updatedItem.id ? updatedItem : i;
        }).toList();

        // Check overall completion?
        // Actually the service streams updates.
        // We can just emit updated items.
        emit(
          ContentSelectionDownloading(
            items: newItems,
            downloadingIds: currentDownloadingMsg.downloadingIds,
          ),
        );

        // Check if all selected are done
        // This logic might be complex if we just rely on stream.
        // But let's rely on the await downloadSelected below.
      }
    });

    try {
      await _downloadService.downloadSelected(itemsToDownload);

      // Mark onboarding done
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ContentConfig.prefKeyContentReady, true);

      // Notify app that content has been updated
      final downloadedIds = itemsToDownload.map((e) => e.id).toList();
      ContentUpdateEventBus.instance.notifyContentUpdated(downloadedIds);

      emit(ContentSelectionDone());
    } catch (e) {
      emit(ContentSelectionError(e.toString()));
    }
  }

  /// Skip optional is only allowed if Quran is ready.
  /// But "downloadSelected" with ONLY Quran selected IS implicitly "Skip optional" if others are unselected.
  /// The UI button "Skip optional" might just be a shortcut to "Select only mandatory and confirm".
  Future<void> skipOptional() async {
    // Ensure mandatory are selected
    // Just call downloadSelected with current selection if user unchecked everything else?
    // Or specifically select only mandatory.
    if (state is ContentSelectionReady) {
      final currentState = state as ContentSelectionReady;
      final mandatoryParams = currentState.items
          .where((i) => i.isMandatory)
          .map((e) => e.id)
          .toSet();
      emit(currentState.copyWith(selectedIds: mandatoryParams));
      await downloadSelected();
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _downloadService.dispose();
    return super.close();
  }
}
