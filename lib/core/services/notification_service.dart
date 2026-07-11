import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/error_handler.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance!;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _realtimeChannel;

  static Future<NotificationService> initialize() async {
    if (_instance != null) return _instance!;
    final service = NotificationService._();
    _instance = service;
    await service._init();
    return service;
  }

  NotificationService._();

  Future<void> _init() async {
    try {
      await _setupLocalNotifications();
      _setupRealtimeListener();
      ErrorHandler.logInfo('NotificationService', 'Initialized with Supabase Realtime');
    } catch (e, stack) {
      ErrorHandler.logError('NotificationService._init', e, stack);
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  void _setupRealtimeListener() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final userId = session.user.id;

      _realtimeChannel = Supabase.instance.client
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final data = payload.newRecord;
              final title = data['title'] as String? ?? 'IronBook';
              final body = data['body'] as String? ?? '';
              final type = data['type'] as String? ?? 'general';
              if (kDebugMode) debugPrint('[Notifications] Realtime notification: $title');
              _showLocalNotification(title, body, type);
            },
          )
          .subscribe();
    } catch (e, stack) {
      ErrorHandler.logError('NotificationService._setupRealtimeListener', e, stack);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (kDebugMode) debugPrint('[Notifications] Local notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification(String title, String body, String type) async {
    final androidDetails = AndroidNotificationDetails(
      'ironbook_channel',
      'IronBook Notifications',
      channelDescription: 'Gym management notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: type,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'ironbook_channel',
      'IronBook Notifications',
      channelDescription: 'Gym management notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> dispose() async {
    await _realtimeChannel?.unsubscribe();
  }
}
