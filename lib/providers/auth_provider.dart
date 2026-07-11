import 'dart:async';
import 'package:flutter/foundation.dart';
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
  return AuthRepository(Supabase.instance.client);
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
  bool _initCalled = false;
  final Completer<void> _initCompleter = Completer<void>();

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> waitForInit() {
    if (!_initCalled) {
      _initCalled = true;
      try {
        _initAuth();
      } catch (e) {
        if (!kReleaseMode) debugPrint('[Auth] waitForInit sync error: $e');
        if (!_initCompleter.isCompleted) _initCompleter.complete();
      }
    }
    return _initCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!kReleaseMode) debugPrint('[Auth] waitForInit TIMEOUT - forcing completion');
        if (!_initCompleter.isCompleted) _initCompleter.complete();
      },
    );
  }

  Future<GymModel?> _fetchGym(String? gymId) async {
    if (gymId == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('gyms')
          .select()
          .eq('id', gymId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response == null) return null;
      return GymModel.fromJson(response);
    } catch (e) {
      if (!kReleaseMode) debugPrint('[Auth] _fetchGym error: $e');
      return null;
    }
  }

  Future<void> _initAuth() async {
    if (!kReleaseMode) debugPrint('[Auth] _initAuth started');
    state = state.copyWith(isLoading: true);

    try {
      if (!kReleaseMode) debugPrint('[Auth] Checking currentSession...');
      final session = Supabase.instance.client.auth.currentSession;
      if (!kReleaseMode) debugPrint('[Auth] session = ${session != null ? "exists" : "null"}');

      if (session == null) {
        if (!kReleaseMode) debugPrint('[Auth] No session, skipping profile fetch');
        state = state.copyWith(isLoading: false);
        _initCompleter.complete();
        return;
      }

      if (!kReleaseMode) debugPrint('[Auth] Fetching current user profile...');
      final profile = await _authRepository.getCurrentUser()
          .timeout(const Duration(seconds: 5));
      if (!kReleaseMode) debugPrint('[Auth] profile = ${profile != null ? "found" : "null"}');

      if (profile != null) {
        if (!kReleaseMode) debugPrint('[Auth] Fetching gym...');
        final gym = await _fetchGym(profile.gymId);
        if (!kReleaseMode) debugPrint('[Auth] gym = ${gym != null ? "found" : "null"}');
        state = state.copyWith(
          profile: profile,
          gym: gym,
          gymId: profile.gymId,
          isLoading: false,
        );
      } else {
        if (!kReleaseMode) debugPrint('[Auth] No profile found, staying logged out');
        state = state.copyWith(isLoading: false);
      }
      if (!kReleaseMode) debugPrint('[Auth] _initAuth completed successfully');
    } catch (e, stack) {
      if (!kReleaseMode) debugPrint('========== AUTH INIT ERROR ==========');
      if (!kReleaseMode) debugPrint('Error: $e');
      if (!kReleaseMode) debugPrint('Stack: $stack');
      if (!kReleaseMode) debugPrint('======================================');
      state = state.copyWith(isLoading: false);
    }
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Sign in attempt');

    try {
      final profile = await _authRepository.signIn(
        email: email,
        password: password,
      );

      final gym = profile.gymId != null ? await _fetchGym(profile.gymId) : null;

      ErrorHandler.logInfo('AuthNotifier', 'Sign in successful');
      
      state = state.copyWith(
        profile: profile,
        gym: gym,
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
    String? gymType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Sign up attempt');

    try {
      final result = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
        gymName: gymName,
        gymAddress: gymAddress,
        phone: phone,
        gymType: gymType,
      );

      final (profile, gym) = result;
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Account created! Please check your email to verify, then log in.',
        );
        return false;
      }

      ErrorHandler.logInfo('AuthNotifier', 'Sign up successful');
      
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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Google sign in attempt');

    try {
      await _authRepository.signInWithGoogle();

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        state = state.copyWith(isLoading: false, error: 'Google sign-in failed');
        return;
      }

      final profile = await _authRepository.getCurrentUser();
      if (profile == null) {
        state = state.copyWith(isLoading: false, error: 'Could not load profile');
        return;
      }

      if (profile.gymId == null) {
        state = state.copyWith(
          profile: profile,
          gymId: null,
          isLoading: false,
          error: null,
        );
        return;
      }

      final gym = await _fetchGym(profile.gymId);
      state = state.copyWith(
        profile: profile,
        gym: gym,
        gymId: profile.gymId,
        isLoading: false,
        error: null,
      );
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.signInWithGoogle', e, stack);
      state = state.copyWith(
        isLoading: false,
        error: _getUserFriendlyError(e),
      );
    }
  }

  Future<void> signOut() async {
    // Immediately reset state for instant UI response
    state = AuthState(isLoading: false);
    ErrorHandler.logInfo('AuthNotifier', 'Signing out...');

    try {
      await _authRepository.signOut();
      ErrorHandler.logInfo('AuthNotifier', 'Sign out successful');
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.signOut', e, stack);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Password reset requested');

    try {
      await _authRepository.resetPassword(email);
      ErrorHandler.logInfo('AuthNotifier', 'Password reset email sent');
      state = state.copyWith(isLoading: false, error: null);
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.resetPassword', e, stack);
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    ErrorHandler.logInfo('AuthNotifier', 'Password update requested');

    try {
      await _authRepository.updatePassword(newPassword);
      ErrorHandler.logInfo('AuthNotifier', 'Password updated successfully');
      state = state.copyWith(isLoading: false, error: null);
    } catch (e, stack) {
      ErrorHandler.logError('AuthNotifier.updatePassword', e, stack);
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateProfileData(ProfileModel profile, GymModel? gym) {
    state = AuthState(
      profile: profile,
      gym: gym,
      gymId: profile.gymId,
      isLoading: false,
    );
  }

  Future<void> refreshGym() async {
    final currentProfile = state.profile;
    if (currentProfile?.gymId == null) return;
    try {
      final gym = await _fetchGym(currentProfile!.gymId);
      state = state.copyWith(gym: gym);
    } catch (_) {}
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
      return 'Password is too weak. Please use at least 8 characters.';
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

    if (msg.contains('email confirmation')) {
      return 'Account created! Check your email to verify, then log in.';
    }

    return 'Authentication failed: ${error.toString()}';
  }
}
