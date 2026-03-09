import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor_rating.dart';
import 'package:hearth/features/maintenance/domain/repositories/maintenance_task_repository.dart';
import 'package:hearth/features/maintenance/domain/repositories/vendor_repository.dart';
import 'package:hearth/features/maintenance/domain/usecases/complete_task_usecase.dart';
import 'package:hearth/features/maintenance/domain/usecases/submit_vendor_rating_usecase.dart';

void main() {
  group('CompleteTaskUseCase', () {
    test('completes and schedules the next task for recurring rules', () async {
      final cases = <({
        MaintenanceRecurrence recurrence,
        String recurrenceRule,
        DateTime dueDate,
        DateTime expectedNextDue,
      })>[
        (
          recurrence: MaintenanceRecurrence.monthly,
          recurrenceRule: 'monthly',
          dueDate: DateTime(2026, 3, 9),
          expectedNextDue: DateTime(2026, 4, 9),
        ),
        (
          recurrence: MaintenanceRecurrence.quarterly,
          recurrenceRule: 'quarterly',
          dueDate: DateTime(2026, 3, 9),
          expectedNextDue: DateTime(2026, 6, 9),
        ),
        (
          recurrence: MaintenanceRecurrence.annually,
          recurrenceRule: 'annually',
          dueDate: DateTime(2026, 3, 9),
          expectedNextDue: DateTime(2027, 3, 9),
        ),
        (
          recurrence: MaintenanceRecurrence.custom,
          recurrenceRule: 'every_90_days',
          dueDate: DateTime(2026, 3, 9),
          expectedNextDue: DateTime(2026, 6, 7),
        ),
      ];

      for (final testCase in cases) {
        final repository = _FakeMaintenanceTaskRepository();
        final task = _task(
          id: 'task-${testCase.recurrence.name}',
          dueDate: testCase.dueDate,
          recurrence: testCase.recurrence,
          recurrenceRule: testCase.recurrenceRule,
        );

        final nextDueDate = await CompleteTaskUseCase(repository).execute(
          task,
          completedByUserId: 'user-1',
          actualCost: 42,
        );

        expect(nextDueDate, testCase.expectedNextDue);
        expect(repository.completedTaskIds, <String>[task.id]);
        expect(repository.addedTasks, hasLength(1));
        expect(repository.addedTasks.single.dueDate, testCase.expectedNextDue);
        expect(
          repository.addedTasks.single.status,
          MaintenanceTaskStatus.pending,
        );
        expect(repository.addedTasks.single.completedAt, isNull);
      }
    });

    test('completes a one-off task without creating a follow-up', () async {
      final repository = _FakeMaintenanceTaskRepository();
      final task = _task(
        id: 'task-none',
        recurrence: MaintenanceRecurrence.none,
        recurrenceRule: 'none',
      );

      final nextDueDate = await CompleteTaskUseCase(repository).execute(
        task,
        completedByUserId: 'user-1',
      );

      expect(nextDueDate, isNull);
      expect(repository.completedTaskIds, <String>['task-none']);
      expect(repository.addedTasks, isEmpty);
    });
  });

  group('SubmitVendorRatingUseCase', () {
    test('inserts a new rating and returns a rounded average', () async {
      final repository = _FakeVendorRepository(
        ratings: <VendorRating>[
          _rating(vendorId: 'vendor-1', userId: 'user-2', stars: 5),
          _rating(vendorId: 'vendor-1', userId: 'user-3', stars: 4),
        ],
      );

      final average = await SubmitVendorRatingUseCase(repository).execute(
        _rating(vendorId: 'vendor-1', userId: 'user-1', stars: 4),
      );

      expect(repository.addedRatings, hasLength(1));
      expect(repository.updatedRatings, isEmpty);
      expect(repository.ratingsByVendor['vendor-1'], hasLength(3));
      expect(average, 4.3);
    });

    test('updates an existing user rating instead of inserting a duplicate', () async {
      final repository = _FakeVendorRepository(
        ratings: <VendorRating>[
          _rating(vendorId: 'vendor-1', userId: 'user-1', stars: 2),
          _rating(vendorId: 'vendor-1', userId: 'user-2', stars: 5),
        ],
      );

      final average = await SubmitVendorRatingUseCase(repository).execute(
        _rating(vendorId: 'vendor-1', userId: 'user-1', stars: 4),
      );

      expect(repository.addedRatings, isEmpty);
      expect(repository.updatedRatings, hasLength(1));
      expect(repository.ratingsByVendor['vendor-1'], hasLength(2));
      expect(
        repository.ratingsByVendor['vendor-1']!
            .firstWhere((rating) => rating.ratingByUserId == 'user-1')
            .stars,
        4,
      );
      expect(average, 4.5);
    });
  });
}

class _FakeMaintenanceTaskRepository implements MaintenanceTaskRepository {
  final List<String> completedTaskIds = <String>[];
  final List<MaintenanceTask> addedTasks = <MaintenanceTask>[];

  @override
  Future<void> addTask(MaintenanceTask task) async {
    addedTasks.add(task);
  }

  @override
  Future<void> completeTask(
    String taskId, {
    required String completedByUserId,
    double? actualCost,
    String? vendorId,
    String? notes,
    String? completionPhotoPath,
  }) async {
    completedTaskIds.add(taskId);
  }

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForAsset(String assetId) async {
    return const <MaintenanceTask>[];
  }

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId) async {
    return const <MaintenanceTask>[];
  }

  @override
  Future<MaintenanceTask?> getTaskById(String id) async => null;

  @override
  Future<List<MaintenanceTask>> getTasksWithDueDateBetween(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    return const <MaintenanceTask>[];
  }

  @override
  Future<List<MaintenanceTask>> getPendingTasksPastDue(String householdId) async {
    return const <MaintenanceTask>[];
  }

  @override
  Future<void> markTaskStatus(String taskId, MaintenanceTaskStatus status) async {}

  @override
  Future<void> updateTask(MaintenanceTask task) async {}

  @override
  Stream<List<MaintenanceTask>> watchOverdueTasks(String householdId) {
    return Stream<List<MaintenanceTask>>.value(const <MaintenanceTask>[]);
  }

  @override
  Stream<List<MaintenanceTask>> watchTasksForAsset(String assetId) {
    return Stream<List<MaintenanceTask>>.value(const <MaintenanceTask>[]);
  }

  @override
  Stream<List<MaintenanceTask>> watchTasksForHousehold(String householdId) {
    return Stream<List<MaintenanceTask>>.value(const <MaintenanceTask>[]);
  }

  @override
  Stream<List<MaintenanceTask>> watchUpcomingTasks(
    String householdId, {
    int daysAhead = 30,
  }) {
    return Stream<List<MaintenanceTask>>.value(const <MaintenanceTask>[]);
  }
}

class _FakeVendorRepository implements VendorRepository {
  _FakeVendorRepository({
    List<VendorRating> ratings = const <VendorRating>[],
  }) {
    for (final rating in ratings) {
      ratingsByVendor.putIfAbsent(rating.vendorId, () => <VendorRating>[]).add(rating);
    }
  }

  final Map<String, List<VendorRating>> ratingsByVendor =
      <String, List<VendorRating>>{};
  final List<VendorRating> addedRatings = <VendorRating>[];
  final List<VendorRating> updatedRatings = <VendorRating>[];

  @override
  Future<void> addRating(VendorRating rating) async {
    addedRatings.add(rating);
    ratingsByVendor.putIfAbsent(rating.vendorId, () => <VendorRating>[]).add(rating);
  }

  @override
  Future<void> addVendor(Vendor vendor) async {}

  @override
  Future<void> deleteVendor(String id) async {}

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId) async {
    return const <MaintenanceTask>[];
  }

  @override
  Future<Vendor?> getVendorById(String id) async => null;

  @override
  Future<VendorRating?> getRatingByVendorAndUser(String vendorId, String userId) async {
    return ratingsByVendor[vendorId]?.cast<VendorRating?>().firstWhere(
          (rating) => rating?.ratingByUserId == userId,
          orElse: () => null,
        );
  }

  @override
  Future<double> updateAverageRating(String vendorId) async {
    final ratings = ratingsByVendor[vendorId] ?? const <VendorRating>[];
    if (ratings.isEmpty) {
      return 0;
    }
    final total = ratings.fold<int>(0, (sum, rating) => sum + rating.stars);
    return double.parse((total / ratings.length).toStringAsFixed(1));
  }

  @override
  Future<void> updateRating(VendorRating rating) async {
    updatedRatings.add(rating);
    final ratings = ratingsByVendor[rating.vendorId] ?? <VendorRating>[];
    final index = ratings.indexWhere(
      (existing) => existing.ratingByUserId == rating.ratingByUserId,
    );
    if (index >= 0) {
      ratings[index] = rating;
    } else {
      ratings.add(rating);
    }
    ratingsByVendor[rating.vendorId] = ratings;
  }

  @override
  Future<void> updateVendor(Vendor vendor) async {}

  @override
  Stream<List<VendorRating>> watchRatingsForVendor(String vendorId) {
    return Stream<List<VendorRating>>.value(
      ratingsByVendor[vendorId] ?? const <VendorRating>[],
    );
  }

  @override
  Stream<List<Vendor>> watchVendorsForHousehold(String householdId) {
    return Stream<List<Vendor>>.value(const <Vendor>[]);
  }
}

VendorRating _rating({
  required String vendorId,
  required String userId,
  required int stars,
}) {
  return VendorRating(
    id: '$vendorId-$userId',
    vendorId: vendorId,
    ratingByUserId: userId,
    stars: stars,
    ratedAt: DateTime(2026, 3, 9),
  );
}

MaintenanceTask _task({
  required String id,
  MaintenanceRecurrence recurrence = MaintenanceRecurrence.monthly,
  String recurrenceRule = 'monthly',
  DateTime? dueDate,
}) {
  return MaintenanceTask(
    id: id,
    householdId: 'household-1',
    assetId: 'asset-1',
    title: 'Replace filter',
    dueDate: dueDate ?? DateTime(2026, 3, 9),
    recurrence: recurrence,
    recurrenceRule: recurrenceRule,
    status: MaintenanceTaskStatus.pending,
    createdAt: DateTime(2026, 3, 9),
    createdByUserId: 'user-1',
  );
}
