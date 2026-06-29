import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/profile_model.dart';
import '../models/gym_model.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final gymProvider = StateProvider<GymModel?>((ref) {
  return null;
});

class AuthState {
  final ProfileModel? profile;
  final GymModel? gym;
  final String? gymId;
  final bool isLoading;
  final String? error;

  AuthState({
    this.profile,
    this.gym,
    this.gymId,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    ProfileModel? profile,
    GymModel? gym,
    String? gymId,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      profile: profile ?? this.profile,
      gym: gym ?? this.gym,
      gymId: gymId ?? this.gymId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  final Completer<void> _initCompleter = Completer<void>();

  AuthNotifier(this._authRepository) : super(AuthState()) {
    _initAuth();
  }

  Future<void> waitForInit() => _initCompleter.future;

  Future<void> _initAuth() async {
    state = state.copyWith(isLoading: true);

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = state.copyWith(isLoading: false);
      _initCompleter.complete();
      return;
    }

    try {
      final profile = await _authRepository.getCurrentUser();
      state = state.copyWith(
        profile: profile,
        gymId: profile?.gymId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Sign in attempt for: $email');

    try {
      final profile = await _authRepository.signIn(
        email: email,
        password: password,
      );

      ErrorHandler.logInfo('AuthNotifier', 'Sign in successful: ${profile.email}');
      
      state = state.copyWith(
        profile: profile,
        gymId: profile.gymId,
        isLoading: false,
        error: null,
      );
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.signIn', e, stack);
      final errorMsg = _getUserFriendlyError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String gymName,
    required String gymAddress,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Sign up attempt for: $email');

    try {
      final result = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
        gymName: gymName,
        gymAddress: gymAddress,
        phone: phone,
      );

      if (result == null) {
        state = state.copyWith(isLoading: false, error: null);
        return false; // Email confirmation required
      }

      final (profile, gym) = result;

      ErrorHandler.logInfo('AuthNotifier', 'Sign up successful: ${profile.email}');
      
      state = state.copyWith(
        profile: profile,
        gym: gym,
        gymId: profile.gymId,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.signUp', e, stack);
      final errorMsg = _getUserFriendlyError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    ErrorHandler.logInfo('AuthNotifier', 'Signing out...');

    try {
      await _authRepository.signOut();
      state = AuthState(isLoading: false);
      ErrorHandler.logInfo('AuthNotifier', 'Sign out successful');
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.signOut', e, stack);
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed: ${e.toString()}',
      );
    }
  }

  String _getUserFriendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    
    if (msg.contains('invalid login credentials') || 
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    
    if (msg.contains('email already registered') || 
        msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    
    if (msg.contains('weak password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    
    if (msg.contains('network') || 
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('dns')) {
      return 'Network error. Please check your internet connection.';
    }
    
    if (msg.contains('rate limit') || 
        msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    
    if (msg.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    return 'Authentication failed: ${error.toString()}';
  }
}
