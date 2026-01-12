import 'package:equatable/equatable.dart';
import '../../domain/models/tasbeeh_preset.dart';
import '../../domain/models/tasbeeh_stats.dart';

/// Tasbeeh states
abstract class TasbeehState extends Equatable {
  const TasbeehState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state
class TasbeehLoading extends TasbeehState {
  const TasbeehLoading();
}

/// Loaded state with all data
class TasbeehLoaded extends TasbeehState {
  /// Available presets
  final List<TasbeehPreset> presets;

  /// Currently selected preset
  final TasbeehPreset selected;

  /// Current count in this session
  final int count;

  /// Goal from selected preset
  int get goal => selected.goal;

  /// Progress percentage (0.0 to 1.0)
  double get progress => goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;

  /// Whether goal is reached
  bool get goalReached => count >= goal;

  /// Haptic feedback enabled
  final bool hapticEnabled;

  /// Sound feedback enabled
  final bool soundEnabled;

  /// Statistics
  final TasbeehStats stats;

  const TasbeehLoaded({
    required this.presets,
    required this.selected,
    required this.count,
    required this.hapticEnabled,
    required this.soundEnabled,
    required this.stats,
  });

  @override
  List<Object?> get props => [
    presets,
    selected,
    count,
    hapticEnabled,
    soundEnabled,
    stats,
  ];

  TasbeehLoaded copyWith({
    List<TasbeehPreset>? presets,
    TasbeehPreset? selected,
    int? count,
    bool? hapticEnabled,
    bool? soundEnabled,
    TasbeehStats? stats,
  }) {
    return TasbeehLoaded(
      presets: presets ?? this.presets,
      selected: selected ?? this.selected,
      count: count ?? this.count,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      stats: stats ?? this.stats,
    );
  }
}

/// Error state
class TasbeehError extends TasbeehState {
  final String message;

  const TasbeehError(this.message);

  @override
  List<Object?> get props => [message];
}
