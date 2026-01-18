part of 'content_bootstrap_cubit.dart';

abstract class ContentBootstrapState extends Equatable {
  const ContentBootstrapState();

  @override
  List<Object?> get props => [];
}

class ContentBootstrapInitial extends ContentBootstrapState {
  const ContentBootstrapInitial();
}

class ContentBootstrapLoading extends ContentBootstrapState {
  final String message;
  final double progress;
  final String? phase;

  const ContentBootstrapLoading({
    required this.message,
    required this.progress,
    this.phase,
  });

  @override
  List<Object?> get props => [message, progress, phase];
}

class ContentBootstrapComplete extends ContentBootstrapState {
  const ContentBootstrapComplete();
}

class ContentBootstrapError extends ContentBootstrapState {
  final String message;

  const ContentBootstrapError({required this.message});

  @override
  List<Object?> get props => [message];
}
