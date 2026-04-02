import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime dt) {
  return DateFormat('EEE, MMM d, yyyy hh:mm a').format(dt);
}

Color priorityColor(int percent) {
  if (percent >= 80) return Colors.green;
  if (percent >= 50) return Colors.orange;
  return Colors.red;
}
