import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile.dart';

/// Profile states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile is being saved
class ProfileSaving extends ProfileState {
  final UserProfile profile;

  const ProfileSaving(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile operation succeeded (for showing success message)
class ProfileSuccess extends ProfileState {
  final UserProfile profile;
  final String message;

  const ProfileSuccess(this.profile, this.message);

  @override
  List<Object?> get props => [profile, message];
}

/// Profile error
class ProfileError extends ProfileState {
  final String message;
  final UserProfile? previousProfile;

  const ProfileError(this.message, {this.previousProfile});

  @override
  List<Object?> get props => [message, previousProfile];
}

/// Account deleted
class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}

/// Signed out
class ProfileSignedOut extends ProfileState {
  const ProfileSignedOut();
}
