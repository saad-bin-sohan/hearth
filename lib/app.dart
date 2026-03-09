import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:hearth/core/router/app_router.dart';
import 'package:hearth/core/theme/app_theme.dart';
import 'package:hearth/features/documents/presentation/vault_lock_provider.dart';

class HearthApp extends ConsumerStatefulWidget {
  const HearthApp({super.key});

  @override
  ConsumerState<HearthApp> createState() => _HearthAppState();
}

class _HearthAppState extends ConsumerState<HearthApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      ref.read(vaultLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hearth',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
