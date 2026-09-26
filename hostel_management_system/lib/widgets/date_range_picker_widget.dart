import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../core/utils/date_formatter.dart';

enum DateFilterOption { today, thisWeek, thisMonth, lastMonth, thisYear, custom }

class DateRangePickerWidget extends StatefulWidget {
  final DateTime initialFrom;
  final DateTime initialTo;
  final DateFilterOption initialOption;
  final Function(DateTime from, DateTime to, String label) onRangeChanged;

  const DateRangePickerWidget({
    super.key,
    required this.initialFrom,
    required this.initialTo,
    this.initialOption = DateFilterOption.thisMonth,
    required this.onRangeChanged,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  late DateFilterOption _selectedOption;
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _fromDate = widget.initialFrom;
    _toDate = widget.initialTo;
  }

  void _applyOption(DateFilterOption option) {
    final now = DateTime.now();
    DateTime from = now;
    DateTime to = now;
    String label = 'Today';

    switch (option) {
      case DateFilterOption.today:
        from = DateTime(now.year, now.month, now.day, 0, 0, 0);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        label = 'Today (${DateFormatter.formatDate(from)})';
        break;
      case DateFilterOption.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        label = 'This Week (${DateFormatter.formatDate(from)} → ${DateFormatter.formatDate(to)})';
        break;
      case DateFilterOption.thisMonth:
        from = DateTime(now.year, now.month, 1, 0, 0, 0);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        label = 'This Month (${DateFormatter.formatMonthYear(now)})';
        break;
      case DateFilterOption.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        from = DateTime(lastMonthDate.year, lastMonthDate.month, 1, 0, 0, 0);
        to = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 0, 23, 59, 59);
        label = 'Last Month (${DateFormatter.formatMonthYear(lastMonthDate)})';
        break;
      case DateFilterOption.thisYear:
        from = DateTime(now.year, 1, 1, 0, 0, 0);
        to = DateTime(now.year, 12, 31, 23, 59, 59);
        label = 'This Year (${now.year})';
        break;
      case DateFilterOption.custom:
        label = '${DateFormatter.formatDate(_fromDate)} → ${DateFormatter.formatDate(_toDate)}';
        from = _fromDate;
        to = _toDate;
        break;
    }

    setState(() {
      _selectedOption = option;
      _fromDate = from;
      _toDate = to;
    });

    widget.onRangeChanged(from, to, label);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final from = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      final to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      setState(() {
        _selectedOption = DateFilterOption.custom;
        _fromDate = from;
        _toDate = to;
      });
      final label = '${DateFormatter.formatDate(from)} → ${DateFormatter.formatDate(to)}';
      widget.onRangeChanged(from, to, label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<DateFilterOption>(
                value: _selectedOption,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              items: const [
                DropdownMenuItem(value: DateFilterOption.today, child: Text('Today')),
                DropdownMenuItem(value: DateFilterOption.thisWeek, child: Text('This Week')),
                DropdownMenuItem(value: DateFilterOption.thisMonth, child: Text('This Month')),
                DropdownMenuItem(value: DateFilterOption.lastMonth, child: Text('Last Month')),
                DropdownMenuItem(value: DateFilterOption.thisYear, child: Text('This Year')),
                DropdownMenuItem(value: DateFilterOption.custom, child: Text('Custom Range')),
              ],
              onChanged: (val) {
                if (val != null) {
                  if (val == DateFilterOption.custom) {
                    _pickCustomRange();
                  } else {
                    _applyOption(val);
                  }
                }
              },
            ),
          ),
          if (_selectedOption == DateFilterOption.custom) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: _pickCustomRange,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${DateFormatter.formatDate(_fromDate)} → ${DateFormatter.formatDate(_toDate)}',
                  style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
