import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/theme_provider.dart';
import 'package:hearth/core/services/session_repository.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _authTokenKey = 'auth_token';
const String _authUserIdKey = 'auth_user_id';
const String _activeHouseholdIdKey = 'active_household_id';
const String _onboardingCompleteKey = 'onboarding_complete';

class SharedPreferencesSessionRepository implements SessionRepository {
  SharedPreferencesSessionRepository(this._preferencesFuture);

  final Future<SharedPreferences> _preferencesFuture;

  @override
  Future<void> clearSession() async {
    final prefs = await _preferencesFuture;
    await prefs.remove(_authTokenKey);
    await prefs.remove(_authUserIdKey);
    await prefs.remove(_activeHouseholdIdKey);
  }

  @override
  Future<SessionSnapshot> load() async {
    final prefs = await _preferencesFuture;
    return SessionSnapshot(
      isReady: true,
      onboardingComplete: prefs.getBool(_onboardingCompleteKey) ?? false,
      authToken: prefs.getString(_authTokenKey),
      userId: prefs.getString(_authUserIdKey),
      activeHouseholdId: prefs.getString(_activeHouseholdIdKey),
    );
  }

  @override
  Future<void> saveSession({
    required String authToken,
    required String userId,
  }) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_authTokenKey, authToken);
    await prefs.setString(_authUserIdKey, userId);
  }

  @override
  Future<void> setActiveHouseholdId(String? householdId) async {
    final prefs = await _preferencesFuture;
    if (householdId == null) {
      await prefs.remove(_activeHouseholdIdKey);
      return;
    }
    await prefs.setString(_activeHouseholdIdKey, householdId);
  }

  @override
  Future<void> setOnboardingComplete(bool completed) async {
    final prefs = await _preferencesFuture;
    await prefs.setBool(_onboardingCompleteKey, completed);
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((Ref ref) {
  return SharedPreferencesSessionRepository(
    ref.read(sharedPreferencesProvider.future),
  );
});

class SessionController extends StateNotifier<SessionSnapshot> {
  SessionController(this.ref)
    : super(const SessionSnapshot(isReady: false, onboardingComplete: false)) {
    bootstrap();
  }

  final Ref ref;

  Future<void> bootstrap() async {
    state = await ref.read(sessionRepositoryProvider).load();
  }

  Future<void> markOnboardingComplete() async {
    await ref.read(sessionRepositoryProvider).setOnboardingComplete(true);
    state = state.copyWith(onboardingComplete: true);
  }

  Future<void> saveSession({
    required String authToken,
    required String userId,
  }) async {
    await ref
        .read(sessionRepositoryProvider)
        .saveSession(authToken: authToken, userId: userId);
    state = state.copyWith(authToken: authToken, userId: userId);
  }

  Future<void> clearSession() async {
    await ref.read(sessionRepositoryProvider).clearSession();
    state = state.copyWith(
      clearAuthToken: true,
      clearUserId: true,
      clearHousehold: true,
    );
  }

  Future<void> setActiveHousehold(String? householdId) async {
    await ref.read(sessionRepositoryProvider).setActiveHouseholdId(householdId);
    state = state.copyWith(
      activeHouseholdId: householdId,
      clearHousehold: householdId == null,
    );
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionSnapshot>((Ref ref) {
      return SessionController(ref);
    });

final currentUserProvider = FutureProvider<AppUser?>((Ref ref) async {
  final session = ref.watch(sessionControllerProvider);
  if (session.userId == null) {
    return null;
  }
  return ref.watch(authRepositoryProvider).getUserById(session.userId!);
});
