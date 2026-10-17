import 'package:intl/intl.dart';

class Formatters {
  static String currency(num amount, {String symbol = 'Rs. '}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String compactCurrency(num amount, {String symbol = 'Rs. '}) {
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return currency(amount, symbol: symbol);
  }

  static String date(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String time(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('hh:mm a').format(date);
  }

  static String dateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
