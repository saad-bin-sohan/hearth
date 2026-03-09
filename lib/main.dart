import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/app.dart';
import 'package:hearth/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = LocalNotificationService();
  await notificationService.initialize();
  runApp(
    ProviderScope(
      overrides: <Override>[
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const HearthApp(),
    ),
  );
}
