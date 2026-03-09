import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/features/auth/presentation/routes.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:hearth/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:hearth/features/chores/presentation/routes.dart';
import 'package:hearth/features/documents/presentation/routes.dart';
import 'package:hearth/features/finance/presentation/routes.dart';
import 'package:hearth/features/grocery/presentation/routes.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/home/presentation/settings_screen.dart';
import 'package:hearth/features/home/presentation/widgets/home_shell_scaffold.dart';
import 'package:hearth/features/household/presentation/household_module.dart';
import 'package:hearth/features/household/presentation/member_management_screen.dart';
import 'package:hearth/features/household/presentation/routes.dart';
import 'package:hearth/features/maintenance/presentation/routes.dart';

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      ...authRoutes,
      ...householdRoutes,
      GoRoute(
        path: MemberManagementScreen.routePath,
        builder: (context, state) => const MemberManagementScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: CalendarScreen.routePath,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/calendar/events/:eventId',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
          initialEvent: state.extra is CalendarEvent
              ? state.extra! as CalendarEvent
              : null,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeScreen.routePath,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: financeRoutes),
          StatefulShellBranch(routes: choresRoutes),
          StatefulShellBranch(routes: documentsRoutes),
          StatefulShellBranch(routes: groceryRoutes),
          StatefulShellBranch(routes: maintenanceRoutes),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/household',
                builder: (context, state) => const HouseholdModule(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
