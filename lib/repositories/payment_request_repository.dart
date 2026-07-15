import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/error_handler.dart';

class PaymentRequestRepository {
  final SupabaseClient _supabase;

  PaymentRequestRepository(this._supabase);

  Future<Map<String, dynamic>> create({
    required String gymId,
    required String planType,
    required String planName,
    required double amount,
  }) async {
    ErrorHandler.logStep('PaymentRequestRepository.create', 'called');
    final data = {
      'gym_id': gymId,
      'plan_type': planType,
      'plan_name': planName,
      'amount': amount,
      'status': 'pending',
      'created_by': _supabase.auth.currentUser?.id,
    };
    final response = await _supabase
        .from('payment_requests')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> completePayment({
    required String requestId,
    required String gymId,
    required String paymentId,
    required String plan,
    required double amount,
  }) async {
    ErrorHandler.logStep('PaymentRequestRepository.completePayment', 'called');
    try {
      final updateData = {
        'status': 'completed',
        'razorpay_payment_id': paymentId,
        'updated_at': DateTime.now().toIso8601String(),
        'payment_metadata': {
          'plan': plan,
          'amount': amount,
          'platform': 'flutter',
          'completed_at': DateTime.now().toIso8601String(),
        },
      };

      final response = await _supabase
          .from('payment_requests')
          .update(updateData)
          .eq('id', requestId)
          .eq('gym_id', gymId)
          .select()
          .single();

      return response;
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRequestRepository.completePayment', e, stack);
      throw Exception('Failed to complete payment request: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updatePlan(
    String requestId,
    String newPlan,
    String gymId,
  ) async {
    ErrorHandler.logStep('PaymentRequestRepository.updatePlan', 'called');
    try {
      final response = await _supabase
          .from('payment_requests')
          .update({
            'plan_type': newPlan,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('gym_id', gymId)
          .select()
          .single();

      return response;
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRequestRepository.updatePlan', e, stack);
      throw Exception('Failed to update plan: ${e.toString()}');
    }
  }

  Future<void> delete(String requestId, String gymId) async {
    ErrorHandler.logStep('PaymentRequestRepository.delete', 'called');
    try {
      await _supabase
          .from('payment_requests')
          .delete()
          .eq('id', requestId)
          .eq('gym_id', gymId);
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRequestRepository.delete', e, stack);
      throw Exception('Failed to delete payment request: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getByGymId(String gymId) async {
    ErrorHandler.logStep('PaymentRequestRepository.getByGymId', 'called');
    try {
      final response = await _supabase
          .from('payment_requests')
          .select()
          .eq('gym_id', gymId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, stack) {
      ErrorHandler.logError('PaymentRequestRepository.getByGymId', e, stack);
      throw Exception('Failed to load payment requests: ${e.toString()}');
    }
  }
}
