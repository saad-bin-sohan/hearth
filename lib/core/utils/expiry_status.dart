enum DateExpiryUrgency { none, safe, warning, critical, expired }

class ExpiryStatus {
  const ExpiryStatus._();

  static DateExpiryUrgency urgencyForDate(
    DateTime? value, {
    DateTime? now,
    int criticalDays = 14,
    int warningDays = 60,
  }) {
    final days = daysUntil(value, now: now);
    if (days == null) {
      return DateExpiryUrgency.none;
    }
    if (days < 0) {
      return DateExpiryUrgency.expired;
    }
    if (days < criticalDays) {
      return DateExpiryUrgency.critical;
    }
    if (days <= warningDays) {
      return DateExpiryUrgency.warning;
    }
    return DateExpiryUrgency.safe;
  }

  static int? daysUntil(DateTime? value, {DateTime? now}) {
    if (value == null) {
      return null;
    }
    final current = now ?? DateTime.now();
    final startOfToday = DateTime(current.year, current.month, current.day);
    final target = DateTime(value.year, value.month, value.day);
    return target.difference(startOfToday).inDays;
  }
}
