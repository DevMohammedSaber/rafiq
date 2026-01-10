import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/hadith_repository.dart';
import '../../data/hadith_user_repository.dart';
import '../../domain/models/hadith_models.dart';

abstract class HadithDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HadithDetailInitial extends HadithDetailState {}

class HadithDetailLoading extends HadithDetailState {}

class HadithDetailLoaded extends HadithDetailState {
  final HadithItem item;
  final bool isFavorite;

  HadithDetailLoaded(this.item, this.isFavorite);

  @override
  List<Object?> get props => [item, isFavorite];
}

class HadithDetailError extends HadithDetailState {
  final String message;
  HadithDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class HadithDetailCubit extends Cubit<HadithDetailState> {
  final HadithRepository _repository;
  final HadithUserRepository _userRepository;

  HadithDetailCubit(this._repository, this._userRepository)
    : super(HadithDetailInitial());

  Future<void> loadHadith(String uid) async {
    emit(HadithDetailLoading());
    try {
      final item = await _repository.getHadithByUid(uid);
      if (item == null) {
        emit(HadithDetailError('Hadith not found'));
        return;
      }
      final favorites = await _userRepository.listFavorites();
      emit(HadithDetailLoaded(item, favorites.contains(uid)));
    } catch (e) {
      emit(HadithDetailError(e.toString()));
    }
  }

  Future<void> toggleFavorite() async {
    if (state is! HadithDetailLoaded) return;
    final currentState = state as HadithDetailLoaded;

    final isFav = await _userRepository.toggleFavorite(
      currentState.item.uid,
      currentState.item.bookId,
    );
    emit(HadithDetailLoaded(currentState.item, isFav));
  }
}
