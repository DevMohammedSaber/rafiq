import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_repository.dart';

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthGuest extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  static const String _kGuestKey = 'is_guest';

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_kGuestKey) ?? false;

      // Check current user immediately (for hot restart scenarios)
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else if (isGuest) {
        emit(AuthGuest());
      } else {
        emit(AuthUnauthenticated());
      }

      // Listen for future auth state changes
      _authRepository.authStateChanges.listen((user) async {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          // Re-check guest status when user signs out
          final prefs = await SharedPreferences.getInstance();
          final guest = prefs.getBool(_kGuestKey) ?? false;
          if (guest) {
            emit(AuthGuest());
          } else {
            emit(AuthUnauthenticated());
          }
        }
      });
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
      await _clearGuestMode();
    } catch (e) {
      // Stream listener will handle state, but meaningful error is useful
      // If auth fails, we revert to Unauth (or remain Guest if was guest?)
      // Usually better to show error in UI via listener, but state might need to depend on PREVIOUS state.
      // For simplicity, emit Error, then check current user/guest status
      debugPrint(e.toString());
      emit(AuthError(e.toString()));
      await _checkCurrentStatus();
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithApple();
      await _clearGuestMode();
    } catch (e) {
      emit(AuthError(e.toString()));
      await _checkCurrentStatus();
    }
  }

  Future<void> continueAsGuest() async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kGuestKey, true);
      emit(AuthGuest());
    } catch (e) {
      emit(AuthError("Failed to set guest mode"));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      await _clearGuestMode();
      // Stream will emit Unauthenticated
    } catch (e) {
      emit(AuthError("Failed to sign out"));
    }
  }

  Future<void> _clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGuestKey);
  }

  Future<void> _checkCurrentStatus() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_kGuestKey) ?? false;
      if (isGuest) {
        emit(AuthGuest());
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }
}
