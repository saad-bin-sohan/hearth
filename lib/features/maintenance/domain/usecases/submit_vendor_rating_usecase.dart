import 'package:hearth/features/maintenance/domain/entities/vendor_rating.dart';
import 'package:hearth/features/maintenance/domain/repositories/vendor_repository.dart';

class SubmitVendorRatingUseCase {
  const SubmitVendorRatingUseCase(this._repository);

  final VendorRepository _repository;

  Future<double> execute(VendorRating rating) async {
    final existing = await _repository.getRatingByVendorAndUser(
      rating.vendorId,
      rating.ratingByUserId,
    );
    if (existing == null) {
      await _repository.addRating(rating);
    } else {
      await _repository.updateRating(
        existing.copyWith(
          stars: rating.stars,
          notes: rating.notes,
          ratedAt: rating.ratedAt,
        ),
      );
    }
    final average = await _repository.updateAverageRating(rating.vendorId);
    return (average * 10).round() / 10;
  }
}
