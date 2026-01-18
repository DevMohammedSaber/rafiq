import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/tafsir_package_repository.dart';
import '../../domain/models/tafsir_package.dart';

// States

abstract class TafsirState extends Equatable {
  const TafsirState();
  @override
  List<Object?> get props => [];
}

class TafsirInitial extends TafsirState {}

class TafsirLoading extends TafsirState {}

class TafsirLoaded extends TafsirState {
  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final List<TafsirPackage> packages;
  final Map<String, bool> downloadStatus;
  final Map<String, String?> loadedTafsir;
  final String? selectedPackageId;
  final String? downloadingPackageId;
  final double downloadProgress;

  const TafsirLoaded({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    required this.packages,
    required this.downloadStatus,
    required this.loadedTafsir,
    this.selectedPackageId,
    this.downloadingPackageId,
    this.downloadProgress = 0.0,
  });

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    ayahText,
    packages,
    downloadStatus,
    loadedTafsir,
    selectedPackageId,
    downloadingPackageId,
    downloadProgress,
  ];

  TafsirLoaded copyWith({
    int? surahId,
    int? ayahNumber,
    String? ayahText,
    List<TafsirPackage>? packages,
    Map<String, bool>? downloadStatus,
    Map<String, String?>? loadedTafsir,
    String? selectedPackageId,
    String? downloadingPackageId,
    double? downloadProgress,
  }) {
    return TafsirLoaded(
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      ayahText: ayahText ?? this.ayahText,
      packages: packages ?? this.packages,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      loadedTafsir: loadedTafsir ?? this.loadedTafsir,
      selectedPackageId: selectedPackageId ?? this.selectedPackageId,
      downloadingPackageId: downloadingPackageId ?? this.downloadingPackageId,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  List<TafsirPackage> get tafsirPackages =>
      packages.where((p) => p.isTafsir).toList();

  List<TafsirPackage> get translationPackages =>
      packages.where((p) => p.isTranslation).toList();
}

class TafsirError extends TafsirState {
  final String message;

  const TafsirError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit

class TafsirCubit extends Cubit<TafsirState> {
  final TafsirPackageRepository _repository;

  StreamSubscription? _downloadSubscription;

  TafsirCubit({TafsirPackageRepository? repository})
    : _repository = repository ?? TafsirPackageRepository(),
      super(TafsirInitial());

  /// Load tafsir data for an ayah.
  Future<void> loadForAyah(int surahId, int ayahNumber, String ayahText) async {
    emit(TafsirLoading());

    try {
      final packages = await _repository.listPackages();

      // Check download status for each package
      final downloadStatus = <String, bool>{};
      final loadedTafsir = <String, String?>{};

      for (final package in packages) {
        final isDownloaded = await _repository.isDownloaded(package.id);
        downloadStatus[package.id] = isDownloaded;

        if (isDownloaded) {
          final text = await _repository.getTafsirText(
            package.id,
            surahId,
            ayahNumber,
          );
          loadedTafsir[package.id] = text;
        }
      }

      // Select first installed package by default
      String? selectedPackageId;
      for (final package in packages) {
        if (downloadStatus[package.id] == true &&
            loadedTafsir[package.id] != null) {
          selectedPackageId = package.id;
          break;
        }
      }

      emit(
        TafsirLoaded(
          surahId: surahId,
          ayahNumber: ayahNumber,
          ayahText: ayahText,
          packages: packages,
          downloadStatus: downloadStatus,
          loadedTafsir: loadedTafsir,
          selectedPackageId: selectedPackageId,
        ),
      );
    } catch (e) {
      emit(TafsirError(e.toString()));
    }
  }

  /// Select a package to view.
  void selectPackage(String packageId) {
    final currentState = state;
    if (currentState is! TafsirLoaded) return;

    emit(currentState.copyWith(selectedPackageId: packageId));
  }

  /// Download a package.
  Future<void> downloadPackage(String packageId) async {
    final currentState = state;
    if (currentState is! TafsirLoaded) return;

    emit(
      currentState.copyWith(
        downloadingPackageId: packageId,
        downloadProgress: 0.0,
      ),
    );

    _downloadSubscription?.cancel();
    _downloadSubscription = _repository.downloadPackage(packageId).listen((
      progress,
    ) async {
      final updatedState = state;
      if (updatedState is! TafsirLoaded) return;

      if (progress.status == DownloadStatus.completed) {
        // Reload tafsir text
        final text = await _repository.getTafsirText(
          packageId,
          updatedState.surahId,
          updatedState.ayahNumber,
        );

        final newDownloadStatus = Map<String, bool>.from(
          updatedState.downloadStatus,
        );
        newDownloadStatus[packageId] = true;

        final newLoadedTafsir = Map<String, String?>.from(
          updatedState.loadedTafsir,
        );
        newLoadedTafsir[packageId] = text;

        emit(
          updatedState.copyWith(
            downloadStatus: newDownloadStatus,
            loadedTafsir: newLoadedTafsir,
            downloadingPackageId: null,
            downloadProgress: 1.0,
            selectedPackageId: packageId,
          ),
        );
      } else if (progress.status == DownloadStatus.error) {
        emit(
          updatedState.copyWith(
            downloadingPackageId: null,
            downloadProgress: 0.0,
          ),
        );
      } else {
        emit(updatedState.copyWith(downloadProgress: progress.progress));
      }
    });
  }

  /// Delete a downloaded package.
  Future<void> deletePackage(String packageId) async {
    final currentState = state;
    if (currentState is! TafsirLoaded) return;

    await _repository.deletePackage(packageId);

    final newDownloadStatus = Map<String, bool>.from(
      currentState.downloadStatus,
    );
    newDownloadStatus[packageId] = false;

    final newLoadedTafsir = Map<String, String?>.from(
      currentState.loadedTafsir,
    );
    newLoadedTafsir.remove(packageId);

    String? newSelectedPackageId = currentState.selectedPackageId;
    if (newSelectedPackageId == packageId) {
      // Select another installed package
      newSelectedPackageId = null;
      for (final entry in newDownloadStatus.entries) {
        if (entry.value && newLoadedTafsir[entry.key] != null) {
          newSelectedPackageId = entry.key;
          break;
        }
      }
    }

    emit(
      currentState.copyWith(
        downloadStatus: newDownloadStatus,
        loadedTafsir: newLoadedTafsir,
        selectedPackageId: newSelectedPackageId,
      ),
    );
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
