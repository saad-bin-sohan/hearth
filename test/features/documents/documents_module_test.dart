import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/app.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:hearth/core/router/app_router.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/documents/presentation/screens/vault_dashboard_screen.dart';
import 'package:hearth/features/documents/presentation/widgets/vault_lock_overlay.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('documents route renders the vault dashboard in its locked state', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
      'auth_token': 'token-1',
      'theme_mode': 'system',
    });
    final preferences = await SharedPreferences.getInstance();
    final database = createTestDatabase();
    addTearDown(database.close);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });

    final authRepository = LocalAuthRepository(
      database: database,
      passwordHasher: const PasswordHasher(),
      uuid: const Uuid(),
    );
    final householdRepository = LocalHouseholdRepository(
      database: database,
      uuid: const Uuid(),
    );

    final user = await authRepository.signUp(
      email: 'docs@example.com',
      password: 'SecurePass1',
    );
    final household = await householdRepository.createHousehold(
      userId: user.id,
      name: 'Warm House',
      emoji: '🏡',
      avatarColorKey: 'terracotta',
      currencyCode: 'USD',
    );
    await preferences.setString('auth_user_id', user.id);
    await preferences.setString('active_household_id', household.id);

    final container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWith((Ref ref) async => preferences),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HearthApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));

    router.go(VaultDashboardScreen.routePath);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Document Vault'), findsWidgets);
    expect(find.text('This vault is protected'), findsOneWidget);
  });

  testWidgets('vault lock overlay keeps protected content mounted', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: VaultLockOverlay(
              child: Center(child: Text('Sensitive file')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sensitive file'), findsOneWidget);
    expect(find.text('Document Vault'), findsOneWidget);
    expect(find.text('This vault is protected'), findsOneWidget);
  });
}
