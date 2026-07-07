import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../core/utils/error_handler.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

  Future<PaymentModel> addPayment(String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('PaymentRepository.addPayment', 'called');
    try {
      const allowedFields = {'member_id', 'member_name', 'plan_id', 'plan_name', 'amount', 'discount', 'method', 'transaction_id', 'note', 'next_due_date'};
      var filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final amount = (filtered['amount'] as num?) ?? 0;
      final discount = (filtered['discount'] as num?) ?? 0;

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }
      if (discount < 0) {
        throw Exception('Discount cannot be negative');
      }
      if (discount > amount) {
        throw Exception('Discount cannot exceed amount');
      }

      final validMethods = {'Cash', 'UPI', 'Card', 'Cheque', 'Other'};
      if (filtered['method'] != null && !validMethods.contains(filtered['method'])) {
        throw Exception('Invalid payment method. Must be one of: Cash, UPI, Card, Cheque, Other');
      }

      final finalAmount = amount - discount;
      if (finalAmount < 0) {
        throw Exception('Final amount cannot be negative');
      }
      filtered['final_amount'] = finalAmount;
      filtered['gym_id'] = gymId;

      final response = await _supabase
          .from('payments')
          .insert(filtered)
          .select()
          .single();

      final memberId = data['member_id'] as String?;
      if (memberId == null || memberId.isEmpty) {
        throw Exception('Member ID is required');
      }

      final memberRes = await _supabase
          .from('members')
          .select('status, membership_end')
          .eq('gym_id', gymId)
          .eq('id', memberId)
          .maybeSingle();

      if (memberRes == null) {
        throw Exception('Member not found');
      }

      final memberStatus = memberRes['status'] as String? ?? 'Active';
      if (memberStatus == 'Deleted') {
        throw Exception('Cannot process payment for deleted member');
      }

      final planId = data['plan_id'] as String?;
      if (planId != null && planId.isNotEmpty) {
        final planResponse = await _supabase
            .from('plans')
            .select('duration_days')
            .eq('id', planId)
            .maybeSingle();

        if (planResponse != null) {
          final durationDays = planResponse['duration_days'] as int? ?? 30;
          if (durationDays <= 0 || durationDays > 3650) {
            throw Exception('Invalid plan duration');
          }

          final paidAt = data['paid_at'] != null
              ? DateTime.parse(data['paid_at'] as String)
              : DateTime.now();

          final membershipStart = data['membership_start'] != null
              ? DateTime.parse(data['membership_start'] as String)
              : paidAt;

          DateTime? currentEnd;
          if (memberRes['membership_end'] != null) {
            currentEnd = DateTime.parse(memberRes['membership_end'] as String);
          }

          final membershipEnd = (currentEnd != null && currentEnd.isAfter(membershipStart))
              ? currentEnd.add(Duration(days: durationDays))
              : membershipStart.add(Duration(days: durationDays));

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
              .eq('id', memberId);
        }
      }

      return PaymentModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.addPayment', e, stack);
      throw Exception('Failed to add payment: ${e.toString()}');
    }
  }

  Future<List<PaymentModel>> getPaymentsByMember(
    String gymId,
    String memberId,
  ) async {
    ErrorHandler.logStep('PaymentRepository.getPaymentsByMember', 'called');
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
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.getPaymentsByMember', e, stack);
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
    ErrorHandler.logStep('PaymentRepository.getAllPayments', 'called');
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
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.getAllPayments', e, stack);
      throw Exception('Failed to load payments: ${e.toString()}');
    }
  }

  Future<PaymentModel> getPaymentById(String paymentId, String gymId) async {
    ErrorHandler.logStep('PaymentRepository.getPaymentById', 'called');
    try {
      final response = await _supabase
          .from('payments')
          .select('*, members(name, phone), plans(name)')
          .eq('id', paymentId)
          .eq('gym_id', gymId)
          .single();

      final memberData = response['members'] as Map<String, dynamic>?;
      final planData = response['plans'] as Map<String, dynamic>?;
      if (memberData != null) {
        response['member_name'] = memberData['name'];
      }
      if (planData != null) {
        response['plan_name'] = planData['name'];
      }

      return PaymentModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.getPaymentById', e, stack);
      throw Exception('Failed to load payment: ${e.toString()}');
    }
  }

  Future<void> deletePayment(String paymentId, String gymId) async {
    ErrorHandler.logStep('PaymentRepository.deletePayment', 'called');
    try {
      await _supabase
          .from('payments')
          .delete()
          .eq('id', paymentId)
          .eq('gym_id', gymId);
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.deletePayment', e, stack);
      throw Exception('Failed to delete payment: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPaymentStats(String gymId) async {
    ErrorHandler.logStep('PaymentRepository.getPaymentStats', 'called');
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

      final result = {
        'today': todaySum,
        'thisMonth': monthSum,
        'total': totalSum,
        'todayCount': (todayPayments as List).length,
        'monthCount': (monthPayments as List).length,
        'totalCount': (allPayments as List).length,
      };
      ErrorHandler.logStep('PaymentRepository.getPaymentStats', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRepository.getPaymentStats', e, stack);
      throw Exception('Failed to load payment stats: ${e.toString()}');
    }
  }
}
