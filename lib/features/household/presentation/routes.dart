import 'package:go_router/go_router.dart';
import 'package:hearth/features/household/presentation/create_household_screen.dart';
import 'package:hearth/features/household/presentation/invite_screen.dart';
import 'package:hearth/features/household/presentation/join_household_confirm_screen.dart';
import 'package:hearth/features/household/presentation/join_household_screen.dart';

List<RouteBase> get householdRoutes => <RouteBase>[
      GoRoute(
        path: CreateHouseholdScreen.routePath,
        builder: (context, state) => const CreateHouseholdScreen(),
      ),
      GoRoute(
        path: InviteScreen.routePath,
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: JoinHouseholdScreen.routePath,
        builder: (context, state) => const JoinHouseholdScreen(),
      ),
      GoRoute(
        path: JoinHouseholdConfirmScreen.routePath,
        builder: (context, state) => JoinHouseholdConfirmScreen(
          inviteCode: state.uri.queryParameters['code'] ?? '',
        ),
      ),
    ];
