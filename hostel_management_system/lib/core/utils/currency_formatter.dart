import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num? amount, {String symbol = 'Rs. '}) {
    if (amount == null) return '${symbol}0';
    final formatter = NumberFormat('#,##0.##');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatPlain(num? amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(amount);
  }
}
