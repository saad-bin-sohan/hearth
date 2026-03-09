import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/app.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.test(NativeDatabase.memory());
}

ProviderScope createTestApp({
  required SharedPreferences preferences,
  required AppDatabase database,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWith((Ref ref) async => preferences),
      appDatabaseProvider.overrideWithValue(database),
      ...overrides,
    ],
    child: const HearthApp(),
  );
}

List<Override> documentShellTestOverrides() {
  return <Override>[
    allDocumentsProvider.overrideWith(
      (Ref ref) => Stream<List<DocumentEntity>>.value(const <DocumentEntity>[]),
    ),
    documentBootstrapProvider.overrideWith((Ref ref) async {}),
    maintenanceBootstrapProvider.overrideWith((Ref ref) async {}),
  ];
}
