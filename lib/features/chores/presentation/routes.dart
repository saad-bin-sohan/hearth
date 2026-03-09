import 'package:go_router/go_router.dart';
import 'package:hearth/features/chores/presentation/chore_detail_screen.dart';
import 'package:hearth/features/chores/presentation/chore_list_screen.dart';
import 'package:hearth/features/chores/presentation/chores_dashboard_screen.dart';
import 'package:hearth/features/chores/presentation/fairness_score_screen.dart';

List<RouteBase> get choresRoutes => <RouteBase>[
  GoRoute(
    path: ChoresDashboardScreen.routePath,
    builder: (context, state) => const ChoresDashboardScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: 'list',
        builder: (context, state) => const ChoreListScreen(),
      ),
      GoRoute(
        path: 'fairness',
        builder: (context, state) => const FairnessScoreScreen(),
      ),
      GoRoute(
        path: ':choreId',
        builder: (context, state) {
          return ChoreDetailScreen(choreId: state.pathParameters['choreId']!);
        },
      ),
    ],
  ),
];
