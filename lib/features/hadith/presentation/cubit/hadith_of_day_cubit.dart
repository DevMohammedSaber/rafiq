import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/hadith_repository.dart';
import '../../data/hadith_daily_repository.dart';
import '../../domain/models/hadith_models.dart';

abstract class HadithOfDayState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HadithOfDayInitial extends HadithOfDayState {}

class HadithOfDayLoading extends HadithOfDayState {}

class HadithOfDayLoaded extends HadithOfDayState {
  final HadithItem item;
  HadithOfDayLoaded(this.item);
  @override
  List<Object?> get props => [item];
}

class HadithOfDayError extends HadithOfDayState {
  final String message;
  HadithOfDayError(this.message);
  @override
  List<Object?> get props => [message];
}

class HadithOfDayCubit extends Cubit<HadithOfDayState> {
  final HadithRepository _repository;
  final HadithDailyRepository _dailyRepository;

  HadithOfDayCubit(this._repository, this._dailyRepository)
    : super(HadithOfDayInitial());

  Future<void> loadToday() async {
    emit(HadithOfDayLoading());
    try {
      final total = await _repository.getTotalHadithCount();
      if (total == 0) {
        emit(HadithOfDayError('Database not initialized'));
        return;
      }
      final uid = await _dailyRepository.getDailyHadithUid(total);
      if (uid == null) {
        emit(HadithOfDayError('Failed to pick daily hadith'));
        return;
      }
      final item = await _repository.getHadithByUid(uid);
      if (item == null) {
        emit(HadithOfDayError('Hadith not found'));
        return;
      }
      emit(HadithOfDayLoaded(item));
    } catch (e) {
      emit(HadithOfDayError(e.toString()));
    }
  }
}
