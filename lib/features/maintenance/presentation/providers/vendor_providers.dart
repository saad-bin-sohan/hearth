import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/data/datasources/vendor_local_datasource.dart';
import 'package:hearth/features/maintenance/data/repositories/vendor_repository_impl.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor_rating.dart';
import 'package:hearth/features/maintenance/domain/repositories/vendor_repository.dart';
import 'package:hearth/features/maintenance/domain/usecases/submit_vendor_rating_usecase.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:uuid/uuid.dart';

final vendorLocalDataSourceProvider = Provider<VendorLocalDataSource>((Ref ref) {
  return VendorLocalDataSource(ref.watch(db.appDatabaseProvider));
});

final vendorRepositoryProvider = Provider<VendorRepository>((Ref ref) {
  final database = ref.watch(db.appDatabaseProvider);
  return VendorRepositoryImpl(
    vendorDataSource: ref.watch(vendorLocalDataSourceProvider),
    taskDataSource: MaintenanceTaskDataSource(database),
  );
});

final vendorsProvider = StreamProvider.family<List<Vendor>, String>((
  Ref ref,
  String householdId,
) {
  return ref.watch(vendorRepositoryProvider).watchVendorsForHousehold(householdId);
});

final vendorDetailProvider = FutureProvider.family<Vendor?, String>((
  Ref ref,
  String vendorId,
) {
  return ref.watch(vendorRepositoryProvider).getVendorById(vendorId);
});

final vendorRatingsProvider = StreamProvider.family<List<VendorRating>, String>((
  Ref ref,
  String vendorId,
) {
  return ref.watch(vendorRepositoryProvider).watchRatingsForVendor(vendorId);
});

final vendorCurrentUserRatingProvider =
    FutureProvider.family<VendorRating?, String>((Ref ref, String vendorId) async {
  final currentUserId = ref.watch(maintenanceCurrentUserIdProvider);
  if (currentUserId == null) {
    return null;
  }
  return ref
      .watch(vendorRepositoryProvider)
      .getRatingByVendorAndUser(vendorId, currentUserId);
});

final completedVendorTasksProvider =
    FutureProvider.family<List<MaintenanceTask>, String>((
      Ref ref,
      String vendorId,
    ) {
      return ref
          .watch(vendorRepositoryProvider)
          .getCompletedTasksForVendor(vendorId);
    });

class VendorNotifier extends AsyncNotifier<void> {
  final Uuid _uuid = const Uuid();

  @override
  FutureOr<void> build() {}

  Future<void> addVendor(Vendor vendor) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorRepositoryProvider).addVendor(vendor);
      _invalidate(vendor);
    });
  }

  Future<void> updateVendor(Vendor vendor) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorRepositoryProvider).updateVendor(vendor);
      _invalidate(vendor);
    });
  }

  Future<void> deleteVendor(String vendorId) async {
    final vendor = await ref.read(vendorDetailProvider(vendorId).future);
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorRepositoryProvider).deleteVendor(vendorId);
      ref.invalidate(vendorDetailProvider(vendorId));
      if (vendor != null) {
        ref.invalidate(vendorsProvider(vendor.householdId));
      }
    });
  }

  Future<double> submitRating({
    required String vendorId,
    required int stars,
    String? notes,
  }) async {
    state = const AsyncLoading<void>();
    final ratingByUserId = ref.read(maintenanceCurrentUserIdProvider);
    if (ratingByUserId == null) {
      throw StateError('You must be signed in to rate a vendor.');
    }
    final rating = VendorRating(
      id: _uuid.v4(),
      vendorId: vendorId,
      ratingByUserId: ratingByUserId,
      stars: stars,
      notes: notes,
      ratedAt: DateTime.now(),
    );
    double average = 0;
    state = await AsyncValue.guard(() async {
      average = await SubmitVendorRatingUseCase(
        ref.read(vendorRepositoryProvider),
      ).execute(rating);
      final vendor = await ref.read(vendorDetailProvider(vendorId).future);
      ref.invalidate(vendorRatingsProvider(vendorId));
      ref.invalidate(vendorDetailProvider(vendorId));
      if (vendor != null) {
        ref.invalidate(vendorsProvider(vendor.householdId));
      }
    });
    return average;
  }

  void _invalidate(Vendor vendor) {
    ref.invalidate(vendorDetailProvider(vendor.id));
    ref.invalidate(vendorsProvider(vendor.householdId));
  }
}

final vendorNotifierProvider = AsyncNotifierProvider<VendorNotifier, void>(
  VendorNotifier.new,
);
