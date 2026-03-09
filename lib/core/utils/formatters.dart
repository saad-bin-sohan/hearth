import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static double centsToAmount(int amountCents) {
    return amountCents / 100;
  }

  static String currency({required num amount, required String currencyCode}) {
    return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
  }

  static String currencyFromCents({
    required int amountCents,
    required String currencyCode,
  }) {
    return currency(
      amount: centsToAmount(amountCents),
      currencyCode: currencyCode,
    );
  }

  static int? centsFromInput(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[^0-9\.\,]'), '')
        .replaceAll(',', '.');
    if (sanitized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(sanitized);
    if (parsed == null) {
      return null;
    }
    return (parsed * 100).round();
  }

  static String shortDate(DateTime value) {
    return DateFormat('MMM d, y').format(value);
  }

  static String fullDateTime(DateTime value) {
    return DateFormat('MMM d, y • h:mm a').format(value);
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb >= 100 ? 0 : 1)} GB';
  }
}
