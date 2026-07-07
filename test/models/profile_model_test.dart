import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/profile_model.dart';

void main() {
  final sampleJson = {
    'id': 'user1',
    'name': 'Admin User',
    'email': 'admin@gym.com',
    'phone': '9876543210',
    'role': 'owner',
    'gym_id': 'gym1',
    'avatar_url': null,
    'language': 'en',
    'is_active': true,
    'last_login': '2024-01-15 10:00:00.000',
    'created_at': '2024-01-01 10:00:00.000',
    'updated_at': '2024-01-15 10:00:00.000',
  };

  group('ProfileModel', () {
    test('fromJson parses correctly', () {
      final profile = ProfileModel.fromJson(sampleJson);
      expect(profile.id, 'user1');
      expect(profile.name, 'Admin User');
      expect(profile.email, 'admin@gym.com');
      expect(profile.role, 'owner');
      expect(profile.gymId, 'gym1');
      expect(profile.isActive, true);
    });

    test('toJson roundtrip', () {
      final profile = ProfileModel.fromJson(sampleJson);
      final json = profile.toJson();
      expect(json['name'], 'Admin User');
      expect(json['email'], 'admin@gym.com');
      expect(json['role'], 'owner');
    });

    test('initials returns first letters', () {
      final profile = ProfileModel.fromJson(sampleJson);
      expect(profile.initials, 'AU');
    });

    test('initials for single name', () {
      final json = Map<String, dynamic>.from(sampleJson)..['name'] = 'Admin';
      final profile = ProfileModel.fromJson(json);
      expect(profile.initials, 'A');
    });

    test('isSuperAdmin returns true only for superadmin role', () {
      final owner = ProfileModel.fromJson(sampleJson);
      expect(owner.isSuperAdmin, false);

      final admin = ProfileModel.fromJson({...sampleJson, 'role': 'superadmin'});
      expect(admin.isSuperAdmin, true);
    });

    test('copyWith updates fields', () {
      final profile = ProfileModel.fromJson(sampleJson);
      final updated = profile.copyWith(name: 'New Name', role: 'superadmin');
      expect(updated.name, 'New Name');
      expect(updated.role, 'superadmin');
      expect(updated.id, 'user1');
    });
  });
}
