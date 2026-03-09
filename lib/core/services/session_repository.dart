abstract class SessionRepository {
  Future<SessionSnapshot> load();
  Future<void> saveSession({required String authToken, required String userId});
  Future<void> clearSession();
  Future<void> setOnboardingComplete(bool completed);
  Future<void> setActiveHouseholdId(String? householdId);
}

class SessionSnapshot {
  const SessionSnapshot({
    required this.isReady,
    required this.onboardingComplete,
    this.authToken,
    this.userId,
    this.activeHouseholdId,
  });

  final bool isReady;
  final bool onboardingComplete;
  final String? authToken;
  final String? userId;
  final String? activeHouseholdId;

  bool get hasSession => authToken != null && userId != null;

  SessionSnapshot copyWith({
    bool? isReady,
    bool? onboardingComplete,
    String? authToken,
    String? userId,
    String? activeHouseholdId,
    bool clearAuthToken = false,
    bool clearUserId = false,
    bool clearHousehold = false,
  }) {
    return SessionSnapshot(
      isReady: isReady ?? this.isReady,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      authToken: clearAuthToken ? null : authToken ?? this.authToken,
      userId: clearUserId ? null : userId ?? this.userId,
      activeHouseholdId: clearHousehold
          ? null
          : activeHouseholdId ?? this.activeHouseholdId,
    );
  }
}
