import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/quran_import_service.dart';

abstract class QuranBootstrapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuranBootstrapIdle extends QuranBootstrapState {}

class QuranBootstrapImporting extends QuranBootstrapState {
  final QuranImportProgress progress;
  QuranBootstrapImporting(this.progress);

  @override
  List<Object?> get props => [progress];
}

class QuranBootstrapReady extends QuranBootstrapState {}

class QuranBootstrapError extends QuranBootstrapState {
  final String message;
  QuranBootstrapError(this.message);

  @override
  List<Object?> get props => [message];
}

class QuranBootstrapCubit extends Cubit<QuranBootstrapState> {
  final QuranImportService _importService;

  QuranBootstrapCubit(this._importService) : super(QuranBootstrapIdle());

  Future<void> checkStatus() async {
    if (await _importService.needsImport()) {
      startImport();
    } else {
      emit(QuranBootstrapReady());
    }
  }

  void startImport() {
    _importService.progressStream.listen((progress) {
      if (progress.phase == QuranImportPhase.completed) {
        emit(QuranBootstrapReady());
      } else if (progress.phase == QuranImportPhase.error) {
        emit(QuranBootstrapError(progress.error ?? 'Unknown error'));
      } else {
        emit(QuranBootstrapImporting(progress));
      }
    });

    _importService.startImport();
  }
}
