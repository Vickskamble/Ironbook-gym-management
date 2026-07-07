import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan_model.dart';
import '../core/utils/error_handler.dart';

class PlanRepository {
  final SupabaseClient _client;

  PlanRepository(this._client);

  // Get plans for a specific gym with mandatory gym_id (DATA ISOLATION RULE)
  Future<List<PlanModel>> getPlans({required String gymId}) async {
    ErrorHandler.logStep('PlanRepository.getPlans', 'called');
    try {
      final response = await _client
          .from('plans')
          .select('''
            id,
            gym_id,
            name,
            description,
            duration_days,
            price,
            features,
            is_active,
            color,
            created_at,
            updated_at
          ''')
          .eq('gym_id', gymId)
          .order('created_at', ascending: false);

      final result = response.map((item) => PlanModel.fromJson(item)).toList();
      ErrorHandler.logStep('PlanRepository.getPlans', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.getPlans', e, stack);
      throw Exception('Failed to load plans: ${e.toString()}');
    }
  }

  // Add a new plan
  Future<PlanModel> addPlan(PlanModel plan) async {
    ErrorHandler.logStep('PlanRepository.addPlan', 'called');
    try {
      const allowedFields = {'gym_id', 'name', 'description', 'duration_days', 'price', 'features', 'is_active', 'color'};
      final planJson = plan.toJson();
      final filtered = Map<String, dynamic>.fromEntries(
        planJson.entries.where((e) => allowedFields.contains(e.key)),
      );

      final response = await _client
          .from('plans')
          .insert(filtered)
          .select('''
            id,
            gym_id,
            name,
            description,
            duration_days,
            price,
            features,
            is_active,
            color,
            created_at,
            updated_at
          ''');

      return PlanModel.fromJson(response[0]);
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.addPlan', e, stack);
      throw Exception('Failed to add plan: ${e.toString()}');
    }
  }

  // Update an existing plan
  Future<PlanModel> updatePlan(String planId, String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('PlanRepository.updatePlan', 'called');
    try {
      const allowedFields = {'name', 'description', 'duration_days', 'price', 'features', 'is_active', 'color'};
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final response = await _client
          .from('plans')
          .update(filtered)
          .eq('id', planId)
          .eq('gym_id', gymId)
          .select('''
            id,
            gym_id,
            name,
            description,
            duration_days,
            price,
            features,
            is_active,
            color,
            created_at,
            updated_at
          ''');

      return PlanModel.fromJson(response[0]);
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.updatePlan', e, stack);
      throw Exception('Failed to update plan: ${e.toString()}');
    }
  }

  // Soft delete a plan (mark as inactive)
  Future<void> deactivatePlan(String planId, String gymId) async {
    ErrorHandler.logStep('PlanRepository.deactivatePlan', 'called');
    try {
      // First check if there are active members on this plan
      final activeMembers = await _client
          .from('members')
          .select('id')
          .eq('plan_id', planId)
          .eq('status', 'Active');

      final memberCount = (activeMembers as List).length;
      
      if (memberCount > 0) {
        throw Exception('Cannot delete plan with active members');
      }

      // Soft delete the plan (mark inactive instead of hard delete)
      await _client
          .from('plans')
          .update({'is_active': false})
          .eq('id', planId)
          .eq('gym_id', gymId);
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.deactivatePlan', e, stack);
      throw Exception('Failed to delete plan: ${e.toString()}');
    }
  }

  // Get plan statistics
  Future<Map<String, int>> getPlanStats(String gymId) async {
    ErrorHandler.logStep('PlanRepository.getPlanStats', 'called');
    try {
      final response = await _client
          .from('plans')
          .select('is_active')
          .eq('gym_id', gymId);

      final activeCount = response.where((item) => item['is_active'] == true).length;
      final inactiveCount = response.where((item) => item['is_active'] == false).length;

      final result = {
        'total': response.length,
        'active': activeCount,
        'inactive': inactiveCount,
      };
      ErrorHandler.logStep('PlanRepository.getPlanStats', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.getPlanStats', e, stack);
      throw Exception('Failed to load plan stats: ${e.toString()}');
    }
  }

  // Get unique colors used by other plans (for new plans)
  Future<List<String>> getUsedPlanColors(String gymId) async {
    ErrorHandler.logStep('PlanRepository.getUsedPlanColors', 'called');
    try {
      final response = await _client
          .from('plans')
          .select('color')
          .eq('gym_id', gymId)
          .not('color', 'is', null);

      return response.map((item) => item['color'] as String).toList();
    } catch (e, stack) {
      ErrorHandler.logError('PlanRepository.getUsedPlanColors', e, stack);
      throw Exception('Failed to load plan colors: ${e.toString()}');
    }
  }
}
