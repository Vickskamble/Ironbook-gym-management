import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(Supabase.instance.client);
});

final expenseListProvider =
    AsyncNotifierProvider.family<
      ExpenseListNotifier,
      List<ExpenseModel>,
      String
    >(ExpenseListNotifier.new);

class ExpenseListNotifier
    extends FamilyAsyncNotifier<List<ExpenseModel>, String> {
  @override
  Future<List<ExpenseModel>> build(String arg) async {
    ErrorHandler.logStep('ExpenseListNotifier', 'build', {'arg': arg});
    ref.keepAlive();
    final repo = ref.read(expenseRepositoryProvider);
    return repo.getExpenses(arg);
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    ErrorHandler.logStep('ExpenseListNotifier', 'addExpense', data['title'] ?? '');
    final repo = ref.read(expenseRepositoryProvider);
    final gymId = arg;
    data['gym_id'] = gymId;
    data['created_at'] = DateTime.now().toIso8601String();
    data['created_by'] = Supabase.instance.client.auth.currentUser?.id ?? '';
    await repo.addExpense(data);
    await refresh();
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    ErrorHandler.logStep('ExpenseListNotifier', 'updateExpense', {'id': id});
    final repo = ref.read(expenseRepositoryProvider);
    await repo.updateExpense(arg, id, data);
    await refresh();
  }

  Future<void> deleteExpense(String id) async {
    ErrorHandler.logStep('ExpenseListNotifier', 'deleteExpense', {'id': id});
    final repo = ref.read(expenseRepositoryProvider);
    await repo.deleteExpense(arg, id);
    await refresh();
  }

  Future<void> refresh() async {
    ErrorHandler.logStep('ExpenseListNotifier', 'refresh');
    final repo = ref.read(expenseRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.getExpenses(arg));
  }
}
