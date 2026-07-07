import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../repositories/member_repository.dart';
import 'auth_provider.dart';
import 'package:ironbook/core/utils/error_handler.dart';

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
    ErrorHandler.logStep('MemberListNotifier', 'build', {'arg': arg});
    ref.keepAlive();
    final repo = ref.read(memberRepositoryProvider);
    await repo.markExpiredMembers(arg);
    return repo.getMembers(arg);
  }

  Future<void> refresh(String gymId) async {
    ErrorHandler.logStep('MemberListNotifier', 'refresh', {'gymId': gymId});
    state = const AsyncValue.loading();
    await ref.read(memberRepositoryProvider).markExpiredMembers(gymId);
    state = await AsyncValue.guard(
        () => ref.read(memberRepositoryProvider).getMembers(gymId));
  }

  Future<void> search(String gymId, String query) async {
    ErrorHandler.logStep('MemberListNotifier', 'search', {'gymId': gymId, 'query': query});
    state = const AsyncValue.loading();
    await ref.read(memberRepositoryProvider).markExpiredMembers(gymId);
    if (query.trim().isEmpty) {
      state = await AsyncValue.guard(
          () => ref.read(memberRepositoryProvider).getMembers(gymId));
    } else {
      state = await AsyncValue.guard(
          () => ref.read(memberRepositoryProvider).getMembers(gymId, search: query));
    }
  }

  Future<void> addMember(String gymId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('MemberListNotifier', 'addMember', {'gymId': gymId});
    data['gym_id'] = gymId;
    await ref.read(memberRepositoryProvider).addMember(data);
    await refresh(gymId);
  }

  Future<void> updateMember(String memberId, Map<String, dynamic> data) async {
    ErrorHandler.logStep('MemberListNotifier', 'updateMember', {'memberId': memberId});
    final gymId = ref.read(authProvider).gymId!;
    await ref.read(memberRepositoryProvider).updateMember(gymId, memberId, data);
    await refresh(gymId);
  }

  Future<void> deleteMember(String memberId) async {
    ErrorHandler.logStep('MemberListNotifier', 'deleteMember', {'memberId': memberId});
    final gymId = ref.read(authProvider).gymId!;
    await ref.read(memberRepositoryProvider).hardDeleteMember(gymId, memberId);
    await refresh(gymId);
  }
}

final memberDetailProvider =
    FutureProvider.family<MemberModel, ({String gymId, String memberId})>(
  (ref, params) async {
    ErrorHandler.logStep('memberDetailProvider', 'build', {'gymId': params.gymId, 'memberId': params.memberId});
    final repo = ref.read(memberRepositoryProvider);
    await repo.markExpiredMembers(params.gymId);
    return repo.getMemberById(params.gymId, params.memberId);
  },
);
