import 'dart:async';

/// Global event bus for notifying app-wide content changes
class ContentUpdateEventBus {
  static final ContentUpdateEventBus instance = ContentUpdateEventBus._();
  ContentUpdateEventBus._();

  final _controller = StreamController<ContentUpdateEvent>.broadcast();

  Stream<ContentUpdateEvent> get stream => _controller.stream;

  void notifyContentUpdated(List<String> contentIds) {
    _controller.add(ContentUpdateEvent(contentIds));
  }

  void dispose() {
    _controller.close();
  }
}

class ContentUpdateEvent {
  final List<String> contentIds;
  final DateTime timestamp;

  ContentUpdateEvent(this.contentIds) : timestamp = DateTime.now();

  bool hasContent(String id) => contentIds.contains(id);
  bool get hasQuran => contentIds.contains('quran');
  bool get hasAzkar => contentIds.contains('azkar');
  bool get hasHadith => contentIds.contains('hadith');
}
