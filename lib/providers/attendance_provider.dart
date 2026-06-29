import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

final todayAttendanceProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, gymId) {
  return ref.read(attendanceRepositoryProvider).getTodayAttendance(gymId);
});

final memberAttendanceProvider = FutureProvider.family<List<AttendanceModel>, ({String gymId, String memberId})>(
  (ref, params) {
    return ref.read(attendanceRepositoryProvider).getMemberAttendance(params.gymId, params.memberId);
  },
);
