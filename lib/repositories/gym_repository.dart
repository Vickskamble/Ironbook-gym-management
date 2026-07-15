import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gym_model.dart';
import '../core/utils/error_handler.dart';

class GymRepository {
  final SupabaseClient _client;

  GymRepository(this._client);

  Future<GymModel> getGym(String gymId) async {
    ErrorHandler.logStep('GymRepository.getGym', 'called');
    try {
      final response = await _client
          .from('gyms')
          .select()
          .eq('id', gymId)
          .single();

      return GymModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.getGym', e, stack);
      throw Exception('Failed to load gym: ${e.toString()}');
    }
  }

  Future<GymModel> updateGym(String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('GymRepository.updateGym', 'called');
    try {
      const allowedFields = {'name', 'address', 'phone', 'logo_url', 'website'};
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final response = await _client
          .from('gyms')
          .update(filtered)
          .eq('id', gymId)
          .select()
          .single();

      return GymModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.updateGym', e, stack);
      throw Exception('Failed to update gym: ${e.toString()}');
    }
  }

  Future<void> updateSubscription(
    String gymId,
    String subscriptionPlan,
    DateTime? subscriptionExpiresAt,
  ) async {
    ErrorHandler.logStep('GymRepository.updateSubscription', 'called');
    try {
      final data = <String, dynamic>{
        'subscription': subscriptionPlan,
      };
      if (subscriptionExpiresAt != null) {
        data['subscription_expires_at'] = subscriptionExpiresAt.toIso8601String();
      }
      await _client.from('gyms').update(data).eq('id', gymId);
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.updateSubscription', e, stack);
      throw Exception('Failed to update subscription: ${e.toString()}');
    }
  }

  Future<String?> getSubscriptionPlan(String gymId) async {
    ErrorHandler.logStep('GymRepository.getSubscriptionPlan', 'called');
    try {
      final response = await _client
          .from('gyms')
          .select('subscription')
          .eq('id', gymId)
          .single();

      return (response['subscription'] as String?);
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.getSubscriptionPlan', e, stack);
      return null;
    }
  }

  Future<DateTime?> getSubscriptionExpiresAt(String gymId) async {
    ErrorHandler.logStep('GymRepository.getSubscriptionExpiresAt', 'called');
    try {
      final response = await _client
          .from('gyms')
          .select('subscription_expires_at')
          .eq('id', gymId)
          .single();

      final expiresAtStr = response['subscription_expires_at'] as String?;
      if (expiresAtStr == null || expiresAtStr.isEmpty) return null;
      return DateTime.parse(expiresAtStr);
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.getSubscriptionExpiresAt', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>> getGymSettings(String gymId) async {
    ErrorHandler.logStep('GymRepository.getGymSettings', 'called');
    try {
      final response = await _client
          .from('gym_settings')
          .select()
          .eq('gym_id', gymId)
          .maybeSingle();

      return response ?? <String, dynamic>{};
    } catch (e, stack) {
      ErrorHandler.logError('GymRepository.getGymSettings', e, stack);
      throw Exception('Failed to load gym settings: ${e.toString()}');
    }
  }
}
