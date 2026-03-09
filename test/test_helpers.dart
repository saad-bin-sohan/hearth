import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/app.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.test(NativeDatabase.memory());
}

ProviderScope createTestApp({
  required SharedPreferences preferences,
  required AppDatabase database,
}) {
  return ProviderScope(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWith((Ref ref) async => preferences),
      appDatabaseProvider.overrideWithValue(database),
    ],
    child: const HearthApp(),
  );
}
