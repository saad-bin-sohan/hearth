import 'package:go_router/go_router.dart';
import 'package:hearth/features/finance/presentation/expense_detail_screen.dart';
import 'package:hearth/features/finance/presentation/finance_module.dart';

List<RouteBase> get financeRoutes => <RouteBase>[
      GoRoute(
        path: FinanceModule.routePath,
        builder: (context, state) => const FinanceModule(),
        routes: <RouteBase>[
          GoRoute(
            path: 'expense/:expenseId',
            builder: (context, state) {
              return ExpenseDetailScreen(
                expenseId: state.pathParameters['expenseId']!,
              );
            },
          ),
        ],
      ),
    ];
