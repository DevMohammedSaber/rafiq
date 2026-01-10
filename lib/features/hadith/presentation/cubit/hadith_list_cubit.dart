import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/hadith_repository.dart';
import '../../data/hadith_user_repository.dart';
import '../../domain/models/hadith_models.dart';

abstract class HadithListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HadithListInitial extends HadithListState {}

class HadithListLoading extends HadithListState {}

class HadithListLoaded extends HadithListState {
  final List<HadithItem> items;
  final Set<String> favorites;
  final bool hasMore;
  final String? query;

  HadithListLoaded({
    required this.items,
    required this.favorites,
    required this.hasMore,
    this.query,
  });

  @override
  List<Object?> get props => [items, favorites, hasMore, query];

  HadithListLoaded copyWith({
    List<HadithItem>? items,
    Set<String>? favorites,
    bool? hasMore,
    String? query,
  }) {
    return HadithListLoaded(
      items: items ?? this.items,
      favorites: favorites ?? this.favorites,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
    );
  }
}

class HadithListError extends HadithListState {
  final String message;
  HadithListError(this.message);
  @override
  List<Object?> get props => [message];
}

class HadithListCubit extends Cubit<HadithListState> {
  final HadithRepository _repository;
  final HadithUserRepository _userRepository;
  final String bookId;
  static const int _limit = 50;

  HadithListCubit(this._repository, this._userRepository, this.bookId)
    : super(HadithListInitial());

  Future<void> loadInitial() async {
    emit(HadithListLoading());
    try {
      final items = await _repository.getHadithByBook(
        bookId,
        limit: _limit,
        offset: 0,
      );
      final favorites = await _userRepository.listFavorites();
      emit(
        HadithListLoaded(
          items: items,
          favorites: favorites,
          hasMore: items.length == _limit,
        ),
      );
    } catch (e) {
      emit(HadithListError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is! HadithListLoaded) return;
    final currentState = state as HadithListLoaded;
    if (!currentState.hasMore) return;

    try {
      final offset = currentState.items.length;
      List<HadithItem> newItems;

      if (currentState.query != null && currentState.query!.isNotEmpty) {
        newItems = await _repository.searchInBook(
          bookId,
          currentState.query!,
          limit: _limit,
          offset: offset,
        );
      } else {
        newItems = await _repository.getHadithByBook(
          bookId,
          limit: _limit,
          offset: offset,
        );
      }

      emit(
        currentState.copyWith(
          items: [...currentState.items, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e) {
      // Handle error quietly or emit error state
    }
  }

  Future<void> search(String query) async {
    emit(HadithListLoading());
    try {
      if (query.isEmpty) {
        await loadInitial();
        return;
      }
      final items = await _repository.searchInBook(
        bookId,
        query,
        limit: _limit,
        offset: 0,
      );
      final favorites = await _userRepository.listFavorites();
      emit(
        HadithListLoaded(
          items: items,
          favorites: favorites,
          hasMore: items.length == _limit,
          query: query,
        ),
      );
    } catch (e) {
      emit(HadithListError(e.toString()));
    }
  }

  Future<void> toggleFavorite(String uid) async {
    if (state is! HadithListLoaded) return;
    final currentState = state as HadithListLoaded;

    final isFav = await _userRepository.toggleFavorite(uid, bookId);
    final newFavs = Set<String>.from(currentState.favorites);
    if (isFav) {
      newFavs.add(uid);
    } else {
      newFavs.remove(uid);
    }
    emit(currentState.copyWith(favorites: newFavs));
  }
}
