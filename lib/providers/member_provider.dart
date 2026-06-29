import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../repositories/member_repository.dart';
import 'auth_provider.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(Supabase.instance.client);
});

final memberListProvider =
    AsyncNotifierProvider.family<MemberListNotifier, List<MemberModel>, String>(
  MemberListNotifier.new,
);

class MemberListNotifier
    extends FamilyAsyncNotifier<List<MemberModel>, String> {
  @override
  Future<List<MemberModel>> build(String arg) async {
    ref.keepAlive();
    final repo = ref.read(memberRepositoryProvider);
    return repo.getMembers(arg);
  }

  Future<void> refresh(String gymId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(memberRepositoryProvider).getMembers(gymId));
  }

  Future<void> search(String gymId, String query) async {
    state = const AsyncValue.loading();
    if (query.trim().isEmpty) {
      state = await AsyncValue.guard(
          () => ref.read(memberRepositoryProvider).getMembers(gymId));
    } else {
      state = await AsyncValue.guard(
          () => ref.read(memberRepositoryProvider).getMembers(gymId, search: query));
    }
  }

  Future<void> addMember(String gymId, Map<String, dynamic> data) async {
    data['gym_id'] = gymId;
    await ref.read(memberRepositoryProvider).addMember(data);
    await refresh(gymId);
  }

  Future<void> updateMember(String memberId, Map<String, dynamic> data) async {
    final gymId = ref.read(authProvider).gymId!;
    await ref.read(memberRepositoryProvider).updateMember(gymId, memberId, data);
    await refresh(gymId);
  }

  Future<void> deleteMember(String memberId) async {
    final gymId = ref.read(authProvider).gymId!;
    await ref.read(memberRepositoryProvider).softDeleteMember(gymId, memberId);
    await refresh(gymId);
  }
}

final memberDetailProvider =
    FutureProvider.family<MemberModel, ({String gymId, String memberId})>(
  (ref, params) {
    return ref.read(memberRepositoryProvider).getMemberById(params.gymId, params.memberId);
  },
);
