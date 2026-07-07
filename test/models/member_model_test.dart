import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/member_model.dart';

void main() {
  final sampleJson = {
    'id': '123',
    'gym_id': 'gym1',
    'name': 'Rahul Sharma',
    'phone': '9876543210',
    'email': 'rahul@test.com',
    'gender': 'Male',
    'age': 28,
    'address': 'Mumbai',
    'plan_id': 'plan1',
    'plan_name': 'Basic',
    'join_date': '2024-01-15 00:00:00.000',
    'membership_start': '2024-01-15 00:00:00.000',
    'membership_end': '2024-02-14 00:00:00.000',
    'status': 'Active',
    'profile_pic': null,
    'emergency_contact': '9876543211',
    'blood_group': 'O+',
    'notes': 'Regular member',
    'created_at': '2024-01-15 10:00:00.000',
    'updated_at': '2024-01-15 10:00:00.000',
  };

  group('MemberModel', () {
    test('fromJson parses correctly', () {
      final member = MemberModel.fromJson(sampleJson);
      expect(member.id, '123');
      expect(member.name, 'Rahul Sharma');
      expect(member.phone, '9876543210');
      expect(member.email, 'rahul@test.com');
      expect(member.gender, 'Male');
      expect(member.age, 28);
      expect(member.planName, 'Basic');
      expect(member.status, 'Active');
      expect(member.bloodGroup, 'O+');
    });

    test('toJson roundtrip', () {
      final member = MemberModel.fromJson(sampleJson);
      final json = member.toJson();
      expect(json['id'], '123');
      expect(json['name'], 'Rahul Sharma');
      expect(json['status'], 'Active');
    });

    test('initials returns first letters', () {
      final member = MemberModel.fromJson(sampleJson);
      expect(member.initials, 'RS');
    });

    test('initials for single name', () {
      final json = Map<String, dynamic>.from(sampleJson)..['name'] = 'Rahul';
      final member = MemberModel.fromJson(json);
      expect(member.initials, 'R');
    });

    test('statusColor returns correct color', () {
      final active = MemberModel.fromJson(sampleJson);
      expect(active.statusColor.toARGB32(), 0xFF4CAF50);

      final expired = MemberModel.fromJson({...sampleJson, 'status': 'Expired'});
      expect(expired.statusColor.toARGB32(), 0xFFF44336);

      final paused = MemberModel.fromJson({...sampleJson, 'status': 'Paused'});
      expect(paused.statusColor.toARGB32(), 0xFFFFC107);

      final deleted = MemberModel.fromJson({...sampleJson, 'status': 'Deleted'});
      expect(deleted.statusColor.toARGB32(), 0xFF9E9E9E);
    });

    test('isExpired returns true when past membership end', () {
      final past = MemberModel.fromJson({...sampleJson, 'membership_end': '2020-01-01 00:00:00.000'});
      expect(past.isExpired, true);
    });

    test('daysUntilExpiry returns correct days', () {
      final member = MemberModel.fromJson({...sampleJson, 'membership_end': '2099-01-01 00:00:00.000'});
      expect(member.daysUntilExpiry, greaterThan(0));
    });

    test('copyWith updates fields', () {
      final member = MemberModel.fromJson(sampleJson);
      final updated = member.copyWith(name: 'New Name', status: 'Paused');
      expect(updated.name, 'New Name');
      expect(updated.status, 'Paused');
      expect(updated.id, '123');
    });
  });
}
