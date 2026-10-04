import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalCurrencyFormatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String currency(num? amount, {bool showDecimals = false}) {
    if (amount == null) return 'Rs. 0';
    if (showDecimals && amount % 1 != 0) {
      return _decimalCurrencyFormatter.format(amount);
    }
    return _currencyFormatter.format(amount);
  }

  static String date(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateFormat.format(dateTime);
  }

  static String dateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime);
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _timeFormat.format(dateTime);
  }

  static bool isValidImei(String? imei) {
    if (imei == null) return false;
    final clean = imei.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 14 && clean.length <= 16;
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11 && clean.startsWith('03')) {
      return '${clean.substring(0, 4)}-${clean.substring(4)}';
    }
    return phone;
  }
}
