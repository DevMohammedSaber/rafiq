import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/azkar_repository.dart';
import '../../data/azkar_user_repository.dart';
import '../../domain/models/zikr.dart';

abstract class ZikrReaderState extends Equatable {
  const ZikrReaderState();
  @override
  List<Object?> get props => [];
}

class ZikrReaderInitial extends ZikrReaderState {}

class ZikrReaderLoaded extends ZikrReaderState {
  final List<Zikr> zikrList;
  final int currentIndex;
  final Map<String, int> counters;
  final Set<String> favorites;

  const ZikrReaderLoaded.zikrReaderLoaded({
    required this.zikrList,
    this.currentIndex = 0,
    this.counters = const {},
    this.favorites = const {},
  });

  Zikr? get currentZikr {
    if (zikrList.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= zikrList.length) {
      return null;
    }
    return zikrList[currentIndex];
  }

  int get currentCount => counters[currentZikr?.id ?? ''] ?? 0;

  bool get isFavorite =>
      currentZikr != null && favorites.contains(currentZikr!.id);

  bool get hasNext => currentIndex < zikrList.length - 1;
  bool get hasPrevious => currentIndex > 0;

  @override
  List<Object?> get props => [zikrList, currentIndex, counters, favorites];

  ZikrReaderLoaded copyWith({
    List<Zikr>? zikrList,
    int? currentIndex,
    Map<String, int>? counters,
    Set<String>? favorites,
  }) {
    return ZikrReaderLoaded.zikrReaderLoaded(
      zikrList: zikrList ?? this.zikrList,
      currentIndex: currentIndex ?? this.currentIndex,
      counters: counters ?? this.counters,
      favorites: favorites ?? this.favorites,
    );
  }
}

class ZikrReaderCubit extends Cubit<ZikrReaderState> {
  final AzkarRepository _repository;
  final AzkarUserRepository _userRepository;

  ZikrReaderCubit(this._repository, this._userRepository)
    : super(ZikrReaderInitial());

  Future<void> loadZikrForCategory(
    String categoryId, {
    int? initialIndex,
  }) async {
    try {
      final zikrList = await _repository.loadZikrByCategory(categoryId);
      final favorites = await _userRepository.listFavorites();
      final index =
          initialIndex != null &&
              initialIndex >= 0 &&
              initialIndex < zikrList.length
          ? initialIndex
          : 0;
      emit(
        ZikrReaderLoaded.zikrReaderLoaded(
          zikrList: zikrList,
          currentIndex: index,
          favorites: Set<String>.from(favorites),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  void incrementCounter() {
    if (state is! ZikrReaderLoaded) return;
    final currentState = state as ZikrReaderLoaded;
    final zikr = currentState.currentZikr;
    if (zikr == null) return;

    final newCounters = Map<String, int>.from(currentState.counters);
    final currentCount = newCounters[zikr.id] ?? 0;
    newCounters[zikr.id] = currentCount + 1;

    emit(currentState.copyWith(counters: newCounters));
  }

  void resetCounter() {
    if (state is! ZikrReaderLoaded) return;
    final currentState = state as ZikrReaderLoaded;
    final zikr = currentState.currentZikr;
    if (zikr == null) return;

    final newCounters = Map<String, int>.from(currentState.counters);
    newCounters[zikr.id] = 0;

    emit(currentState.copyWith(counters: newCounters));
  }

  void nextZikr() {
    if (state is! ZikrReaderLoaded) return;
    final currentState = state as ZikrReaderLoaded;
    if (!currentState.hasNext) return;

    emit(currentState.copyWith(currentIndex: currentState.currentIndex + 1));
  }

  void previousZikr() {
    if (state is! ZikrReaderLoaded) return;
    final currentState = state as ZikrReaderLoaded;
    if (!currentState.hasPrevious) return;

    emit(currentState.copyWith(currentIndex: currentState.currentIndex - 1));
  }

  Future<void> toggleFavorite() async {
    if (state is! ZikrReaderLoaded) return;
    final currentState = state as ZikrReaderLoaded;
    final zikr = currentState.currentZikr;
    if (zikr == null) return;

    final isNowFavorite = await _userRepository.toggleFavorite(zikr.id);
    final newFavorites = Set<String>.from(currentState.favorites);
    if (isNowFavorite) {
      newFavorites.add(zikr.id);
    } else {
      newFavorites.remove(zikr.id);
    }

    emit(currentState.copyWith(favorites: newFavorites));
  }
}
