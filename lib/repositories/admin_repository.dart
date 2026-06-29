import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getAllGyms() async {
    try {
      final response = await _supabase
          .from('gyms')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load gyms: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final gyms = await _supabase.from('gyms').select('id');
      final members = await _supabase.from('members').select('id');

      final newMembersThisMonth = await _supabase
          .from('members')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());

      final payments = await _supabase
          .from('payments')
          .select('final_amount');

      final thisMonthPayments = await _supabase
          .from('payments')
          .select('final_amount')
          .gte('paid_at', monthStart.toIso8601String());

      num totalRevenue = 0;
      for (final p in payments) {
        totalRevenue += (p['final_amount'] as num?) ?? 0;
      }

      num thisMonthRevenue = 0;
      for (final p in thisMonthPayments) {
        thisMonthRevenue += (p['final_amount'] as num?) ?? 0;
      }

      return {
        'totalGyms': (gyms as List).length,
        'totalMembers': (members as List).length,
        'totalRevenue': totalRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'newMembersThisMonth': (newMembersThisMonth as List).length,
        'thisMonthPayments': (thisMonthPayments as List).length,
      };
    } catch (e) {
      throw Exception('Failed to load platform stats: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getGymDetail(String gymId) async {
    try {
      final gymResponse = await _supabase
          .from('gyms')
          .select()
          .eq('id', gymId)
          .single();

      final members = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId);

      final activeMembers = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Active');

      final staff = await _supabase
          .from('profiles')
          .select('id')
          .eq('gym_id', gymId)
          .neq('role', 'superadmin');

      final payments = await _supabase
          .from('payments')
          .select('final_amount')
          .eq('gym_id', gymId);

      num totalRevenue = 0;
      for (final p in payments) {
        totalRevenue += (p['final_amount'] as num?) ?? 0;
      }

      return {
        'gym': gymResponse,
        'totalMembers': (members as List).length,
        'activeMembers': (activeMembers as List).length,
        'totalStaff': (staff as List).length,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to load gym detail: ${e.toString()}');
    }
  }

  Future<void> updateSubscription(
    String gymId,
    String plan,
    DateTime expiresAt,
  ) async {
    try {
      await _supabase
          .from('gyms')
          .update({
            'subscription': plan,
            'subscription_expires_at': expiresAt.toIso8601String(),
          })
          .eq('id', gymId);
    } catch (e) {
      throw Exception('Failed to update subscription: ${e.toString()}');
    }
  }
}
