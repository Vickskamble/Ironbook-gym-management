import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gym_model.dart';

class GymRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<GymModel> getGym(String gymId) async {
    try {
      final response = await _client
          .from('gyms')
          .select()
          .eq('id', gymId)
          .single();

      return GymModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load gym: ${e.toString()}');
    }
  }

  Future<GymModel> updateGym(String gymId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('gyms')
          .update(data)
          .eq('id', gymId)
          .select()
          .single();

      return GymModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update gym: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getGymSettings(String gymId) async {
    try {
      final response = await _client
          .from('gym_settings')
          .select()
          .eq('gym_id', gymId)
          .maybeSingle();

      return response ?? <String, dynamic>{};
    } catch (e) {
      throw Exception('Failed to load gym settings: ${e.toString()}');
    }
  }
}
