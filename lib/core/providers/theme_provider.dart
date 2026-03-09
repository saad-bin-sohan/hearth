import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  Ref ref,
) async {
  return SharedPreferences.getInstance();
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this.ref) : super(ThemeMode.system) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_themeModeKey);
    state = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>((
  Ref ref,
) {
  return ThemeController(ref);
});
