import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/tasbeeh_local_repository.dart';
import '../../data/tasbeeh_remote_repository.dart';
import '../../domain/models/tasbeeh_preset.dart';
import '../../domain/models/tasbeeh_stats.dart';
import 'tasbeeh_state.dart';

/// Cubit for managing Tasbeeh counter functionality
class TasbeehCubit extends Cubit<TasbeehState> {
  final TasbeehLocalRepository _localRepository;
  final TasbeehRemoteRepository _remoteRepository;
  final String? _userId;

  TasbeehCubit({
    required TasbeehLocalRepository localRepository,
    TasbeehRemoteRepository? remoteRepository,
    String? userId,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository ?? TasbeehRemoteRepository(),
       _userId = userId,
       super(const TasbeehLoading());

  /// Initialize tasbeeh data
  Future<void> init() async {
    emit(const TasbeehLoading());

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _localRepository.loadPresets(),
        _localRepository.loadSessionState(),
        _localRepository.loadStats(),
        _localRepository.loadSettings(),
      ]);

      var presets = results[0] as List<TasbeehPreset>;
      final session = results[1] as TasbeehSession;
      final stats = results[2] as TasbeehStats;
      final settings = results[3] as TasbeehSettings;

      // If authenticated, try to merge remote presets
      if (_userId != null) {
        final remotePresets = await _remoteRepository.fetchPresets(_userId);
        if (remotePresets != null && remotePresets.isNotEmpty) {
          // Merge remote custom presets with local
          final localCustomIds = presets
              .where((p) => !p.isDefault)
              .map((p) => p.id)
              .toSet();

          for (final remotePreset in remotePresets) {
            if (!localCustomIds.contains(remotePreset.id)) {
              presets.add(remotePreset);
            }
          }
        }
      }

      // Find selected preset
      var selected = presets.firstWhere(
        (p) => p.id == session.selectedPresetId,
        orElse: () => presets.first,
      );

      emit(
        TasbeehLoaded(
          presets: presets,
          selected: selected,
          count: session.currentCount,
          hapticEnabled: settings.hapticEnabled,
          soundEnabled: settings.soundEnabled,
          stats: stats,
        ),
      );
    } catch (e) {
      emit(TasbeehError(e.toString()));
    }
  }

  /// Increment counter
  Future<void> increment() async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    // Haptic feedback
    if (currentState.hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    final newCount = currentState.count + 1;
    final newStats = currentState.stats.addCount(1);

    emit(currentState.copyWith(count: newCount, stats: newStats));

    // Persist asynchronously
    _persistSession(currentState.selected.id, newCount);
    _persistStats(newStats);
  }

  /// Decrement counter (undo last tap)
  void decrement() {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;
    if (currentState.count <= 0) return;

    final newCount = currentState.count - 1;

    emit(currentState.copyWith(count: newCount));

    _persistSession(currentState.selected.id, newCount);
  }

  /// Reset counter to zero
  void reset() {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    emit(currentState.copyWith(count: 0));

    _persistSession(currentState.selected.id, 0);
  }

  /// Select a different preset
  Future<void> selectPreset(String presetId) async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    final selected = currentState.presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => currentState.selected,
    );

    if (selected.id == currentState.selected.id) return;

    // Reset count when switching presets
    emit(currentState.copyWith(selected: selected, count: 0));

    _persistSession(selected.id, 0);
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic() async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    final newValue = !currentState.hapticEnabled;

    emit(currentState.copyWith(hapticEnabled: newValue));

    await _localRepository.saveSettings(
      TasbeehSettings(
        hapticEnabled: newValue,
        soundEnabled: currentState.soundEnabled,
      ),
    );
  }

  /// Toggle sound feedback
  Future<void> toggleSound() async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    final newValue = !currentState.soundEnabled;

    emit(currentState.copyWith(soundEnabled: newValue));

    await _localRepository.saveSettings(
      TasbeehSettings(
        hapticEnabled: currentState.hapticEnabled,
        soundEnabled: newValue,
      ),
    );
  }

  /// Add a new custom preset
  Future<void> addPreset({
    required String titleAr,
    String? titleEn,
    required int goal,
    String? colorHex,
  }) async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    final newPreset = TasbeehPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titleAr: titleAr,
      titleEn: titleEn,
      goal: goal,
      isDefault: false,
      colorHex: colorHex,
    );

    final updatedPresets = [...currentState.presets, newPreset];

    emit(currentState.copyWith(presets: updatedPresets));

    await _persistPresets(updatedPresets);
  }

  /// Update an existing preset
  Future<void> updatePreset(TasbeehPreset updatedPreset) async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    // Cannot edit default presets
    if (updatedPreset.isDefault) return;

    final index = currentState.presets.indexWhere(
      (p) => p.id == updatedPreset.id,
    );
    if (index == -1) return;

    final updatedPresets = List<TasbeehPreset>.from(currentState.presets);
    updatedPresets[index] = updatedPreset;

    // Update selected if it was the one edited
    var newSelected = currentState.selected;
    if (currentState.selected.id == updatedPreset.id) {
      newSelected = updatedPreset;
    }

    emit(currentState.copyWith(presets: updatedPresets, selected: newSelected));

    await _persistPresets(updatedPresets);
  }

  /// Delete a custom preset
  Future<void> deletePreset(String presetId) async {
    final currentState = state;
    if (currentState is! TasbeehLoaded) return;

    // Cannot delete default presets
    final presetToDelete = currentState.presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => currentState.presets.first,
    );
    if (presetToDelete.isDefault) return;

    final updatedPresets = currentState.presets
        .where((p) => p.id != presetId)
        .toList();

    // If deleted preset was selected, switch to first preset
    var newSelected = currentState.selected;
    int newCount = currentState.count;
    if (currentState.selected.id == presetId) {
      newSelected = updatedPresets.first;
      newCount = 0;
    }

    emit(
      currentState.copyWith(
        presets: updatedPresets,
        selected: newSelected,
        count: newCount,
      ),
    );

    await _persistPresets(updatedPresets);
    if (currentState.selected.id == presetId) {
      _persistSession(newSelected.id, 0);
    }
  }

  /// Persist session state
  Future<void> _persistSession(String presetId, int count) async {
    await _localRepository.saveSessionState(
      TasbeehSession(selectedPresetId: presetId, currentCount: count),
    );
  }

  /// Persist stats
  Future<void> _persistStats(TasbeehStats stats) async {
    await _localRepository.saveStats(stats);
  }

  /// Persist presets (local + remote if authenticated)
  Future<void> _persistPresets(List<TasbeehPreset> presets) async {
    await _localRepository.savePresets(presets);

    if (_userId != null) {
      await _remoteRepository.syncPresets(_userId, presets);
    }
  }
}
