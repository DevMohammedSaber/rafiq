import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/azkar_repository.dart';
import '../../data/azkar_user_repository.dart';
import '../../domain/models/zikr.dart';

abstract class ZikrListState extends Equatable {
  const ZikrListState();
  @override
  List<Object?> get props => [];
}

class ZikrListInitial extends ZikrListState {}

class ZikrListLoading extends ZikrListState {}

class ZikrListLoaded extends ZikrListState {
  final List<Zikr> zikrList;
  final Set<String> favorites;

  const ZikrListLoaded({required this.zikrList, required this.favorites});

  @override
  List<Object?> get props => [zikrList, favorites];

  ZikrListLoaded copyWith({List<Zikr>? zikrList, Set<String>? favorites}) {
    return ZikrListLoaded(
      zikrList: zikrList ?? this.zikrList,
      favorites: favorites ?? this.favorites,
    );
  }
}

class ZikrListError extends ZikrListState {
  final String message;

  const ZikrListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ZikrListCubit extends Cubit<ZikrListState> {
  final AzkarRepository _repository;
  final AzkarUserRepository _userRepository;

  ZikrListCubit(this._repository, this._userRepository)
    : super(ZikrListInitial());

  Future<void> loadZikrForCategory(String categoryId) async {
    emit(ZikrListLoading());
    try {
      final zikrList = await _repository.loadZikrByCategory(categoryId);
      final favorites = await _userRepository.listFavorites();
      emit(
        ZikrListLoaded(
          zikrList: zikrList,
          favorites: Set<String>.from(favorites),
        ),
      );
    } catch (e) {
      emit(ZikrListError(e.toString()));
    }
  }

  Future<void> toggleFavorite(String zikrId) async {
    if (state is! ZikrListLoaded) return;

    final currentState = state as ZikrListLoaded;
    final isNowFavorite = await _userRepository.toggleFavorite(zikrId);

    final newFavorites = Set<String>.from(currentState.favorites);
    if (isNowFavorite) {
      newFavorites.add(zikrId);
    } else {
      newFavorites.remove(zikrId);
    }

    emit(currentState.copyWith(favorites: newFavorites));
  }
}
