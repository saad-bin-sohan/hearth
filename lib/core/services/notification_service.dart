abstract class NotificationService {
  Future<void> initialize();

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledFor,
  });
}

class LocalNotificationService implements NotificationService {
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
