import 'package:equatable/equatable.dart';

enum HouseholdRole { admin, member, observer }

extension HouseholdRoleX on HouseholdRole {
  String get label => switch (this) {
    HouseholdRole.admin => 'Admin',
    HouseholdRole.member => 'Member',
    HouseholdRole.observer => 'Observer',
  };
}

class HouseholdEntity extends Equatable {
  const HouseholdEntity({
    required this.id,
    required this.name,
    required this.emoji,
    required this.avatarColorKey,
    required this.currencyCode,
    required this.inviteCode,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final String avatarColorKey;
  final String currencyCode;
  final String inviteCode;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    emoji,
    avatarColorKey,
    currencyCode,
    inviteCode,
    createdByUserId,
    createdAt,
    updatedAt,
  ];
}

class HouseholdMember extends Equatable {
  const HouseholdMember({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String membershipId;
  final String userId;
  final String displayName;
  final String email;
  final HouseholdRole role;
  final DateTime joinedAt;

  @override
  List<Object?> get props => <Object?>[
    membershipId,
    userId,
    displayName,
    email,
    role,
    joinedAt,
  ];
}

class HouseholdInvitePreview extends Equatable {
  const HouseholdInvitePreview({
    required this.household,
    required this.memberCount,
  });

  final HouseholdEntity household;
  final int memberCount;

  @override
  List<Object?> get props => <Object?>[household, memberCount];
}
