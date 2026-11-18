import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

enum DateFilterPreset {
  all,
  today,
  thisWeek,
  thisMonth,
  custom,
}

class DateRangeFilterBar extends StatefulWidget {
  final DateFilterPreset initialPreset;
  final String? initialStartDate;
  final String? initialEndDate;
  final void Function(String? startDate, String? endDate, String label) onFilterChanged;

  const DateRangeFilterBar({
    super.key,
    this.initialPreset = DateFilterPreset.all,
    this.initialStartDate,
    this.initialEndDate,
    required this.onFilterChanged,
  });

  @override
  State<DateRangeFilterBar> createState() => _DateRangeFilterBarState();
}

class _DateRangeFilterBarState extends State<DateRangeFilterBar> {
  late DateFilterPreset _selectedPreset;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      final s = DateTime.tryParse(widget.initialStartDate!);
      final e = DateTime.tryParse(widget.initialEndDate!);
      if (s != null && e != null) {
        _customRange = DateTimeRange(start: s, end: e);
      }
    }
  }

  void _applyPreset(DateFilterPreset preset) async {
    final now = DateTime.now();

    if (preset == DateFilterPreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: _customRange ?? DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedPreset = DateFilterPreset.custom;
          _customRange = picked;
        });
        final startIso = DateFormat('yyyy-MM-dd').format(picked.start);
        final endIso = DateFormat('yyyy-MM-dd').format(picked.end);
        final label = '${DateFormat('d MMM').format(picked.start)} - ${DateFormat('d MMM').format(picked.end)}';
        widget.onFilterChanged(startIso, endIso, label);
      }
      return;
    }

    setState(() {
      _selectedPreset = preset;
    });

    switch (preset) {
      case DateFilterPreset.all:
        widget.onFilterChanged(null, null, 'All Time');
        break;
      case DateFilterPreset.today:
        final startIso = DateFormat('yyyy-MM-dd').format(now);
        final endIso = DateFormat('yyyy-MM-dd').format(now);
        widget.onFilterChanged(startIso, endIso, 'Today');
        break;
      case DateFilterPreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final startIso = DateFormat('yyyy-MM-dd').format(startOfWeek);
        final endIso = DateFormat('yyyy-MM-dd').format(endOfWeek);
        widget.onFilterChanged(startIso, endIso, 'This Week');
        break;
      case DateFilterPreset.thisMonth:
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        final startIso = DateFormat('yyyy-MM-dd').format(firstDay);
        final endIso = DateFormat('yyyy-MM-dd').format(lastDay);
        widget.onFilterChanged(startIso, endIso, 'This Month');
        break;
      case DateFilterPreset.custom:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String customLabel = 'Custom';
    if (_customRange != null) {
      customLabel = '${DateFormat('d MMM').format(_customRange!.start)} - ${DateFormat('d MMM').format(_customRange!.end)}';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(DateFilterPreset.all, 'All Time', Icons.all_inclusive_rounded),
          const SizedBox(width: 6),
          _buildChip(DateFilterPreset.today, 'Today', Icons.today_rounded),
          const SizedBox(width: 6),
          _buildChip(DateFilterPreset.thisWeek, 'This Week', Icons.view_week_rounded),
          const SizedBox(width: 6),
          _buildChip(DateFilterPreset.thisMonth, 'This Month', Icons.calendar_month_rounded),
          const SizedBox(width: 6),
          _buildChip(
            DateFilterPreset.custom,
            customLabel,
            Icons.date_range_rounded,
            isCustom: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    DateFilterPreset preset,
    String label,
    IconData icon, {
    bool isCustom = false,
  }) {
    final isSelected = _selectedPreset == preset;

    return InkWell(
      onTap: () => _applyPreset(preset),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderDark,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textDarkSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDarkPrimary,
              ),
            ),
            if (isCustom && isSelected && _customRange != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _customRange = null;
                  });
                  _applyPreset(DateFilterPreset.all);
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

