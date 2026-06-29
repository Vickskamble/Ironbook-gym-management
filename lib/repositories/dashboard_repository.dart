import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';

class DashboardStats {
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;
  final num thisMonthRevenue;
  final int expiringSoon;

  DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
    required this.thisMonthRevenue,
    required this.expiringSoon,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalMembers: json['total_members'] ?? 0,
      activeMembers: json['active_members'] ?? 0,
      expiredMembers: json['expired_members'] ?? 0,
      thisMonthRevenue: json['this_month_revenue'] ?? 0,
      expiringSoon: json['expiring_soon'] ?? 0,
    );
  }
}

class MonthlyRevenue {
  final String month;
  final num amount;

  MonthlyRevenue({required this.month, required this.amount});

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] ?? '',
      amount: json['amount'] ?? 0,
    );
  }
}

class DashboardRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<DashboardStats> getDashboardStats(String gymId) async {
    try {
      final totalMembersResponse = await _client
          .from('members')
          .select('id')
          .eq('gym_id', gymId);

      final activeMembersResponse = await _client
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Active');

      final expiredMembersResponse = await _client
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Expired');

      final today = DateTime.now();
      final firstOfMonth = DateTime(today.year, today.month, 1);

      final thisMonthPayments = await _client
          .from('payments')
          .select('final_amount')
          .eq('gym_id', gymId)
          .gte('paid_at', firstOfMonth.toIso8601String());

      final endOfWeek = today.add(const Duration(days: 7));

      final expiringMembersResponse = await _client
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Active')
          .gte('membership_end', today.toIso8601String())
          .lte('membership_end', endOfWeek.toIso8601String());

      num thisMonthRevenue = 0;
      for (final p in thisMonthPayments) {
        thisMonthRevenue += (p['final_amount'] as num?) ?? 0;
      }

      return DashboardStats(
        totalMembers: (totalMembersResponse as List).length,
        activeMembers: (activeMembersResponse as List).length,
        expiredMembers: (expiredMembersResponse as List).length,
        thisMonthRevenue: thisMonthRevenue,
        expiringSoon: (expiringMembersResponse as List).length,
      );
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  Future<List<MonthlyRevenue>> getLastSixMonthsRevenue(String gymId) async {
    try {
      final today = DateTime.now();
      final sixMonthsAgo = DateTime(today.year, today.month - 6, 1);

      final response = await _client
          .from('payments')
          .select('paid_at, final_amount')
          .eq('gym_id', gymId)
          .gte('paid_at', sixMonthsAgo.toIso8601String())
          .order('paid_at', ascending: true);

      final Map<String, num> monthlyRevenue = {};
      for (final payment in response) {
        final paidAt = DateTime.parse(payment['paid_at'] as String);
        final monthKey =
            '${paidAt.month.toString().padLeft(2, '0')} ${paidAt.year}';
        final amount = (payment['final_amount'] as num?) ?? 0;
        monthlyRevenue[monthKey] =
            (monthlyRevenue[monthKey] ?? 0) + amount;
      }

      final List<MonthlyRevenue> result = [];
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(today.year, today.month - i, 1);
        final monthKey =
            '${monthDate.month.toString().padLeft(2, '0')} ${monthDate.year}';
        result.add(MonthlyRevenue(
          month: monthKey,
          amount: monthlyRevenue[monthKey] ?? 0,
        ));
      }

      return result;
    } catch (e) {
      throw Exception('Failed to load revenue data: $e');
    }
  }

  Future<List<MemberModel>> getRecentMembers(String gymId,
      {int limit = 5}) async {
    try {
      final response = await _client
          .from('members')
          .select()
          .eq('gym_id', gymId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => MemberModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load recent members: $e');
    }
  }

  Future<List<MemberModel>> getExpiringMembers(String gymId) async {
    try {
      final today = DateTime.now();
      final endOfWeek = today.add(const Duration(days: 7));

      final response = await _client
          .from('members')
          .select()
          .eq('gym_id', gymId)
          .eq('status', 'Active')
          .gte('membership_end', today.toIso8601String())
          .lte('membership_end', endOfWeek.toIso8601String())
          .order('membership_end', ascending: true);

      return (response as List)
          .map((item) => MemberModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expiring members: $e');
    }
  }
}
