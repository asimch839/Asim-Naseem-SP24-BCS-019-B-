import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd-MMM-yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MMM-yyyy hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _isoMonthFormat = DateFormat('yyyy-MM');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYearFormat.format(date);
  }

  static String formatMonthYearString(String isoMonth) {
    try {
      final parts = isoMonth.split('-');
      if (parts.length == 2) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return _monthYearFormat.format(date);
      }
    } catch (_) {}
    return isoMonth;
  }

  static String toIsoMonth(DateTime date) {
    return _isoMonthFormat.format(date);
  }

  static String toIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  static DateTime parseIsoDate(String dateStr) {
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
