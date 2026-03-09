import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/features/documents/presentation/screens/camera_scan_screen.dart';
import 'package:hearth/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:hearth/features/documents/presentation/screens/expiry_timeline_screen.dart';
import 'package:hearth/features/documents/presentation/screens/folder_screen.dart';
import 'package:hearth/features/documents/presentation/screens/vault_dashboard_screen.dart';
import 'package:hearth/features/documents/presentation/sheets/add_document_sheet.dart';

List<RouteBase> get documentsRoutes => <RouteBase>[
  GoRoute(
    path: VaultDashboardScreen.routePath,
    builder: (BuildContext context, GoRouterState state) {
      return const VaultDashboardScreen();
    },
    routes: <RouteBase>[
      GoRoute(
        path: 'folder/:folderPath',
        builder: (BuildContext context, GoRouterState state) {
          return FolderScreen(
            folderPath: Uri.decodeComponent(state.pathParameters['folderPath']!),
          );
        },
      ),
      GoRoute(
        path: 'expiry',
        builder: (BuildContext context, GoRouterState state) {
          return const ExpiryTimelineScreen();
        },
      ),
      GoRoute(
        path: 'scan',
        builder: (BuildContext context, GoRouterState state) {
          return const CameraScanScreen();
        },
      ),
      GoRoute(
        path: ':documentId',
        builder: (BuildContext context, GoRouterState state) {
          return DocumentDetailScreen(
            documentId: state.pathParameters['documentId']!,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            pageBuilder: (BuildContext context, GoRouterState state) {
              final documentId = state.pathParameters['documentId']!;
              return CustomTransitionPage<void>(
                key: state.pageKey,
                barrierDismissible: true,
                barrierColor: Colors.transparent,
                opaque: false,
                child: _EditDocumentSheetRoute(documentId: documentId),
                transitionsBuilder: (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
        ],
      ),
    ],
  ),
];

class _EditDocumentSheetRoute extends StatefulWidget {
  const _EditDocumentSheetRoute({required this.documentId});

  final String documentId;

  @override
  State<_EditDocumentSheetRoute> createState() => _EditDocumentSheetRouteState();
}

class _EditDocumentSheetRouteState extends State<_EditDocumentSheetRoute> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) {
      return;
    }
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final NavigatorState navigator = Navigator.of(context);
      unawaited(
        showAddDocumentSheet(
          context,
          documentId: widget.documentId,
        ).then((_) {
          if (navigator.mounted) {
            navigator.maybePop();
          }
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
