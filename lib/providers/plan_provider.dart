import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/plan_repository.dart';
import '../models/plan_model.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

final planProvider =
    AsyncNotifierProvider.family<PlanNotifier, List<PlanModel>, String>(
  PlanNotifier.new,
);

class PlanNotifier extends FamilyAsyncNotifier<List<PlanModel>, String> {
  @override
  Future<List<PlanModel>> build(String arg) async {
    ref.keepAlive();
    final repo = ref.read(planRepositoryProvider);
    return repo.getPlans(gymId: arg);
  }

  Future<void> addPlan(PlanModel plan) async {
    final repo = ref.read(planRepositoryProvider);
    final newPlan = await repo.addPlan(plan);
    state = AsyncData([...state.value ?? [], newPlan]);
  }

  Future<void> updatePlan(String planId, Map<String, dynamic> data) async {
    final repo = ref.read(planRepositoryProvider);
    final updatedPlan = await repo.updatePlan(planId, data);
    final currentPlans = <PlanModel>[...state.value ?? []];
    final index = currentPlans.indexWhere((plan) => plan.id == planId);
    if (index != -1) {
      currentPlans[index] = updatedPlan;
      state = AsyncData(currentPlans);
    }
  }

  Future<void> deletePlan(String planId) async {
    final repo = ref.read(planRepositoryProvider);
    await repo.deactivatePlan(planId);
    final currentPlans = <PlanModel>[...state.value ?? []];
    currentPlans.removeWhere((p) => p.id == planId);
    state = AsyncData(currentPlans);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getPlans(gymId: arg),
    );
  }
}
