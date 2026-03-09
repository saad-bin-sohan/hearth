import 'package:go_router/go_router.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/home/presentation/settings_screen.dart';

List<RouteBase> get homeRoutes => <RouteBase>[
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        builder: (context, state) => const SettingsScreen(),
      ),
    ];
