import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/hadith_import_service.dart';

abstract class HadithBootstrapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BootstrapIdle extends HadithBootstrapState {}

class BootstrapImporting extends HadithBootstrapState {
  final HadithImportProgress progress;
  BootstrapImporting(this.progress);
  @override
  List<Object?> get props => [progress];
}

class BootstrapReady extends HadithBootstrapState {}

class BootstrapError extends HadithBootstrapState {
  final String message;
  BootstrapError(this.message);
  @override
  List<Object?> get props => [message];
}

class HadithBootstrapCubit extends Cubit<HadithBootstrapState> {
  final HadithImportService _importService;

  HadithBootstrapCubit(this._importService) : super(BootstrapIdle());

  Future<void> checkStatus() async {
    if (await _importService.needsImport()) {
      // Default to plain for bootstrap if needed
      startImport('plain');
    } else {
      emit(BootstrapReady());
    }
  }

  void startImport(String scriptType) {
    _importService.progressStream.listen((progress) {
      if (progress.phase == ImportPhase.completed) {
        emit(BootstrapReady());
      } else if (progress.phase == ImportPhase.error) {
        emit(BootstrapError(progress.error ?? 'Unknown error'));
      } else {
        emit(BootstrapImporting(progress));
      }
    });

    _importService.startImport(scriptType);
  }
}
