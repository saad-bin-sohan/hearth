import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';

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

  Future<void> schedulePantryExpiryAlerts(List<PantryItemEntity> pantryItems);
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

  @override
  Future<void> schedulePantryExpiryAlerts(
    List<PantryItemEntity> pantryItems,
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

    final notificationId = _genericNotificationId(id);
    await _plugin.show(notificationId, title, body, _choreNotificationDetails);
  }

  @override
  Future<void> scheduleDocumentExpiryAlerts(
    List<DocumentEntity> documentsWithExpiry,
  ) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    for (
      var notificationId = 2000;
      notificationId < 3000;
      notificationId += 1
    ) {
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

  @override
  Future<void> schedulePantryExpiryAlerts(
    List<PantryItemEntity> pantryItems,
  ) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    for (
      var notificationId = 3000;
      notificationId < 4000;
      notificationId += 1
    ) {
      await _plugin.cancel(notificationId);
    }

    final planned = plannedPantryNotificationEntries(pantryItems);
    for (final entry in planned) {
      final item = entry.item;
      final daysUntil = item.daysUntilExpiry;
      if (daysUntil == null) {
        continue;
      }
      if (daysUntil <= 2) {
        await _plugin.show(
          entry.id,
          '🍎 Expiring soon in pantry',
          '${item.name} expires ${daysUntil == 0 ? "today" : "in $daysUntil day${daysUntil == 1 ? "" : "s"}"}',
          _pantryNotificationDetails,
        );
      } else {
        await _plugin.show(
          entry.id,
          '🗓️ Pantry item expiring this week',
          '${item.name} expires in $daysUntil days. Use it soon.',
          _pantryNotificationDetails,
        );
      }
    }
  }

  @visibleForTesting
  static int genericNotificationIdFor(String id) {
    return 4000 + ((id.hashCode & 0x7fffffff) % 1000000);
  }

  @visibleForTesting
  static int documentNotificationIdFor(String documentId, String slot) {
    return 2000 + ('document-$documentId-$slot'.hashCode & 0x7fffffff) % 1000;
  }

  @visibleForTesting
  static List<({int id, PantryItemEntity item})>
  plannedPantryNotificationEntries(List<PantryItemEntity> pantryItems) {
    final planned = <({int id, PantryItemEntity item})>[];
    var idCounter = 3000;
    for (final item in pantryItems) {
      final daysUntil = item.daysUntilExpiry;
      if (item.expiryDate == null || daysUntil == null || daysUntil < 0) {
        continue;
      }
      if (daysUntil <= 2) {
        planned.add((id: idCounter++, item: item));
      } else if (daysUntil <= 6) {
        planned.add((id: idCounter++, item: item));
      }
      if (idCounter >= 3999) {
        break;
      }
    }
    return planned;
  }

  int _genericNotificationId(String id) {
    return genericNotificationIdFor(id);
  }

  int _documentNotificationId(String documentId, String slot) {
    return documentNotificationIdFor(documentId, slot);
  }

  static const NotificationDetails _choreNotificationDetails =
      NotificationDetails(
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

  static const NotificationDetails _pantryNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hearth_pantry',
          'Pantry expiry alerts',
          channelDescription: 'Expiry reminders for pantry items.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
}
