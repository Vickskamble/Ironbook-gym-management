import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import 'auth_provider.dart';

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
    ref.keepAlive();
    final repo = ref.read(paymentRepositoryProvider);
    return repo.getAllPayments(arg);
  }

  Future<void> refresh(String gymId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(paymentRepositoryProvider).getAllPayments(gymId));
  }

  Future<void> addPayment(String gymId, Map<String, dynamic> data) async {
    await ref.read(paymentRepositoryProvider).addPayment(gymId, data);
    await refresh(gymId);
  }

  Future<void> deletePayment(String paymentId) async {
    final gymId = ref.read(authProvider).gymId!;
    final repo = ref.read(paymentRepositoryProvider);
    await repo.addPayment(gymId, {'id': paymentId, 'status': 'cancelled'});
    await refresh(gymId);
  }
}

final paymentDetailProvider =
    FutureProvider.family<PaymentModel, ({String gymId, String memberId})>(
  (ref, params) async {
    final payments = await ref.read(paymentRepositoryProvider).getPaymentsByMember(params.gymId, params.memberId);
    if (payments.isEmpty) throw Exception('Payment not found');
    return payments.first;
  },
);
