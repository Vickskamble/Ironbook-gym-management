import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/plan_repository.dart';
import '../models/plan_model.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(Supabase.instance.client);
});

final planProvider =
    AsyncNotifierProvider.family<PlanNotifier, List<PlanModel>, String>(
  PlanNotifier.new,
);

class PlanNotifier extends FamilyAsyncNotifier<List<PlanModel>, String> {
  @override
  Future<List<PlanModel>> build(String arg) async {
    ErrorHandler.logStep('PlanNotifier', 'build', {'arg': arg});
    ref.keepAlive();
    final repo = ref.read(planRepositoryProvider);
    return repo.getPlans(gymId: arg);
  }

  Future<void> addPlan(PlanModel plan) async {
    ErrorHandler.logStep('PlanNotifier', 'addPlan', plan.toJson());
    final repo = ref.read(planRepositoryProvider);
    final newPlan = await repo.addPlan(plan);
    state = AsyncData([...state.value ?? [], newPlan]);
  }

  Future<void> updatePlan(String planId, String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('PlanNotifier', 'updatePlan', {'planId': planId, 'gymId': gymId});
    final repo = ref.read(planRepositoryProvider);
    final updatedPlan = await repo.updatePlan(planId, gymId, data);
    final currentPlans = <PlanModel>[...state.value ?? []];
    final index = currentPlans.indexWhere((plan) => plan.id == planId);
    if (index != -1) {
      currentPlans[index] = updatedPlan;
      state = AsyncData(currentPlans);
    }
  }

  Future<void> deletePlan(String planId) async {
    ErrorHandler.logStep('PlanNotifier', 'deletePlan', {'planId': planId});
    final repo = ref.read(planRepositoryProvider);
    final gymId = arg;
    await repo.deactivatePlan(planId, gymId);
    final currentPlans = <PlanModel>[...state.value ?? []];
    currentPlans.removeWhere((p) => p.id == planId);
    state = AsyncData(currentPlans);
  }

  Future<void> refresh() async {
    ErrorHandler.logStep('PlanNotifier', 'refresh');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getPlans(gymId: arg),
    );
  }
}
