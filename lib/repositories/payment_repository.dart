import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

  Future<PaymentModel> addPayment(String gymId, Map<String, dynamic> data) async {
    try {
      data['gym_id'] = gymId;

      final response = await _supabase
          .from('payments')
          .insert(data)
          .select()
          .single();

      final planId = data['plan_id'] as String?;
      if (planId != null && planId.isNotEmpty) {
        final planResponse = await _supabase
            .from('plans')
            .select('duration_days')
            .eq('id', planId)
            .maybeSingle();

        if (planResponse != null) {
          final durationDays = planResponse['duration_days'] as int? ?? 30;
          final paidAt = data['paid_at'] != null
              ? DateTime.parse(data['paid_at'] as String)
              : DateTime.now();
          final membershipStart = paidAt;
          final membershipEnd =
              paidAt.add(Duration(days: durationDays));

          await _supabase
              .from('members')
              .update({
                'status': 'Active',
                'plan_id': planId,
                'plan_name': data['plan_name'],
                'membership_start': membershipStart.toIso8601String(),
                'membership_end': membershipEnd.toIso8601String(),
              })
              .eq('gym_id', gymId)
              .eq('id', data['member_id']);
        }
      }

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add payment: ${e.toString()}');
    }
  }

  Future<List<PaymentModel>> getPaymentsByMember(
    String gymId,
    String memberId,
  ) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*, plans(name)')
          .eq('gym_id', gymId)
          .eq('member_id', memberId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final planData = json['plans'] as Map<String, dynamic>?;
        if (planData != null) {
          json['plan_name'] = planData['name'];
        }
        return PaymentModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payments: ${e.toString()}');
    }
  }

  Future<List<PaymentModel>> getAllPayments(
    String gymId, {
    int? month,
    int? year,
    String? search,
    int? page,
    int limit = 20,
  }) async {
    try {
      dynamic query = _supabase
          .from('payments')
          .select('*, members(name, phone), plans(name)');
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (month != null && year != null) {
        final from = DateTime(year, month, 1);
        final to = DateTime(year, month + 1, 1);
        query = query
            .gte('paid_at', from.toIso8601String())
            .lt('paid_at', to.toIso8601String());
      } else if (year != null) {
        final from = DateTime(year, 1, 1);
        final to = DateTime(year + 1, 1, 1);
        query = query
            .gte('paid_at', from.toIso8601String())
            .lt('paid_at', to.toIso8601String());
      }

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'member_id.ilike.%$search%',
        );
      }

      if (page != null) {
        final from = page * limit;
        final to = from + limit - 1;
        query = query.range(from, to);
      }

      final response = await query;

      return (response as List).map((json) {
        final memberData = json['members'] as Map<String, dynamic>?;
        final planData = json['plans'] as Map<String, dynamic>?;
        if (memberData != null) {
          json['member_name'] = memberData['name'];
        }
        if (planData != null) {
          json['plan_name'] = planData['name'];
        }
        return PaymentModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payments: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPaymentStats(String gymId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 1);

      final todayPayments = await _supabase
          .from('payments')
          .select('final_amount')
          .eq('gym_id', gymId)
          .gte('paid_at', todayStart.toIso8601String())
          .lt('paid_at', todayEnd.toIso8601String());

      final monthPayments = await _supabase
          .from('payments')
          .select('final_amount')
          .eq('gym_id', gymId)
          .gte('paid_at', monthStart.toIso8601String())
          .lt('paid_at', monthEnd.toIso8601String());

      final allPayments = await _supabase
          .from('payments')
          .select('final_amount')
          .eq('gym_id', gymId);

      num todaySum = 0;
      for (final p in todayPayments) {
        todaySum += (p['final_amount'] as num?) ?? 0;
      }

      num monthSum = 0;
      for (final p in monthPayments) {
        monthSum += (p['final_amount'] as num?) ?? 0;
      }

      num totalSum = 0;
      for (final p in allPayments) {
        totalSum += (p['final_amount'] as num?) ?? 0;
      }

      return {
        'today': todaySum,
        'thisMonth': monthSum,
        'total': totalSum,
        'todayCount': (todayPayments as List).length,
        'monthCount': (monthPayments as List).length,
        'totalCount': (allPayments as List).length,
      };
    } catch (e) {
      throw Exception('Failed to load payment stats: ${e.toString()}');
    }
  }
}
