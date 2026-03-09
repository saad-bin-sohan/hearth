import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/features/documents/domain/document_models.dart';

abstract class NotificationService {
  Future<void> initialize();

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledFor,
  });

  Future<void> scheduleDocumentExpiryAlerts(
    List<DocumentEntity> documentsWithExpiry,
  );
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

  @override
  Future<void> scheduleDocumentExpiryAlerts(
    List<DocumentEntity> documentsWithExpiry,
  ) async {}
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
    await _plugin.show(
      notificationId,
      title,
      body,
      _choreNotificationDetails,
    );
  }

  @override
  Future<void> scheduleDocumentExpiryAlerts(
    List<DocumentEntity> documentsWithExpiry,
  ) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    for (var notificationId = 2000; notificationId < 3000; notificationId += 1) {
      await _plugin.cancel(notificationId);
    }

    for (final document in documentsWithExpiry) {
      final daysUntil = document.daysUntilExpiry;
      if (document.expiryDate == null || daysUntil == null) {
        continue;
      }
      if (daysUntil <= 60 && daysUntil > 7) {
        await _plugin.show(
          _documentNotificationId(document.id, '60d'),
          'Document expiring soon',
          '${document.title} expires in $daysUntil days',
          _documentNotificationDetails,
        );
      }
      if (daysUntil <= 7 && daysUntil >= 0) {
        await _plugin.show(
          _documentNotificationId(document.id, '7d'),
          'Document expiring this week',
          '${document.title} expires in $daysUntil days. Renew it soon.',
          _documentNotificationDetails,
        );
      }
    }
  }

  static const NotificationDetails _choreNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'hearth_chores',
      'Chore reminders',
      channelDescription: 'Overdue chore reminders for Hearth households.',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _documentNotificationDetails =
      NotificationDetails(
      android: AndroidNotificationDetails(
        'hearth_documents',
        'Document expiry alerts',
        channelDescription: 'Expiry reminders for household documents.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

  int _documentNotificationId(String documentId, String slot) {
    return 2000 + ('document-$documentId-$slot'.hashCode & 0x7fffffff) % 1000;
  }
}
