import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quran_repository.dart';
import '../../domain/models/surah.dart';

// States

abstract class QuranHomeState extends Equatable {
  const QuranHomeState();
  @override
  List<Object?> get props => [];
}

class QuranHomeInitial extends QuranHomeState {}

class QuranHomeLoading extends QuranHomeState {}

class QuranHomeLoaded extends QuranHomeState {
  final List<Surah> surahs;
  final List<Surah> filtered;
  final String query;

  const QuranHomeLoaded({
    required this.surahs,
    required this.filtered,
    this.query = '',
  });

  @override
  List<Object?> get props => [surahs, filtered, query];

  QuranHomeLoaded copyWith({
    List<Surah>? surahs,
    List<Surah>? filtered,
    String? query,
  }) {
    return QuranHomeLoaded(
      surahs: surahs ?? this.surahs,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
    );
  }
}

class QuranHomeError extends QuranHomeState {
  final String message;

  const QuranHomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit

class QuranHomeCubit extends Cubit<QuranHomeState> {
  final QuranRepository _repository;

  QuranHomeCubit(this._repository) : super(QuranHomeInitial());

  Future<void> load() async {
    emit(QuranHomeLoading());
    try {
      final surahs = await _repository.loadSurahs();
      emit(QuranHomeLoaded(surahs: surahs, filtered: surahs));
    } catch (e) {
      emit(QuranHomeError(e.toString()));
    }
  }

  void setQuery(String query) {
    if (state is! QuranHomeLoaded) return;

    final currentState = state as QuranHomeLoaded;

    if (query.isEmpty) {
      emit(currentState.copyWith(filtered: currentState.surahs, query: ''));
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = currentState.surahs.where((s) {
      return s.nameEn.toLowerCase().contains(lowerQuery) ||
          s.nameAr.contains(query) ||
          s.id.toString() == query;
    }).toList();

    emit(currentState.copyWith(filtered: filtered, query: query));
  }

  void clearQuery() {
    if (state is! QuranHomeLoaded) return;
    final currentState = state as QuranHomeLoaded;
    emit(currentState.copyWith(filtered: currentState.surahs, query: ''));
  }
}
