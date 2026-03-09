import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/features/documents/domain/document_models.dart';

extension DocumentExpiryUrgencyBadgeX on DocumentExpiryUrgency {
  ExpiryBadgeUrgency get badgeUrgency => switch (this) {
    DocumentExpiryUrgency.none => ExpiryBadgeUrgency.none,
    DocumentExpiryUrgency.safe => ExpiryBadgeUrgency.safe,
    DocumentExpiryUrgency.warning => ExpiryBadgeUrgency.warning,
    DocumentExpiryUrgency.critical => ExpiryBadgeUrgency.critical,
    DocumentExpiryUrgency.expired => ExpiryBadgeUrgency.expired,
  };
}
