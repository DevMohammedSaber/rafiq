import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quran_search_repository.dart';
import '../../data/quran_repository.dart';
import '../../domain/models/quran_search_result.dart';
import '../../domain/models/surah.dart';

// States

abstract class QuranSearchState extends Equatable {
  const QuranSearchState();
  @override
  List<Object?> get props => [];
}

class QuranSearchInitial extends QuranSearchState {}

class QuranSearchLoading extends QuranSearchState {}

class QuranSearchLoadingMore extends QuranSearchState {
  final List<QuranSearchResult> currentResults;
  final String query;

  const QuranSearchLoadingMore({
    required this.currentResults,
    required this.query,
  });

  @override
  List<Object?> get props => [currentResults, query];
}

class QuranSearchLoaded extends QuranSearchState {
  final List<QuranSearchResult> results;
  final String query;
  final int? surahFilter;
  final bool exactMatch;
  final bool hasMore;
  final int totalCount;

  const QuranSearchLoaded({
    required this.results,
    required this.query,
    this.surahFilter,
    this.exactMatch = false,
    this.hasMore = false,
    this.totalCount = 0,
  });

  @override
  List<Object?> get props => [
    results,
    query,
    surahFilter,
    exactMatch,
    hasMore,
    totalCount,
  ];

  QuranSearchLoaded copyWith({
    List<QuranSearchResult>? results,
    String? query,
    int? surahFilter,
    bool? exactMatch,
    bool? hasMore,
    int? totalCount,
  }) {
    return QuranSearchLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      surahFilter: surahFilter ?? this.surahFilter,
      exactMatch: exactMatch ?? this.exactMatch,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class QuranSearchError extends QuranSearchState {
  final String message;

  const QuranSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit

class QuranSearchCubit extends Cubit<QuranSearchState> {
  final QuranSearchRepository _searchRepository;
  final QuranRepository _quranRepository;

  static const int _pageSize = 30;

  Timer? _debounceTimer;
  List<Surah>? _cachedSurahs;

  QuranSearchCubit({
    QuranSearchRepository? searchRepository,
    QuranRepository? quranRepository,
  }) : _searchRepository = searchRepository ?? QuranSearchRepository(),
       _quranRepository = quranRepository ?? QuranRepository(),
       super(QuranSearchInitial());

  /// Get list of surahs for filter dropdown
  Future<List<Surah>> getSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    _cachedSurahs = await _quranRepository.loadSurahs();
    return _cachedSurahs!;
  }

  /// Search with debounce
  void searchDebounced(
    String query, {
    int? surahId,
    bool exact = false,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      search(query, surahId: surahId, exact: exact);
    });
  }

  /// Perform search immediately
  Future<void> search(String query, {int? surahId, bool exact = false}) async {
    if (query.trim().isEmpty) {
      emit(QuranSearchInitial());
      return;
    }

    emit(QuranSearchLoading());

    try {
      final results = await _searchRepository.searchAyahs(
        query,
        limit: _pageSize,
        offset: 0,
        surahId: surahId,
        exact: exact,
      );

      final totalCount = await _searchRepository.countSearchResults(
        query,
        surahId: surahId,
        exact: exact,
      );

      emit(
        QuranSearchLoaded(
          results: results,
          query: query,
          surahFilter: surahId,
          exactMatch: exact,
          hasMore: results.length < totalCount,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      emit(QuranSearchError(e.toString()));
    }
  }

  /// Load more results
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! QuranSearchLoaded || !currentState.hasMore) {
      return;
    }

    emit(
      QuranSearchLoadingMore(
        currentResults: currentState.results,
        query: currentState.query,
      ),
    );

    try {
      final moreResults = await _searchRepository.searchAyahs(
        currentState.query,
        limit: _pageSize,
        offset: currentState.results.length,
        surahId: currentState.surahFilter,
        exact: currentState.exactMatch,
      );

      final allResults = [...currentState.results, ...moreResults];

      emit(
        currentState.copyWith(
          results: allResults,
          hasMore: allResults.length < currentState.totalCount,
        ),
      );
    } catch (e) {
      // Restore previous state on error
      emit(currentState);
    }
  }

  /// Update surah filter and re-search
  Future<void> setSurahFilter(int? surahId) async {
    final currentState = state;
    if (currentState is QuranSearchLoaded) {
      await search(
        currentState.query,
        surahId: surahId,
        exact: currentState.exactMatch,
      );
    }
  }

  /// Toggle exact match and re-search
  Future<void> setExactMatch(bool exact) async {
    final currentState = state;
    if (currentState is QuranSearchLoaded) {
      await search(
        currentState.query,
        surahId: currentState.surahFilter,
        exact: exact,
      );
    }
  }

  /// Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    emit(QuranSearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
