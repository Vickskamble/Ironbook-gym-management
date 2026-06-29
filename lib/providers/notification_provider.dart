import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationListProvider = FutureProvider.family<List<NotificationModel>, String>((ref, gymId) {
  return ref.read(notificationRepositoryProvider).getNotifications(gymId);
});

final unreadCountProvider = FutureProvider.family<int, String>((ref, gymId) {
  return ref.read(notificationRepositoryProvider).getUnreadCount(gymId);
});
