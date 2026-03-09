import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NotificationService {
  Future<void> initialize();

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledFor,
  });
}

final notificationServiceProvider = Provider<NotificationService>((Ref ref) {
  return const NoopNotificationService();
});

class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledFor,
  }) async {}
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
  }

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledFor,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    final notificationId = id.hashCode & 0x7fffffff;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hearth_chores',
        'Chore reminders',
        channelDescription: 'Overdue chore reminders for Hearth households.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(notificationId, title, body, details);
  }
}
