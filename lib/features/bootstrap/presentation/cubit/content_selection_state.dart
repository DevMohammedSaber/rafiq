part of 'content_selection_cubit.dart';

abstract class ContentSelectionState extends Equatable {
  const ContentSelectionState();

  @override
  List<Object?> get props => [];
}

class ContentSelectionInitial extends ContentSelectionState {}

class ContentSelectionLoading extends ContentSelectionState {}

class ContentSelectionReady extends ContentSelectionState {
  final List<ContentItem> items;
  final Set<String> selectedIds;

  const ContentSelectionReady({required this.items, required this.selectedIds});

  ContentSelectionReady copyWith({
    List<ContentItem>? items,
    Set<String>? selectedIds,
  }) {
    return ContentSelectionReady(
      items: items ?? this.items,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  @override
  List<Object?> get props => [items, selectedIds];
}

class ContentSelectionDownloading extends ContentSelectionState {
  final List<ContentItem> items;
  final Set<String> downloadingIds;

  const ContentSelectionDownloading({
    required this.items,
    required this.downloadingIds,
  });

  // Helper to get total progress logic if needed
  double get totalProgress {
    int total = downloadingIds.length;
    if (total == 0) return 0;
    double sum = 0;
    for (var id in downloadingIds) {
      final item = items.firstWhere(
        (i) => i.id == id,
        orElse: () => items.first,
      ); // fallback
      sum += item.progress;
    }
    return sum / total;
  }

  @override
  List<Object?> get props => [items, downloadingIds];
}

class ContentSelectionDone extends ContentSelectionState {}

class ContentSelectionError extends ContentSelectionState {
  final String message;

  const ContentSelectionError(this.message);

  @override
  List<Object?> get props => [message];
}
