import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/hadith_repository.dart';
import '../../domain/models/hadith_models.dart';
import '../../../../core/content/content_update_event_bus.dart';

abstract class HadithBooksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HadithBooksInitial extends HadithBooksState {}

class HadithBooksLoading extends HadithBooksState {}

class HadithBooksLoaded extends HadithBooksState {
  final List<HadithBook> books;
  HadithBooksLoaded(this.books);
  @override
  List<Object?> get props => [books];
}

class HadithBooksError extends HadithBooksState {
  final String message;
  HadithBooksError(this.message);
  @override
  List<Object?> get props => [message];
}

class HadithBooksCubit extends Cubit<HadithBooksState> {
  final HadithRepository _repository;
  StreamSubscription<ContentUpdateEvent>? _contentUpdateSubscription;

  HadithBooksCubit(this._repository) : super(HadithBooksInitial()) {
    // Listen for content updates
    _contentUpdateSubscription = ContentUpdateEventBus.instance.stream.listen((
      event,
    ) {
      if (event.hasHadith) {
        // Reload books when hadith content is updated
        loadBooks();
      }
    });
  }

  Future<void> loadBooks() async {
    emit(HadithBooksLoading());
    try {
      final books = await _repository.getBooks();
      emit(HadithBooksLoaded(books));
    } catch (e) {
      emit(HadithBooksError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _contentUpdateSubscription?.cancel();
    return super.close();
  }
}
