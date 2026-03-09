import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_rating.freezed.dart';

@freezed
class VendorRating with _$VendorRating {
  const factory VendorRating({
    required String id,
    required String vendorId,
    required String ratingByUserId,
    required int stars,
    String? notes,
    required DateTime ratedAt,
  }) = _VendorRating;
}
