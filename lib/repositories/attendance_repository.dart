import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../core/utils/error_handler.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository(this._client);

  Future<AttendanceModel> checkIn(String gymId, String memberId) async {
    ErrorHandler.logStep('AttendanceRepository.checkIn', 'called');
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final duplicate = await _client
          .from('attendance')
          .select('id')
          .eq('gym_id', gymId)
          .eq('member_id', memberId)
          .gte('check_in', todayStart.toIso8601String())
          .lt('check_in', todayEnd.toIso8601String())
          .maybeSingle();

      if (duplicate != null) {
        throw Exception('Already checked in today');
      }

      final member = await _client
          .from('members')
          .select('name, status')
          .eq('id', memberId)
          .maybeSingle();

      if (member == null) {
        throw Exception('Member not found');
      }

      if (member['status'] == 'Deleted') {
        throw Exception('Cannot check in a deleted member');
      }

      final memberName = member['name'] as String;

      final response = await _client
          .from('attendance')
          .insert({
            'gym_id': gymId,
            'member_id': memberId,
            'member_name': memberName,
            'check_in': today.toIso8601String(),
            'marked_by': _client.auth.currentUser?.id ?? '',
          })
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('AttendanceRepository.checkIn', e, stack);
      throw Exception('Check-in failed: ${e.toString()}');
    }
  }

  Future<AttendanceModel> checkOut(
    String gymId,
    String attendanceId,
  ) async {
    ErrorHandler.logStep('AttendanceRepository.checkOut', 'called');
    try {
      final now = DateTime.now();

      final record = await _client
          .from('attendance')
          .select('check_in, check_out')
          .eq('gym_id', gymId)
          .eq('id', attendanceId)
          .maybeSingle();

      if (record == null) {
        throw Exception('Attendance record not found');
      }

      if (record['check_out'] != null) {
        throw Exception('Already checked out');
      }

      final checkIn = DateTime.parse(record['check_in'] as String);
      final durationMinutes = now.difference(checkIn).inMinutes;
      if (durationMinutes < 0) {
        throw Exception('Invalid check-out time');
      }

      final response = await _client
          .from('attendance')
          .update({
            'check_out': now.toIso8601String(),
            'duration_minutes': durationMinutes,
          })
          .eq('gym_id', gymId)
          .eq('id', attendanceId)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('AttendanceRepository.checkOut', e, stack);
      throw Exception('Check-out failed: ${e.toString()}');
    }
  }

  Future<List<AttendanceModel>> getTodayAttendance(String gymId) async {
    ErrorHandler.logStep('AttendanceRepository.getTodayAttendance', 'called');
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await _client
          .from('attendance')
          .select('*, members!inner(name, phone)')
          .eq('gym_id', gymId)
          .gte('check_in', todayStart.toIso8601String())
          .lt('check_in', todayEnd.toIso8601String())
          .order('check_in', ascending: false);

      return (response as List).map((e) {
        final attendance = AttendanceModel.fromJson(e);
        final member =
            (e['members'] is Map) ? e['members'] as Map<String, dynamic>? : null;
        return attendance.copyWith(
          memberName: member?['name'] as String?,
          memberPhone: member?['phone'] as String?,
        );
      }).toList();
    } catch (e, stack) {
      ErrorHandler.logError('AttendanceRepository.getTodayAttendance', e, stack);
      throw Exception('Failed to load today attendance: ${e.toString()}');
    }
  }

  Future<List<AttendanceModel>> getMemberAttendance(
    String gymId,
    String memberId, {
    DateTime? from,
    DateTime? to,
  }) async {
    ErrorHandler.logStep('AttendanceRepository.getMemberAttendance', 'called');
    try {
      dynamic query = _client
          .from('attendance')
          .select('*, members!inner(name, phone)');
      query = query.eq('gym_id', gymId);
      query = query.eq('member_id', memberId);
      query = query.order('check_in', ascending: false);

      if (from != null) {
        query = query.gte('check_in', from.toIso8601String());
      }

      if (to != null) {
        final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
        query = query.lte('check_in', endOfDay.toIso8601String());
      }

      final response = await query;

      return (response as List).map((e) {
        final attendance = AttendanceModel.fromJson(e);
        final member =
            (e['members'] is Map) ? e['members'] as Map<String, dynamic>? : null;
        return attendance.copyWith(
          memberName: member?['name'] as String?,
          memberPhone: member?['phone'] as String?,
        );
      }).toList();
    } catch (e, stack) {
      ErrorHandler.logError('AttendanceRepository.getMemberAttendance', e, stack);
      throw Exception('Failed to load member attendance: ${e.toString()}');
    }
  }
}
