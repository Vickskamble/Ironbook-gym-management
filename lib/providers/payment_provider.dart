import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import 'auth_provider.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(Supabase.instance.client);
});

final paymentListProvider =
    AsyncNotifierProvider.family<PaymentListNotifier, List<PaymentModel>, String>(
  PaymentListNotifier.new,
);

class PaymentListNotifier
    extends FamilyAsyncNotifier<List<PaymentModel>, String> {
  @override
  Future<List<PaymentModel>> build(String arg) async {
    ErrorHandler.logStep('PaymentListNotifier', 'build', {'arg': arg});
    ref.keepAlive();
    final repo = ref.read(paymentRepositoryProvider);
    return repo.getAllPayments(arg);
  }

  Future<void> refresh(String gymId) async {
    ErrorHandler.logStep('PaymentListNotifier', 'refresh', {'gymId': gymId});
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(paymentRepositoryProvider).getAllPayments(gymId));
  }

  Future<void> addPayment(String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('PaymentListNotifier', 'addPayment', {'gymId': gymId});
    data['created_by'] = Supabase.instance.client.auth.currentUser?.id;
    await ref.read(paymentRepositoryProvider).addPayment(gymId, data);
    await refresh(gymId);
  }

  Future<void> deletePayment(String paymentId) async {
    ErrorHandler.logStep('PaymentListNotifier', 'deletePayment', {'paymentId': paymentId});
    final gymId = ref.read(authProvider).gymId!;
    final repo = ref.read(paymentRepositoryProvider);
    await repo.deletePayment(paymentId, gymId);
    await refresh(gymId);
  }
}

final paymentDetailProvider =
    FutureProvider.family<PaymentModel, ({String gymId, String paymentId})>(
  (ref, params) async {
    ErrorHandler.logStep('paymentDetailProvider', 'build', {'gymId': params.gymId, 'paymentId': params.paymentId});
    return ref.read(paymentRepositoryProvider).getPaymentById(params.paymentId, params.gymId);
  },
);
