import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quran_audio_repository.dart';
import '../../domain/models/reciter.dart';

// States

abstract class QuranAudioState extends Equatable {
  const QuranAudioState();
  @override
  List<Object?> get props => [];
}

class QuranAudioInitial extends QuranAudioState {}

class QuranAudioLoading extends QuranAudioState {}

class QuranAudioLoaded extends QuranAudioState {
  final List<Reciter> reciters;
  final String? selectedReciterId;
  final int? currentSurahId;
  final Map<String, List<int>> downloadedSurahs;
  final Map<String, int> downloadedSizes;
  final AudioPlaybackState playbackState;
  final String? downloadingReciterId;
  final int? downloadingSurahId;
  final double downloadProgress;
  final String? downloadError;

  const QuranAudioLoaded({
    required this.reciters,
    this.selectedReciterId,
    this.currentSurahId,
    this.downloadedSurahs = const {},
    this.downloadedSizes = const {},
    this.playbackState = const AudioPlaybackState(),
    this.downloadingReciterId,
    this.downloadingSurahId,
    this.downloadProgress = 0.0,
    this.downloadError,
  });

  @override
  List<Object?> get props => [
    reciters,
    selectedReciterId,
    currentSurahId,
    downloadedSurahs,
    downloadedSizes,
    playbackState,
    downloadingReciterId,
    downloadingSurahId,
    downloadProgress,
    downloadError,
  ];

  QuranAudioLoaded copyWith({
    List<Reciter>? reciters,
    String? selectedReciterId,
    int? currentSurahId,
    Map<String, List<int>>? downloadedSurahs,
    Map<String, int>? downloadedSizes,
    AudioPlaybackState? playbackState,
    String? downloadingReciterId,
    int? downloadingSurahId,
    double? downloadProgress,
    String? downloadError,
  }) {
    return QuranAudioLoaded(
      reciters: reciters ?? this.reciters,
      selectedReciterId: selectedReciterId ?? this.selectedReciterId,
      currentSurahId: currentSurahId ?? this.currentSurahId,
      downloadedSurahs: downloadedSurahs ?? this.downloadedSurahs,
      downloadedSizes: downloadedSizes ?? this.downloadedSizes,
      playbackState: playbackState ?? this.playbackState,
      downloadingReciterId: downloadingReciterId ?? this.downloadingReciterId,
      downloadingSurahId: downloadingSurahId ?? this.downloadingSurahId,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadError: downloadError,
    );
  }

  Reciter? get selectedReciter {
    if (selectedReciterId == null) return null;
    try {
      return reciters.firstWhere((r) => r.id == selectedReciterId);
    } catch (e) {
      return null;
    }
  }

  bool isSurahDownloaded(String reciterId, int surahId) {
    return downloadedSurahs[reciterId]?.contains(surahId) ?? false;
  }

  int get totalDownloadedSurahs {
    if (selectedReciterId == null) return 0;
    return downloadedSurahs[selectedReciterId]?.length ?? 0;
  }

  int get selectedReciterDownloadedSize {
    if (selectedReciterId == null) return 0;
    return downloadedSizes[selectedReciterId] ?? 0;
  }
}

class QuranAudioError extends QuranAudioState {
  final String message;

  const QuranAudioError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit

class QuranAudioCubit extends Cubit<QuranAudioState> {
  final QuranAudioRepository _repository;

  StreamSubscription? _downloadSubscription;

  QuranAudioCubit({QuranAudioRepository? repository})
    : _repository = repository ?? QuranAudioRepository(),
      super(QuranAudioInitial());

  /// Initialize and load reciters.
  Future<void> init({String? selectedReciterId}) async {
    emit(QuranAudioLoading());

    try {
      final reciters = await _repository.listReciters();

      // Get downloaded surahs for each reciter
      final downloadedSurahs = <String, List<int>>{};
      final downloadedSizes = <String, int>{};

      for (final reciter in reciters) {
        downloadedSurahs[reciter.id] = await _repository.getDownloadedSurahs(
          reciter.id,
        );
        downloadedSizes[reciter.id] = await _repository.getDownloadedSize(
          reciter.id,
        );
      }

      // Use provided or first reciter as default
      String? defaultReciterId = selectedReciterId;
      if (defaultReciterId == null && reciters.isNotEmpty) {
        defaultReciterId = reciters.first.id;
      }

      emit(
        QuranAudioLoaded(
          reciters: reciters,
          selectedReciterId: defaultReciterId,
          downloadedSurahs: downloadedSurahs,
          downloadedSizes: downloadedSizes,
        ),
      );
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  /// Select a reciter.
  void selectReciter(String reciterId) {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    emit(currentState.copyWith(selectedReciterId: reciterId));
  }

  /// Download a surah.
  Future<void> downloadSurah(String reciterId, int surahId) async {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    emit(
      currentState.copyWith(
        downloadingReciterId: reciterId,
        downloadingSurahId: surahId,
        downloadProgress: 0.0,
        downloadError: null,
      ),
    );

    _downloadSubscription?.cancel();
    _downloadSubscription = _repository
        .downloadSurah(reciterId, surahId)
        .listen((progress) async {
          final updatedState = state;
          if (updatedState is! QuranAudioLoaded) return;

          if (progress.status == AudioDownloadStatus.completed) {
            // Refresh downloaded list
            final downloadedList = await _repository.getDownloadedSurahs(
              reciterId,
            );
            final downloadedSize = await _repository.getDownloadedSize(
              reciterId,
            );

            final newDownloadedSurahs = Map<String, List<int>>.from(
              updatedState.downloadedSurahs,
            );
            newDownloadedSurahs[reciterId] = downloadedList;

            final newDownloadedSizes = Map<String, int>.from(
              updatedState.downloadedSizes,
            );
            newDownloadedSizes[reciterId] = downloadedSize;

            emit(
              updatedState.copyWith(
                downloadedSurahs: newDownloadedSurahs,
                downloadedSizes: newDownloadedSizes,
                downloadingReciterId: null,
                downloadingSurahId: null,
                downloadProgress: 1.0,
              ),
            );
          } else if (progress.status == AudioDownloadStatus.error) {
            emit(
              updatedState.copyWith(
                downloadingReciterId: null,
                downloadingSurahId: null,
                downloadProgress: 0.0,
                downloadError: progress.error,
              ),
            );
          } else {
            emit(updatedState.copyWith(downloadProgress: progress.progress));
          }
        });
  }

  /// Delete a downloaded surah.
  Future<void> deleteSurah(String reciterId, int surahId) async {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    await _repository.deleteSurah(reciterId, surahId);

    final downloadedList = await _repository.getDownloadedSurahs(reciterId);
    final downloadedSize = await _repository.getDownloadedSize(reciterId);

    final newDownloadedSurahs = Map<String, List<int>>.from(
      currentState.downloadedSurahs,
    );
    newDownloadedSurahs[reciterId] = downloadedList;

    final newDownloadedSizes = Map<String, int>.from(
      currentState.downloadedSizes,
    );
    newDownloadedSizes[reciterId] = downloadedSize;

    emit(
      currentState.copyWith(
        downloadedSurahs: newDownloadedSurahs,
        downloadedSizes: newDownloadedSizes,
      ),
    );
  }

  /// Delete all downloads for a reciter.
  Future<void> deleteAllForReciter(String reciterId) async {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    await _repository.deleteAllForReciter(reciterId);

    final newDownloadedSurahs = Map<String, List<int>>.from(
      currentState.downloadedSurahs,
    );
    newDownloadedSurahs[reciterId] = [];

    final newDownloadedSizes = Map<String, int>.from(
      currentState.downloadedSizes,
    );
    newDownloadedSizes[reciterId] = 0;

    emit(
      currentState.copyWith(
        downloadedSurahs: newDownloadedSurahs,
        downloadedSizes: newDownloadedSizes,
      ),
    );
  }

  /// Check if a surah is downloaded.
  Future<bool> isSurahDownloaded(String reciterId, int surahId) async {
    return await _repository.isDownloaded(reciterId, surahId);
  }

  /// Get streaming or local URL for playback.
  Future<String> getPlaybackUrl(String reciterId, int surahId) async {
    return await _repository.getStreamingUrl(reciterId, surahId);
  }

  /// Update playback state.
  void updatePlaybackState(AudioPlaybackState playbackState) {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    emit(currentState.copyWith(playbackState: playbackState));
  }

  /// Set current surah for audio context.
  void setCurrentSurah(int surahId) {
    final currentState = state;
    if (currentState is! QuranAudioLoaded) return;

    emit(currentState.copyWith(currentSurahId: surahId));
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
