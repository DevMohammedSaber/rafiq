import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/azkar_repository.dart';
import '../../domain/models/azkar_category.dart';

abstract class AzkarCategoriesState extends Equatable {
  const AzkarCategoriesState();
  @override
  List<Object?> get props => [];
}

class AzkarCategoriesInitial extends AzkarCategoriesState {}

class AzkarCategoriesLoading extends AzkarCategoriesState {}

class AzkarCategoriesLoaded extends AzkarCategoriesState {
  final List<AZkarCategory> categories;

  const AzkarCategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class AzkarCategoriesError extends AzkarCategoriesState {
  final String message;

  const AzkarCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

class AzkarCategoriesCubit extends Cubit<AzkarCategoriesState> {
  final AzkarRepository _repository;

  AzkarCategoriesCubit(this._repository) : super(AzkarCategoriesInitial());

  Future<void> loadCategories({bool forceReload = false}) async {
    emit(AzkarCategoriesLoading());
    try {
      if (forceReload) {
        _repository.clearCache();
      }
      final categories = await _repository.loadCategories();
      emit(AzkarCategoriesLoaded(categories: categories));
    } catch (e) {
      emit(AzkarCategoriesError(e.toString()));
    }
  }
}
