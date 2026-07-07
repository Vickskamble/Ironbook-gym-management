import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/notification_model.dart';

void main() {
  final sampleJson = {
    'id': 'notif1',
    'gym_id': 'gym1',
    'title': 'Payment Due',
    'body': 'Your membership is expiring soon',
    'type': 'expiry_alert',
    'is_read': false,
    'member_id': 'mem1',
    'created_at': '2024-01-15 10:00:00.000',
  };

  group('NotificationModel', () {
    test('fromJson parses correctly', () {
      final notif = NotificationModel.fromJson(sampleJson);
      expect(notif.id, 'notif1');
      expect(notif.title, 'Payment Due');
      expect(notif.body, 'Your membership is expiring soon');
      expect(notif.type, 'expiry_alert');
      expect(notif.isRead, false);
      expect(notif.memberId, 'mem1');
    });

    test('toJson roundtrip', () {
      final notif = NotificationModel.fromJson(sampleJson);
      final json = notif.toJson();
      expect(json['title'], 'Payment Due');
      expect(json['type'], 'expiry_alert');
      expect(json['is_read'], false);
    });

    test('copyWith updates fields', () {
      final notif = NotificationModel.fromJson(sampleJson);
      final updated = notif.copyWith(isRead: true, title: 'Updated');
      expect(updated.isRead, true);
      expect(updated.title, 'Updated');
      expect(updated.id, 'notif1');
    });
  });
}
