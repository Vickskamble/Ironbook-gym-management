import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/gym_model.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Invalid email or password');
    }

    final profileResponse = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return ProfileModel.fromJson(profileResponse);
  }

  Future<(ProfileModel, GymModel)?> signUp({
    required String name,
    required String email,
    required String password,
    required String gymName,
    required String gymAddress,
    required String phone,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Signup failed');
      }

      // If session is null, email confirmation is required
      if (authResponse.session == null) {
        return null;
      }

      final user = authResponse.user!;

      // Wait for trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update the profile created by the trigger
      final profileResponse = await _client
          .from('profiles')
          .update({
            'name': name,
            'phone': phone,
            'role': 'owner',
          })
          .eq('id', user.id)
          .select()
          .single();

      final gymResponse = await _client
          .from('gyms')
          .insert({
            'name': gymName,
            'address': gymAddress,
            'phone': phone,
            'owner_id': user.id,
          })
          .select()
          .single();

      final gym = GymModel.fromJson(gymResponse);

      // Assign gym_id to profile
      await _client
          .from('profiles')
          .update({'gym_id': gym.id})
          .eq('id', user.id);

      final profile = ProfileModel.fromJson({
        ...profileResponse,
        'gym_id': gym.id,
      });

      return (profile, gym);
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  Future<ProfileModel?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;

      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();

      return ProfileModel.fromJson(profileResponse);
    } catch (e) {
      return null;
    }
  }

  Future<ProfileModel> updateProfile(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('profiles')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}
