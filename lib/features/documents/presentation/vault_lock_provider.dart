import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:local_auth/local_auth.dart';

enum VaultLockState { locked, unlocked, authenticating }

const String _vaultPinKey = 'documents_vault_pin_hash';

final vaultLocalAuthProvider = Provider<LocalAuthentication>((Ref ref) {
  return LocalAuthentication();
});

final vaultHasPinProvider = FutureProvider<bool>((Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return (prefs.getString(_vaultPinKey) ?? '').isNotEmpty;
});

final vaultUnlockLabelProvider = FutureProvider<String>((Ref ref) async {
  final notifier = ref.read(vaultLockProvider.notifier);
  final biometricsAvailable = await notifier.hasBiometricsAvailable();
  if (biometricsAvailable) {
    final auth = ref.read(vaultLocalAuthProvider);
    final available = await auth.getAvailableBiometrics();
    if (available.contains(BiometricType.face)) {
      return 'Unlock with Face ID';
    }
    if (available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.strong) ||
        available.contains(BiometricType.weak)) {
      return 'Unlock with Fingerprint';
    }
  }
  return 'Enter PIN';
});

final vaultLockProvider = NotifierProvider<VaultLockNotifier, VaultLockState>(
  VaultLockNotifier.new,
);

class VaultLockNotifier extends Notifier<VaultLockState> {
  static const Duration inactivityTimeout = Duration(minutes: 5);

  Timer? _inactivityTimer;

  @override
  VaultLockState build() {
    ref.onDispose(() {
      _inactivityTimer?.cancel();
    });
    return VaultLockState.locked;
  }

  Future<void> requestUnlock() async {
    if (state == VaultLockState.authenticating) {
      return;
    }
    state = VaultLockState.authenticating;
    final result = await _authenticate();
    if (result) {
      state = VaultLockState.unlocked;
      _resetInactivityTimer();
      return;
    }
    state = VaultLockState.locked;
  }

  void registerActivity() {
    if (state == VaultLockState.unlocked) {
      _resetInactivityTimer();
    }
  }

  void lock() {
    _inactivityTimer?.cancel();
    state = VaultLockState.locked;
  }

  Future<bool> hasBiometricsAvailable() async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return false;
    }
    try {
      final auth = ref.read(vaultLocalAuthProvider);
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> validatePin(String pin) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final storedHash = prefs.getString(_vaultPinKey);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final candidate = sha256.convert(utf8.encode(pin)).toString();
    if (candidate == storedHash) {
      state = VaultLockState.unlocked;
      _resetInactivityTimer();
      return true;
    }
    state = VaultLockState.locked;
    return false;
  }

  Future<void> setPin(String pin) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _vaultPinKey,
      sha256.convert(utf8.encode(pin)).toString(),
    );
  }

  Future<bool> _authenticate() async {
    if (await hasBiometricsAvailable()) {
      try {
        final auth = ref.read(vaultLocalAuthProvider);
        return await auth.authenticate(
          localizedReason: 'Authenticate to access your Document Vault',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: false,
          ),
        );
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () {
      state = VaultLockState.locked;
    });
  }
}
