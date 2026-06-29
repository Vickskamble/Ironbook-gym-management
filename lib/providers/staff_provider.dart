import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_model.dart';
import '../models/profile_model.dart';
import '../repositories/staff_repository.dart';
import 'auth_provider.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(Supabase.instance.client);
});

final staffProvider = AsyncNotifierProvider<StaffNotifier, List<StaffModel>>(
  StaffNotifier.new,
);

final staffListProvider = staffProvider;

class StaffNotifier extends AsyncNotifier<List<StaffModel>> {
  @override
  Future<List<StaffModel>> build() async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return [];
    final repo = ref.read(staffRepositoryProvider);
    final profiles = await repo.getStaff(gymId);
    return profiles.map(_profileToStaff).toList();
  }

  StaffModel _profileToStaff(ProfileModel p) {
    return StaffModel(
      id: p.id,
      gymId: p.gymId ?? '',
      name: p.name,
      phone: p.phone,
      email: p.email,
      role: p.role,
      salary: 0.0,
      joinDate: p.createdAt,
      status: p.isActive ? 'Active' : 'Inactive',
      profilePic: p.avatarUrl,
      specialization: null,
      shift: null,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  Future<void> _refetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final gymId = ref.read(authProvider).gymId;
      if (gymId == null) return <StaffModel>[];
      final repo = ref.read(staffRepositoryProvider);
      final profiles = await repo.getStaff(gymId);
      return profiles.map(_profileToStaff).toList();
    });
  }

  Future<void> addStaff(StaffModel staff) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    final data = _staffToMap(staff, gymId);
    await ref.read(staffRepositoryProvider).addStaff(data);
    await _refetch();
  }

  Future<void> updateStaff(String id, StaffModel data) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    final map = _staffToMap(data, gymId);
    await ref.read(staffRepositoryProvider).updateStaff(gymId, id, map);
    await _refetch();
  }

  Future<void> terminateStaff(String id) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    await ref.read(staffRepositoryProvider).terminateStaff(gymId, id);
    await _refetch();
  }

  Future<void> filterByRole(String role) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final gymId = ref.read(authProvider).gymId;
      if (gymId == null) return <StaffModel>[];
      final repo = ref.read(staffRepositoryProvider);
      final profiles = await repo.getStaff(gymId, role: role);
      return profiles.map(_profileToStaff).toList();
    });
  }

  Map<String, dynamic> _staffToMap(StaffModel staff, String gymId) {
    final map = <String, dynamic>{
      'name': staff.name,
      'phone': staff.phone,
      'email': staff.email,
      'role': staff.role,
      'salary': staff.salary,
      'gym_id': gymId,
      'is_active': staff.status != 'Terminated',
      'join_date': staff.joinDate.toIso8601String(),
      'shift': staff.shift,
      'specialization': staff.specialization,
    };
    if (staff.profilePic != null) {
      map['avatar_url'] = staff.profilePic;
    }
    return map;
  }
}
