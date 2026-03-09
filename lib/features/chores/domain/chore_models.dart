import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';

enum ChoreAreaTag { kitchen, bathroom, living, bedroom, garden, general }

extension ChoreAreaTagX on ChoreAreaTag {
  String get label => switch (this) {
    ChoreAreaTag.kitchen => 'Kitchen',
    ChoreAreaTag.bathroom => 'Bathroom',
    ChoreAreaTag.living => 'Living',
    ChoreAreaTag.bedroom => 'Bedroom',
    ChoreAreaTag.garden => 'Garden',
    ChoreAreaTag.general => 'General',
  };

  static ChoreAreaTag fromName(String value) {
    return ChoreAreaTag.values.firstWhere(
      (ChoreAreaTag areaTag) => areaTag.name == value,
    );
  }
}

enum ChoreFrequency { daily, weekly, biweekly, monthly, custom }

extension ChoreFrequencyX on ChoreFrequency {
  String get label => switch (this) {
    ChoreFrequency.daily => 'Daily',
    ChoreFrequency.weekly => 'Weekly',
    ChoreFrequency.biweekly => 'Biweekly',
    ChoreFrequency.monthly => 'Monthly',
    ChoreFrequency.custom => 'Custom',
  };

  static ChoreFrequency fromName(String value) {
    return ChoreFrequency.values.firstWhere(
      (ChoreFrequency frequency) => frequency.name == value,
    );
  }
}

enum ChoreAssignmentType { fixed, rotation }

extension ChoreAssignmentTypeX on ChoreAssignmentType {
  String get label => switch (this) {
    ChoreAssignmentType.fixed => 'Fixed Member',
    ChoreAssignmentType.rotation => 'Rotation',
  };

  static ChoreAssignmentType fromName(String value) {
    return ChoreAssignmentType.values.firstWhere(
      (ChoreAssignmentType type) => type.name == value,
    );
  }
}

class ChoreEntity extends Equatable {
  const ChoreEntity({
    required this.id,
    required this.householdId,
    required this.title,
    this.description,
    required this.areaTag,
    required this.estimatedMinutes,
    required this.frequency,
    this.recurrenceRule,
    required this.assignmentType,
    required this.assignedToUserIds,
    required this.currentAssigneeIndex,
    required this.nextDueAt,
    required this.isActive,
    required this.streakCount,
    required this.createdAt,
    required this.createdByUserId,
  });

  final String id;
  final String householdId;
  final String title;
  final String? description;
  final ChoreAreaTag areaTag;
  final int estimatedMinutes;
  final ChoreFrequency frequency;
  final String? recurrenceRule;
  final ChoreAssignmentType assignmentType;
  final List<String> assignedToUserIds;
  final int currentAssigneeIndex;
  final DateTime nextDueAt;
  final bool isActive;
  final int streakCount;
  final DateTime createdAt;
  final String createdByUserId;

  String? get currentAssigneeUserId {
    if (assignedToUserIds.isEmpty) {
      return null;
    }
    final index = currentAssigneeIndex.clamp(0, assignedToUserIds.length - 1);
    return assignedToUserIds[index];
  }

  bool get isRotation => assignmentType == ChoreAssignmentType.rotation;

  ChoreEntity copyWith({
    String? id,
    String? householdId,
    String? title,
    String? description,
    bool clearDescription = false,
    ChoreAreaTag? areaTag,
    int? estimatedMinutes,
    ChoreFrequency? frequency,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
    ChoreAssignmentType? assignmentType,
    List<String>? assignedToUserIds,
    int? currentAssigneeIndex,
    DateTime? nextDueAt,
    bool? isActive,
    int? streakCount,
    DateTime? createdAt,
    String? createdByUserId,
  }) {
    return ChoreEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      areaTag: areaTag ?? this.areaTag,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      frequency: frequency ?? this.frequency,
      recurrenceRule: clearRecurrenceRule
          ? null
          : recurrenceRule ?? this.recurrenceRule,
      assignmentType: assignmentType ?? this.assignmentType,
      assignedToUserIds: assignedToUserIds ?? this.assignedToUserIds,
      currentAssigneeIndex: currentAssigneeIndex ?? this.currentAssigneeIndex,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      isActive: isActive ?? this.isActive,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    title,
    description,
    areaTag,
    estimatedMinutes,
    frequency,
    recurrenceRule,
    assignmentType,
    assignedToUserIds,
    currentAssigneeIndex,
    nextDueAt,
    isActive,
    streakCount,
    createdAt,
    createdByUserId,
  ];
}

class ChoreDraft extends Equatable {
  const ChoreDraft({
    this.id,
    required this.householdId,
    required this.title,
    this.description,
    required this.areaTag,
    required this.estimatedMinutes,
    required this.frequency,
    this.recurrenceRule,
    required this.assignmentType,
    required this.assignedToUserIds,
    this.currentAssigneeIndex = 0,
    required this.nextDueAt,
    this.isActive = true,
  });

  final String? id;
  final String householdId;
  final String title;
  final String? description;
  final ChoreAreaTag areaTag;
  final int estimatedMinutes;
  final ChoreFrequency frequency;
  final String? recurrenceRule;
  final ChoreAssignmentType assignmentType;
  final List<String> assignedToUserIds;
  final int currentAssigneeIndex;
  final DateTime nextDueAt;
  final bool isActive;

  ChoreDraft copyWith({
    String? id,
    bool clearId = false,
    String? householdId,
    String? title,
    String? description,
    bool clearDescription = false,
    ChoreAreaTag? areaTag,
    int? estimatedMinutes,
    ChoreFrequency? frequency,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
    ChoreAssignmentType? assignmentType,
    List<String>? assignedToUserIds,
    int? currentAssigneeIndex,
    DateTime? nextDueAt,
    bool? isActive,
  }) {
    return ChoreDraft(
      id: clearId ? null : id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      areaTag: areaTag ?? this.areaTag,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      frequency: frequency ?? this.frequency,
      recurrenceRule: clearRecurrenceRule
          ? null
          : recurrenceRule ?? this.recurrenceRule,
      assignmentType: assignmentType ?? this.assignmentType,
      assignedToUserIds: assignedToUserIds ?? this.assignedToUserIds,
      currentAssigneeIndex: currentAssigneeIndex ?? this.currentAssigneeIndex,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    title,
    description,
    areaTag,
    estimatedMinutes,
    frequency,
    recurrenceRule,
    assignmentType,
    assignedToUserIds,
    currentAssigneeIndex,
    nextDueAt,
    isActive,
  ];
}

class ChoreCompletionEntity extends Equatable {
  const ChoreCompletionEntity({
    required this.id,
    required this.choreId,
    required this.completedByUserId,
    required this.completedAt,
    this.photoLocalPath,
    this.notes,
    required this.wasOnTime,
  });

  final String id;
  final String choreId;
  final String completedByUserId;
  final DateTime completedAt;
  final String? photoLocalPath;
  final String? notes;
  final bool wasOnTime;

  @override
  List<Object?> get props => <Object?>[
    id,
    choreId,
    completedByUserId,
    completedAt,
    photoLocalPath,
    notes,
    wasOnTime,
  ];
}

class ChoreDeferralEntity extends Equatable {
  const ChoreDeferralEntity({
    required this.id,
    required this.choreId,
    required this.deferredByUserId,
    required this.deferredAt,
    this.reason,
    required this.newDueAt,
  });

  final String id;
  final String choreId;
  final String deferredByUserId;
  final DateTime deferredAt;
  final String? reason;
  final DateTime newDueAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    choreId,
    deferredByUserId,
    deferredAt,
    reason,
    newDueAt,
  ];
}

class ChoreCompletionOutcome extends Equatable {
  const ChoreCompletionOutcome({
    required this.chore,
    required this.completion,
    required this.wasOnTime,
    required this.milestoneReached,
  });

  final ChoreEntity chore;
  final ChoreCompletionEntity completion;
  final bool wasOnTime;
  final bool milestoneReached;

  @override
  List<Object?> get props => <Object?>[
    chore,
    completion,
    wasOnTime,
    milestoneReached,
  ];
}

class ChoreHomeSummary extends Equatable {
  const ChoreHomeSummary({
    required this.dueTodayCount,
    required this.overdueCount,
  });

  final int dueTodayCount;
  final int overdueCount;

  @override
  List<Object?> get props => <Object?>[dueTodayCount, overdueCount];
}

class FairnessScoreEntry extends Equatable {
  const FairnessScoreEntry({
    required this.userId,
    required this.displayName,
    required this.minutesCompleted,
    required this.score,
  });

  final String userId;
  final String displayName;
  final int minutesCompleted;
  final double score;

  String get formattedScore => score.toStringAsFixed(score % 1 == 0 ? 0 : 1);

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    minutesCompleted,
    score,
  ];
}

class FairnessScoreSnapshot extends Equatable {
  const FairnessScoreSnapshot({
    required this.scores,
    required this.memberMinutes,
  });

  final Map<String, double> scores;
  final Map<String, int> memberMinutes;

  int get totalMinutes => memberMinutes.values.fold<int>(
    0,
    (int total, int value) => total + value,
  );

  @override
  List<Object?> get props => <Object?>[scores, memberMinutes];
}

String choreUserIdsToJson(List<String> userIds) => jsonEncode(userIds);

List<String> choreUserIdsFromJson(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! List<dynamic>) {
    return const <String>[];
  }
  return decoded.map((dynamic value) => value as String).toList();
}

double cappedFairnessScore({
  required int contributedMinutes,
  required double fairShareMinutes,
}) {
  if (fairShareMinutes <= 0) {
    return 100;
  }
  return math.min(100, (contributedMinutes / fairShareMinutes) * 100);
}
