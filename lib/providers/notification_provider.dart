import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationListProvider = FutureProvider.family<List<NotificationModel>, String>((ref, gymId) async {
  ErrorHandler.logStep('notificationListProvider', 'build', {'gymId': gymId});
  final repo = ref.read(notificationRepositoryProvider);
  await repo.generateExpiryNotifications(gymId);
  return repo.getNotifications(gymId);
});

final unreadCountProvider = FutureProvider.family<int, String>((ref, gymId) async {
  ErrorHandler.logStep('unreadCountProvider', 'build', {'gymId': gymId});
  final repo = ref.read(notificationRepositoryProvider);
  await repo.generateExpiryNotifications(gymId);
  return repo.getUnreadCount(gymId);
});
