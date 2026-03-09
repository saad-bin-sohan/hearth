import 'package:hearth/features/household/domain/household_models.dart';

abstract class HouseholdRepository {
  Future<HouseholdEntity> createHousehold({
    required String userId,
    required String name,
    required String emoji,
    required String avatarColorKey,
    required String currencyCode,
  });

  Future<HouseholdInvitePreview> previewInvite(String inviteCode);

  Future<HouseholdEntity> joinHousehold({
    required String userId,
    required String inviteCode,
  });

  Future<HouseholdEntity?> getHouseholdForUser(String userId);

  Future<HouseholdEntity?> getHouseholdById(String householdId);

  Future<List<HouseholdMember>> getMembers(String householdId);

  Future<void> updateRole({
    required String actingUserId,
    required String householdId,
    required String memberUserId,
    required HouseholdRole role,
  });

  Future<void> removeMember({
    required String actingUserId,
    required String householdId,
    required String memberUserId,
  });

  Future<String> buildInviteShareText(String householdId);
}
