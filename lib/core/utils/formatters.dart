import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static String currency({
    required num amount,
    required String currencyCode,
  }) {
    return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
  }

  static String shortDate(DateTime value) {
    return DateFormat('MMM d, y').format(value);
  }

  static String fullDateTime(DateTime value) {
    return DateFormat('MMM d, y • h:mm a').format(value);
  }
}
