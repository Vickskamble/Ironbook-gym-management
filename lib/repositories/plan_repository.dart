import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan_model.dart';

class PlanRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Get plans for a specific gym with mandatory gym_id (DATA ISOLATION RULE)
  Future<List<PlanModel>> getPlans({required String gymId}) async {
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

      return response.map((item) => PlanModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load plans: \$e');
    }
  }

  // Add a new plan
  Future<PlanModel> addPlan(PlanModel plan) async {
    try {
      final response = await _client
          .from('plans')
          .insert(plan.toJson())
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
    } catch (e) {
      throw Exception('Failed to add plan: \$e');
    }
  }

  // Update an existing plan
  Future<PlanModel> updatePlan(String planId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('plans')
          .update(data)
          .eq('id', planId)
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
    } catch (e) {
      throw Exception('Failed to update plan: \$e');
    }
  }

  // Soft delete a plan (mark as inactive)
  Future<void> deactivatePlan(String planId) async {
    try {
      // First check if there are active members on this plan
      final activeMembers = await _client
          .from('members')
          .select('count')
          .eq('plan_id', planId)
          .eq('status', 'Active');

      final memberCount = (activeMembers[0]['count'] as int?) ?? 0;
      
      if (memberCount > 0) {
        throw Exception('Cannot delete plan with active members');
      }

      // Delete the plan
      await _client
          .from('plans')
          .delete()
          .eq('id', planId);
    } catch (e) {
      throw Exception('Failed to delete plan: \$e');
    }
  }

  // Get plan statistics
  Future<Map<String, int>> getPlanStats(String gymId) async {
    try {
      final response = await _client
          .from('plans')
          .select('is_active')
          .eq('gym_id', gymId);

      final activeCount = response.where((item) => item['is_active'] == true).length;
      final inactiveCount = response.where((item) => item['is_active'] == false).length;

      return {
        'total': response.length,
        'active': activeCount,
        'inactive': inactiveCount,
      };
    } catch (e) {
      throw Exception('Failed to load plan stats: \$e');
    }
  }

  // Get unique colors used by other plans (for new plans)
  Future<List<String>> getUsedPlanColors(String gymId) async {
    try {
      final response = await _client
          .from('plans')
          .select('color')
          .eq('gym_id', gymId)
          .not('color', 'is', null);

      return response.map((item) => item['color'] as String).toList();
    } catch (e) {
      throw Exception('Failed to load plan colors: \$e');
    }
  }
}