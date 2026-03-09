import 'package:go_router/go_router.dart';
import 'package:hearth/features/maintenance/presentation/screens/asset_detail_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/asset_list_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/maintenance_dashboard_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/task_detail_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/task_list_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/vendor_detail_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/vendor_list_screen.dart';

List<RouteBase> get maintenanceRoutes => <RouteBase>[
  GoRoute(
    path: MaintenanceDashboardScreen.routePath,
    builder: (context, state) => const MaintenanceDashboardScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: 'assets',
        builder: (context, state) => const AssetListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':assetId',
            builder: (context, state) => AssetDetailScreen(
              assetId: state.pathParameters['assetId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'tasks',
        builder: (context, state) => const TaskListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':taskId',
            builder: (context, state) => TaskDetailScreen(
              taskId: state.pathParameters['taskId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'vendors',
        builder: (context, state) => const VendorListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':vendorId',
            builder: (context, state) => VendorDetailScreen(
              vendorId: state.pathParameters['vendorId']!,
            ),
          ),
        ],
      ),
    ],
  ),
];
