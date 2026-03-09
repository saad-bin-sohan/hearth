import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';

final maintenanceHouseholdIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).activeHouseholdId;
});

final maintenanceCurrentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).userId;
});

final maintenanceMembersProvider = FutureProvider<List<HouseholdMember>>((
  Ref ref,
) async {
  return ref.watch(householdMembersProvider.future);
});

final maintenanceMemberLookupProvider =
    FutureProvider<Map<String, HouseholdMember>>((Ref ref) async {
  final members = await ref.watch(maintenanceMembersProvider.future);
  return <String, HouseholdMember>{
    for (final member in members) member.userId: member,
  };
});

final maintenanceHouseholdCurrencyProvider = FutureProvider<String>((
  Ref ref,
) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  return household?.currencyCode ?? 'USD';
});

final maintenanceCurrentRoleProvider = FutureProvider<HouseholdRole?>((
  Ref ref,
) async {
  return ref.watch(currentHouseholdRoleProvider.future);
});
