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
}
