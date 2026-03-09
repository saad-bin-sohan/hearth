import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:hearth/core/theme/app_theme.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/auth/presentation/sign_up_screen.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/presentation/create_household_screen.dart';
import 'package:hearth/features/household/presentation/invite_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash redirects to sign in when onboarding is complete but no session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final database = createTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      createTestApp(preferences: preferences, database: database),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Authenticated household session exposes Finance and Members in More', (
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
      email: 'test@example.com',
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

    await tester.pumpWidget(
      createTestApp(preferences: preferences, database: database),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quick Summary'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Members'), findsNothing);

    await tester.tap(find.text('More'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Join a household'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('About Hearth'), findsOneWidget);
  });

  testWidgets('Sign up flows into create household and lands on invite screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final database = createTestDatabase();
    addTearDown(database.close);
    final router = GoRouter(
      initialLocation: SignUpScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: SignUpScreen.routePath,
          builder: (BuildContext context, GoRouterState state) {
            return const SignUpScreen();
          },
        ),
        GoRoute(
          path: CreateHouseholdScreen.routePath,
          builder: (BuildContext context, GoRouterState state) {
            return const CreateHouseholdScreen();
          },
        ),
        GoRoute(
          path: InviteScreen.routePath,
          builder: (BuildContext context, GoRouterState state) {
            return const InviteScreen();
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWith((Ref ref) async => preferences),
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Create your account'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'fresh@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'SecurePass1',
    );

    await tester.ensureVisible(find.widgetWithText(HearthButton, 'Create Account'));
    await tester.tap(find.widgetWithText(HearthButton, 'Create Account'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(preferences.getString('auth_user_id'), isNotNull);
    expect(find.text('Set the tone for your home'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).last,
      'Hearth House',
    );
    await tester.ensureVisible(find.widgetWithText(HearthButton, 'Create Household'));
    await tester.tap(find.widgetWithText(HearthButton, 'Create Household'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(preferences.getString('active_household_id'), isNotNull);
    expect(find.text('Invite Members'), findsOneWidget);
    expect(find.widgetWithText(HearthButton, 'Share Invite'), findsOneWidget);
  });
}
