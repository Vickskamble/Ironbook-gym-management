import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/gym_model.dart';
import '../core/utils/rate_limiter.dart';
import '../core/utils/error_handler.dart';

class AuthRepository {
  final SupabaseClient _client;
  static final _loginRateLimiter = RateLimiter(maxAttempts: 5, window: Duration(minutes: 1));
  static final _signupRateLimiter = RateLimiter(maxAttempts: 3, window: Duration(minutes: 5));
  static final _resetPasswordRateLimiter = RateLimiter(maxAttempts: 3, window: Duration(minutes: 5));

  AuthRepository(this._client);

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 10 && clean.length <= 15;
  }

  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    ErrorHandler.logStep('AuthRepository.signIn', 'called');
    if (_loginRateLimiter.isRateLimited(email)) {
      throw Exception('Too many login attempts. Please try again after 1 minute.');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        _loginRateLimiter.recordAttempt(email);
        throw Exception('Invalid email or password');
      }

      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _loginRateLimiter.reset(email);
      ErrorHandler.logStep('AuthRepository.signIn', 'returning result');
      return ProfileModel.fromJson(profileResponse);
    } catch (e) {
      if (e is Exception) {
        _loginRateLimiter.recordAttempt(email);
      }
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    ErrorHandler.logStep('AuthRepository.signInWithGoogle', 'called');
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.ironbook.app://callback',
        queryParams: {'access_type': 'offline'},
      );
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.signInWithGoogle', e, stack);
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<(ProfileModel, GymModel)> signUp({
    required String name,
    required String email,
    required String password,
    required String gymName,
    required String gymAddress,
    required String phone,
    String? gymType,
  }) async {
    ErrorHandler.logStep('AuthRepository.signUp', 'called');
    final rateLimitKey = 'signup_$email';
    if (_signupRateLimiter.isRateLimited(rateLimitKey)) {
      throw Exception('Too many signup attempts. Please try again after 5 minutes.');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }
    if (!_isValidPhone(phone)) {
      throw Exception('Invalid phone number. Must be 10-15 digits.');
    }

    try {
      _signupRateLimiter.recordAttempt(rateLimitKey);
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      if (authResponse.user == null) {
        throw Exception('Signup failed');
      }

      User user = authResponse.user!;

      Map<String, dynamic> profileResponse;
      GymModel gym;

      if (authResponse.session != null) {
        profileResponse = await _completeSignupWithSession(
          user: user,
          name: name,
          phone: phone,
          gymName: gymName,
          gymAddress: gymAddress,
          gymType: gymType,
        );
        gym = await _createGym(
          user: user,
          gymName: gymName,
          gymAddress: gymAddress,
          phone: phone,
          gymType: gymType,
        );
        await _client
            .from('profiles')
            .update({'gym_id': gym.id})
            .eq('id', user.id);
      } else {
        profileResponse = await _client.rpc('complete_signup', params: {
          'p_user_id': user.id,
          'p_name': name,
          'p_phone': phone,
          'p_gym_name': gymName,
          'p_gym_address': gymAddress,
          'p_gym_type': gymType ?? '',
        });
        final gymData = await _client
            .from('gyms')
            .select()
            .eq('owner_id', user.id)
            .single();
        gym = GymModel.fromJson(gymData);
      }

      final profile = ProfileModel.fromJson({
        ...profileResponse,
        'gym_id': gym.id,
      });

      _signupRateLimiter.reset(rateLimitKey);
      ErrorHandler.logStep('AuthRepository.signUp', 'returning result');
      return (profile, gym);
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.signUp', e, stack);
      if (e is Exception && !e.toString().contains('Invalid email') && !e.toString().contains('Invalid phone')) {
        _signupRateLimiter.reset(rateLimitKey);
      }
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    ErrorHandler.logStep('AuthRepository.signOut', 'called');
    try {
      await _client.auth.signOut();
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.signOut', e, stack);
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  Future<ProfileModel?> getCurrentUser() async {
    ErrorHandler.logStep('AuthRepository.getCurrentUser', 'called');
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;

      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (profileResponse == null) return null;
      return ProfileModel.fromJson(profileResponse);
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.getCurrentUser', e, stack);
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    ErrorHandler.logStep('AuthRepository.resetPassword', 'called');
    final rateLimitKey = 'reset_$email';
    if (_resetPasswordRateLimiter.isRateLimited(rateLimitKey)) {
      throw Exception('Too many reset attempts. Please try again after 5 minutes.');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    try {
      _resetPasswordRateLimiter.recordAttempt(rateLimitKey);
      await _client.auth.resetPasswordForEmail(email);
      _resetPasswordRateLimiter.reset(rateLimitKey);
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.resetPassword', e, stack);
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    ErrorHandler.logStep('AuthRepository.updatePassword', 'called');
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.updatePassword', e, stack);
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  Future<ProfileModel> updateProfile(String id, Map<String, dynamic> data) async {
    ErrorHandler.logStep('AuthRepository.updateProfile', 'called');
    try {
      const allowedFields = {'name', 'phone', 'avatar_url', 'language'};
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final phone = filtered['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number format');
      }

      final response = await _client
          .from('profiles')
          .update(filtered)
          .eq('id', id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('AuthRepository.updateProfile', e, stack);
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _completeSignupWithSession({
    required User user,
    required String name,
    required String phone,
    required String gymName,
    required String gymAddress,
    String? gymType,
  }) async {
    Map<String, dynamic> profileResponse;
    int retries = 0;
    while (true) {
      try {
        profileResponse = await _client
            .from('profiles')
            .update({
              'name': name,
              'phone': phone,
              'role': 'owner',
            })
            .eq('id', user.id)
            .select()
            .single();
        break;
      } catch (e, stack) {
        ErrorHandler.logError('AuthRepository._completeSignupWithSession', e, stack);
        retries++;
        if (retries >= 5) rethrow;
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return profileResponse;
  }

  Future<GymModel> _createGym({
    required User user,
    required String gymName,
    required String gymAddress,
    required String phone,
    String? gymType,
  }) async {
    final gymResponse = await _client
        .from('gyms')
        .insert({
          'name': gymName,
          'address': gymAddress,
          'phone': phone,
          'type': gymType,
          'owner_id': user.id,
        })
        .select()
        .single();
    return GymModel.fromJson(gymResponse);
  }
}
