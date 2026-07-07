import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../core/utils/error_handler.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  Future<List<NotificationModel>> getNotifications(
    String gymId, {
    bool? isRead,
    String? type,
    int? page,
    int limit = 20,
  }) async {
    ErrorHandler.logStep('NotificationRepository.getNotifications', 'called');
    try {
      dynamic query = _client
          .from('notifications')
          .select();
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (type != null && type.isNotEmpty) {
        query = query.eq('type', type);
      }

      if (page != null) {
        final from = page * limit;
        final to = from + limit - 1;
        query = query.range(from, to);
      }

      final data = await query;
      return (data as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.getNotifications', e, stack);
      throw Exception('Failed to load notifications: ${e.toString()}');
    }
  }

  Future<int> getUnreadCount(String gymId) async {
    ErrorHandler.logStep('NotificationRepository.getUnreadCount', 'called');
    try {
      final data = await _client
          .from('notifications')
          .select('id')
          .eq('gym_id', gymId)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.getUnreadCount', e, stack);
      throw Exception('Failed to get unread count: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String gymId, String id) async {
    ErrorHandler.logStep('NotificationRepository.markAsRead', 'called');
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.markAsRead', e, stack);
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead(String gymId) async {
    ErrorHandler.logStep('NotificationRepository.markAllAsRead', 'called');
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('gym_id', gymId)
          .eq('is_read', false);
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.markAllAsRead', e, stack);
      throw Exception(
          'Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getExpiringMembersForNotification(
    String gymId, {
    int maxDays = 30,
  }) async {
    ErrorHandler.logStep('NotificationRepository.getExpiringMembersForNotification', 'called');
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final members = await _client
          .from('members')
          .select('id, name, phone, plan_name, membership_end, status')
          .eq('gym_id', gymId)
          .eq('status', 'Active')
          .not('membership_end', 'is', null)
          .order('membership_end', ascending: true);

      final List<Map<String, dynamic>> expiring = [];
      for (final m in members) {
        final end = DateTime.parse(m['membership_end'] as String);
        final endDay = DateTime(end.year, end.month, end.day);
        final daysLeft = endDay.difference(todayStart).inDays;
        if (daysLeft <= maxDays) {
          expiring.add({
            'id': m['id'],
            'name': m['name'],
            'phone': m['phone'],
            'plan_name': m['plan_name'] ?? 'N/A',
            'membership_end': m['membership_end'],
            'days_until_expiry': daysLeft,
          });
        }
      }
      return expiring;
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.getExpiringMembersForNotification', e, stack);
      throw Exception('Failed to load expiring members: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllMembersForNotification(
    String gymId,
  ) async {
    ErrorHandler.logStep('NotificationRepository.getAllMembersForNotification', 'called');
    try {
      final members = await _client
          .from('members')
          .select('id, name, phone, plan_name, membership_end, status')
          .eq('gym_id', gymId)
          .order('name', ascending: true);

      final List<Map<String, dynamic>> result = [];
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (final m in members) {
        int? daysLeft;
        if (m['membership_end'] != null) {
          final end = DateTime.parse(m['membership_end'] as String);
          final endDay = DateTime(end.year, end.month, end.day);
          daysLeft = endDay.difference(todayStart).inDays;
        }
        result.add({
          'id': m['id'],
          'name': m['name'],
          'phone': m['phone'] ?? '',
          'plan_name': m['plan_name'] ?? 'N/A',
          'membership_end': m['membership_end'],
          'status': m['status'],
          'days_until_expiry': daysLeft,
        });
      }
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.getAllMembersForNotification', e, stack);
      throw Exception('Failed to load members: ${e.toString()}');
    }
  }

  static const int _maxBulkNotifications = 200;

  Future<int> sendBulkNotifications(
    String gymId,
    List<Map<String, dynamic>> members,
    String title,
    String body,
  ) async {
    ErrorHandler.logStep('NotificationRepository.sendBulkNotifications', 'called');
    try {
      if (members.length > _maxBulkNotifications) {
        throw Exception('Cannot send to more than $_maxBulkNotifications members at once');
      }

      int insertedCount = 0;
      for (final member in members) {
        final daysLeft = member['days_until_expiry'] as int?;
        String type = 'expiry_alert';

        final memberBody = body
            .replaceAll('{name}', (member['name'] as String? ?? 'Member'))
            .replaceAll('{days}', daysLeft?.toString() ?? 'N/A')
            .replaceAll('{plan}', (member['plan_name'] as String? ?? 'Plan'));

        await _client.from('notifications').insert({
          'gym_id': gymId,
          'title': title,
          'body': memberBody,
          'type': type,
          'is_read': false,
          'member_id': member['id'],
        });
        insertedCount++;

        if (insertedCount % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      ErrorHandler.logStep('NotificationRepository.sendBulkNotifications', 'returning result');
      return insertedCount;
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.sendBulkNotifications', e, stack);
      throw Exception('Failed to send bulk notifications: ${e.toString()}');
    }
  }

  Future<int> generateExpiryNotifications(String gymId) async {
    ErrorHandler.logStep('NotificationRepository.generateExpiryNotifications', 'called');
    try {
      final today = DateTime.now();

      final todayStart = DateTime(today.year, today.month, today.day);

      final expiringMembers = await _client
          .from('members')
          .select('id, name, membership_end')
          .eq('gym_id', gymId)
          .eq('status', 'Active')
          .not('membership_end', 'is', null)
          .order('membership_end', ascending: true);

      int insertedCount = 0;

      for (final member in expiringMembers) {
        final membershipEnd =
            DateTime.parse(member['membership_end'] as String);
        final memberName = member['name'] as String;
        final memberId = member['id'] as String;
        final daysUntilExpiry = membershipEnd.difference(todayStart).inDays;

        String? notificationType;
        String? title;
        String? body;

        if (daysUntilExpiry == 1) {
          notificationType = 'expiry_alert';
          title = 'Membership Expires Tomorrow';
          body = '$memberName\'s membership expires tomorrow';
        } else if (daysUntilExpiry == 3) {
          notificationType = 'expiry_alert';
          title = 'Membership Expiring in 3 Days';
          body = '$memberName\'s membership will expire in 3 days';
        } else if (daysUntilExpiry == 7) {
          notificationType = 'expiry_alert';
          title = 'Membership Expiring in 7 Days';
          body = '$memberName\'s membership will expire in 7 days';
        } else if (daysUntilExpiry < 0) {
          notificationType = 'expiry_alert';
          title = 'Membership Expired';
          body = '$memberName\'s membership has expired';
        }

        if (notificationType != null && title != null && body != null) {
          final existing = await _client
              .from('notifications')
              .select('id')
              .eq('gym_id', gymId)
              .eq('type', notificationType)
              .eq('member_id', memberId)
              .maybeSingle();

          if (existing == null) {
            await _client.from('notifications').insert({
              'gym_id': gymId,
              'title': title,
              'body': body,
              'type': notificationType,
              'is_read': false,
              'member_id': memberId,
            });
            insertedCount++;
          }
        }
      }

      ErrorHandler.logStep('NotificationRepository.generateExpiryNotifications', 'returning result');
      return insertedCount;
    } catch (e, stack) {
      ErrorHandler.logError('NotificationRepository.generateExpiryNotifications', e, stack);
      throw Exception(
          'Failed to generate expiry notifications: ${e.toString()}');
    }
  }
}
