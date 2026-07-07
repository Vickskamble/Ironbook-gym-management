import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

final todayAttendanceProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, gymId) {
  ErrorHandler.logStep('todayAttendanceProvider', 'build', {'gymId': gymId});
  return ref.read(attendanceRepositoryProvider).getTodayAttendance(gymId);
});

final memberAttendanceProvider = FutureProvider.family<List<AttendanceModel>, ({String gymId, String memberId})>(
  (ref, params) {
    ErrorHandler.logStep('memberAttendanceProvider', 'build', {'gymId': params.gymId, 'memberId': params.memberId});
    return ref.read(attendanceRepositoryProvider).getMemberAttendance(params.gymId, params.memberId);
  },
);
