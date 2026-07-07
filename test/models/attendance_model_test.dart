import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/attendance_model.dart';

void main() {
  final sampleJson = {
    'id': 'att1',
    'gym_id': 'gym1',
    'member_id': 'mem1',
    'member_name': 'Rahul Sharma',
    'member_phone': '9876543210',
    'check_in': '2024-01-15 08:00:00.000',
    'check_out': '2024-01-15 09:30:00.000',
    'duration_minutes': 90,
    'marked_by': 'user1',
    'created_at': '2024-01-15 08:00:00.000',
  };

  group('AttendanceModel', () {
    test('fromJson parses correctly', () {
      final record = AttendanceModel.fromJson(sampleJson);
      expect(record.id, 'att1');
      expect(record.memberName, 'Rahul Sharma');
      expect(record.memberPhone, '9876543210');
      expect(record.durationMinutes, 90);
    });

    test('toJson roundtrip', () {
      final record = AttendanceModel.fromJson(sampleJson);
      final json = record.toJson();
      expect(json['member_id'], 'mem1');
      expect(json['duration_minutes'], 90);
    });

    test('copyWith updates fields', () {
      final record = AttendanceModel.fromJson(sampleJson);
      final updated = record.copyWith(memberName: 'New Name', durationMinutes: 60);
      expect(updated.memberName, 'New Name');
      expect(updated.durationMinutes, 60);
      expect(updated.id, 'att1');
    });
  });
}
