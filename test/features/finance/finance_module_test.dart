import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('finance tab can add an expense end to end', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 2200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });

    final setup = await _createAuthenticatedAppState();
    addTearDown(setup.database.close);

    await tester.pumpWidget(
      createTestApp(
        preferences: setup.preferences,
        database: setup.database,
        overrides: documentShellTestOverrides(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Finance'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Finance Ledger'), findsOneWidget);

    final fabFinder = find.byType(FloatingActionButton).hitTestable();
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextFormField).at(0), '12.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'Milk');
    final saveFinder = find.widgetWithText(HearthButton, 'Save');
    await tester.ensureVisible(saveFinder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(tester.getRect(saveFinder).center);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Milk'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<({SharedPreferences preferences, AppDatabase database})>
_createAuthenticatedAppState() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_complete': true,
    'auth_token': 'token-1',
    'theme_mode': 'system',
  });
  final preferences = await SharedPreferences.getInstance();
  final database = createTestDatabase();
  final authRepository = LocalAuthRepository(
    database: database,
    passwordHasher: const PasswordHasher(),
    uuid: const Uuid(),
  );
  final householdRepository = LocalHouseholdRepository(
    database: database,
    uuid: const Uuid(),
  );

  final alice = await authRepository.signUp(
    email: 'alice@example.com',
    password: 'SecurePass1',
  );
  final bob = await authRepository.signUp(
    email: 'bob@example.com',
    password: 'SecurePass1',
  );
  final household = await householdRepository.createHousehold(
    userId: alice.id,
    name: 'Warm House',
    emoji: '🏡',
    avatarColorKey: 'terracotta',
    currencyCode: 'USD',
  );
  await householdRepository.joinHousehold(
    userId: bob.id,
    inviteCode: household.inviteCode,
  );

  await preferences.setString('auth_user_id', alice.id);
  await preferences.setString('active_household_id', household.id);
  return (preferences: preferences, database: database);
}
