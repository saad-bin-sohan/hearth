import 'package:go_router/go_router.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/screens/barcode_scanner_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/grocery_dashboard_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/list_templates_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/pantry_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/shopping_list_screen.dart';

List<RouteBase> get groceryRoutes => <RouteBase>[
  GoRoute(
    path: GroceryDashboardScreen.routePath,
    builder: (context, state) => const GroceryDashboardScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: 'list',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: 'pantry',
        builder: (context, state) {
          final locationValue = state.uri.queryParameters['location'];
          final PantryLocation? initialLocation = locationValue == null
              ? null
              : PantryLocationX.fromName(locationValue);
          return PantryScreen(initialLocation: initialLocation);
        },
      ),
      GoRoute(
        path: 'templates',
        builder: (context, state) => const ListTemplatesScreen(),
      ),
      GoRoute(
        path: 'scan',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
    ],
  ),
];
