import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/domain/household_models.dart';

class HouseholdActionState {
  const HouseholdActionState({
    this.isLoading = false,
    this.message,
    this.preview,
  });

  final bool isLoading;
  final String? message;
  final HouseholdInvitePreview? preview;

  HouseholdActionState copyWith({
    bool? isLoading,
    String? message,
    HouseholdInvitePreview? preview,
    bool clearMessage = false,
    bool clearPreview = false,
  }) {
    return HouseholdActionState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      preview: clearPreview ? null : preview ?? this.preview,
    );
  }
}

class HouseholdNotifier extends StateNotifier<HouseholdActionState> {
  HouseholdNotifier(this.ref) : super(const HouseholdActionState());

  final Ref ref;

  Future<HouseholdEntity> createHousehold({
    required String name,
    required String emoji,
    required String avatarColorKey,
    required String currencyCode,
  }) async {
    final session = ref.read(sessionControllerProvider);
    if (session.userId == null) {
      throw StateError('You must be signed in to create a household.');
    }

    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final household = await ref.read(householdRepositoryProvider).createHousehold(
            userId: session.userId!,
            name: name,
            emoji: emoji,
            avatarColorKey: avatarColorKey,
            currencyCode: currencyCode,
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .setActiveHousehold(household.id);
      state = state.copyWith(isLoading: false, clearMessage: true);
      ref.invalidate(currentHouseholdProvider);
      ref.invalidate(householdMembersProvider);
      return household;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<HouseholdInvitePreview> previewInvite(String inviteCode) async {
    state = state.copyWith(isLoading: true, clearMessage: true, clearPreview: true);
    try {
      final preview = await ref.read(householdRepositoryProvider).previewInvite(inviteCode);
      state = state.copyWith(isLoading: false, preview: preview);
      return preview;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<HouseholdEntity> joinHousehold(String inviteCode) async {
    final session = ref.read(sessionControllerProvider);
    if (session.userId == null) {
      throw StateError('You must be signed in to join a household.');
    }

    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final household = await ref.read(householdRepositoryProvider).joinHousehold(
            userId: session.userId!,
            inviteCode: inviteCode,
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .setActiveHousehold(household.id);
      state = state.copyWith(isLoading: false, clearPreview: true);
      ref.invalidate(currentHouseholdProvider);
      ref.invalidate(householdMembersProvider);
      return household;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> updateRole({
    required String memberUserId,
    required HouseholdRole role,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final household = await ref.read(currentHouseholdProvider.future);
    if (session.userId == null || household == null) {
      throw StateError('Household context is missing.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref.read(householdRepositoryProvider).updateRole(
            actingUserId: session.userId!,
            householdId: household.id,
            memberUserId: memberUserId,
            role: role,
          );
      ref.invalidate(householdMembersProvider);
      state = state.copyWith(isLoading: false);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> removeMember(String memberUserId) async {
    final session = ref.read(sessionControllerProvider);
    final household = await ref.read(currentHouseholdProvider.future);
    if (session.userId == null || household == null) {
      throw StateError('Household context is missing.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref.read(householdRepositoryProvider).removeMember(
            actingUserId: session.userId!,
            householdId: household.id,
            memberUserId: memberUserId,
          );
      ref.invalidate(householdMembersProvider);
      state = state.copyWith(isLoading: false);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final householdNotifierProvider =
    StateNotifierProvider<HouseholdNotifier, HouseholdActionState>((Ref ref) {
      return HouseholdNotifier(ref);
    });

final currentHouseholdProvider = FutureProvider<HouseholdEntity?>((Ref ref) async {
  final session = ref.watch(sessionControllerProvider);
  if (session.userId == null) {
    return null;
  }

  final repository = ref.watch(householdRepositoryProvider);
  if (session.activeHouseholdId != null) {
    final household = await repository.getHouseholdById(session.activeHouseholdId!);
    if (household != null) {
      return household;
    }
  }

  final inferred = await repository.getHouseholdForUser(session.userId!);
  if (inferred != null) {
    await ref.read(sessionControllerProvider.notifier).setActiveHousehold(inferred.id);
  }
  return inferred;
});

final householdMembersProvider = FutureProvider<List<HouseholdMember>>((Ref ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    return const <HouseholdMember>[];
  }
  return ref.watch(householdRepositoryProvider).getMembers(household.id);
});

final currentHouseholdRoleProvider = FutureProvider<HouseholdRole?>((Ref ref) async {
  final session = ref.watch(sessionControllerProvider);
  final members = await ref.watch(householdMembersProvider.future);
  if (session.userId == null) {
    return null;
  }
  for (final member in members) {
    if (member.userId == session.userId) {
      return member.role;
    }
  }
  return null;
});

final invitePreviewProvider = FutureProvider.family<HouseholdInvitePreview, String>((
  Ref ref,
  String inviteCode,
) {
  return ref.watch(householdRepositoryProvider).previewInvite(inviteCode);
});
