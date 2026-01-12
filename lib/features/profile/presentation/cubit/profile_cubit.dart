import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/profile_repository.dart';
import '../../data/guest_migration_service.dart';
import '../../domain/models/user_profile.dart';
import 'profile_state.dart';

/// Cubit for managing user profile
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;
  final GuestMigrationService _migrationService;

  ProfileCubit({
    ProfileRepository? repository,
    GuestMigrationService? migrationService,
  }) : _repository = repository ?? ProfileRepository(),
       _migrationService = migrationService ?? GuestMigrationService(),
       super(const ProfileLoading());

  /// Load the current user profile
  Future<void> load() async {
    emit(const ProfileLoading());

    try {
      final profile = await _repository.loadProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Update the user's display name
  Future<void> updateName(String name) async {
    final currentState = state;
    UserProfile? currentProfile;

    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    } else if (currentState is ProfileSuccess) {
      currentProfile = currentState.profile;
    }

    if (currentProfile == null) return;

    emit(ProfileSaving(currentProfile));

    try {
      await _repository.updateProfileName(name);

      final updatedProfile = currentProfile.copyWith(name: name);
      emit(ProfileSuccess(updatedProfile, 'profile.saved'));
    } catch (e) {
      emit(ProfileError(e.toString(), previousProfile: currentProfile));
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    emit(const ProfileSignedOut());
  }

  /// Delete the current user account
  Future<void> deleteAccount() async {
    final currentState = state;
    UserProfile? currentProfile;

    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    }

    if (currentProfile == null || currentProfile.isGuest) {
      emit(const ProfileError('Cannot delete guest account'));
      return;
    }

    emit(ProfileSaving(currentProfile));

    try {
      await _repository.deleteAccount();
      emit(const ProfileDeleted());
    } catch (e) {
      final message = e.toString();
      if (message.contains('requires-recent-login')) {
        emit(
          ProfileError(
            'requires-recent-login',
            previousProfile: currentProfile,
          ),
        );
      } else {
        emit(ProfileError(message, previousProfile: currentProfile));
      }
    }
  }

  /// Called after successful login to migrate guest data
  Future<void> migrateGuestData(String uid) async {
    try {
      final hasData = await _migrationService.hasGuestDataToMigrate();
      if (hasData) {
        await _migrationService.migrateGuestDataToUser(uid);
        await _migrationService.clearGuestData();
      }
    } catch (e) {
      // Log migration error but don't fail the login
    }
  }

  /// Get current profile if loaded
  UserProfile? get currentProfile {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profile;
    } else if (currentState is ProfileSuccess) {
      return currentState.profile;
    } else if (currentState is ProfileSaving) {
      return currentState.profile;
    } else if (currentState is ProfileError) {
      return currentState.previousProfile;
    }
    return null;
  }
}
