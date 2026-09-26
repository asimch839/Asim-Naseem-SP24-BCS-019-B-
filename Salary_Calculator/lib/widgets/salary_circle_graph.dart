import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/salary_model.dart';
import '../utils/tax_calculator.dart';

/// Data item for an individual slice of the circle chart
class CircleSliceData {
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const CircleSliceData({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

/// An elegant, animated circle/donut chart representing salary distribution
class SalaryCircleGraph extends StatefulWidget {
  final SalaryResult result;
  final bool isCompact;

  const SalaryCircleGraph({
    super.key,
    required this.result,
    this.isCompact = false,
  });

  @override
  State<SalaryCircleGraph> createState() => _SalaryCircleGraphState();
}

class _SalaryCircleGraphState extends State<SalaryCircleGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _selectedView = 0; // 0: Net Pay vs Tax, 1: Component Breakdown

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant SalaryCircleGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<CircleSliceData> _getSlices() {
    final gross = widget.result.grossSalary;
    if (gross <= 0) return [];

    if (_selectedView == 0) {
      // Perspective 1: Net Take-Home Pay vs Tax Deduction
      final net = widget.result.netMonthlyIncome;
      final tax = widget.result.taxDeduction;

      final netPct = (net / gross) * 100.0;
      final taxPct = (tax / gross) * 100.0;

      return [
        CircleSliceData(
          label: 'Net Take-Home Pay',
          amount: net,
          percentage: netPct,
          color: const Color(0xFF10B981), // Emerald Green
          icon: Icons.account_balance_wallet_rounded,
        ),
        CircleSliceData(
          label: 'Income Tax Deduction',
          amount: tax,
          percentage: taxPct,
          color: const Color(0xFFEF4444), // Vibrant Rose/Red
          icon: Icons.trending_down_rounded,
        ),
      ];
    } else {
      // Perspective 2: Granular Earnings & Tax breakdown
      final basic = widget.result.input.basicSalary;
      final hra = widget.result.input.houseRentAllowance;
      final med = widget.result.input.medicalAllowance;
      final travel = widget.result.input.travelAllowance;
      final tax = widget.result.taxDeduction;

      final list = <CircleSliceData>[];

      if (basic > 0) {
        list.add(CircleSliceData(
          label: 'Basic Salary',
          amount: basic,
          percentage: (basic / gross) * 100,
          color: const Color(0xFF3B82F6), // Royal Blue
          icon: Icons.monetization_on_rounded,
        ));
      }
      if (hra > 0) {
        list.add(CircleSliceData(
          label: 'House Rent (HRA)',
          amount: hra,
          percentage: (hra / gross) * 100,
          color: const Color(0xFF06B6D4), // Cyan
          icon: Icons.home_rounded,
        ));
      }
      if (med > 0) {
        list.add(CircleSliceData(
          label: 'Medical Allowance',
          amount: med,
          percentage: (med / gross) * 100,
          color: const Color(0xFFF59E0B), // Amber
          icon: Icons.medical_services_rounded,
        ));
      }
      if (travel > 0) {
        list.add(CircleSliceData(
          label: 'Travel Allowance',
          amount: travel,
          percentage: (travel / gross) * 100,
          color: const Color(0xFF8B5CF6), // Purple
          icon: Icons.directions_car_rounded,
        ));
      }
      if (tax > 0) {
        list.add(CircleSliceData(
          label: 'Tax Deduction',
          amount: tax,
          percentage: (tax / gross) * 100,
          color: const Color(0xFFEF4444), // Coral/Red
          icon: Icons.trending_down_rounded,
        ));
      }
      return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = _getSlices();
    final gross = widget.result.grossSalary;

    if (gross <= 0) {
      return const SizedBox.shrink();
    }

    final netPct = (widget.result.netMonthlyIncome / gross) * 100;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.isCompact ? 16.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Salary Circle Graph',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Segmented view toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn(0, 'Overview'),
                    _buildToggleBtn(1, 'Breakdown'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Circle Canvas & Center Readout
          Center(
            child: SizedBox(
              width: widget.isCompact ? 200 : 230,
              height: widget.isCompact ? 200 : 230,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DonutChartPainter(
                      slices: slices,
                      progress: _animation.value,
                      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                      strokeWidth: widget.isCompact ? 24 : 28,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TAKE-HOME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${netPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TaxCalculator.formatCurrency(
                              widget.result.netMonthlyIncome,
                              symbol: 'Rs. ',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Legend list
          Column(
            children: slices.map((slice) {
              return _buildLegendItem(context, slice);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(int index, String title) {
    final isSelected = _selectedView == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (_selectedView != index) {
          setState(() {
            _selectedView = index;
          });
          _animController.reset();
          _animController.forward();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, CircleSliceData slice) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slice.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: slice.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${slice.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: slice.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            TaxCalculator.formatCurrency(slice.amount, symbol: 'Rs. '),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Donut Chart
class _DonutChartPainter extends CustomPainter {
  final List<CircleSliceData> slices;
  final double progress;
  final Color backgroundColor;
  final double strokeWidth;

  _DonutChartPainter({
    required this.slices,
    required this.progress,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (slices.isEmpty || progress <= 0) return;

    double total = 0;
    for (final s in slices) {
      total += s.amount;
    }
    if (total <= 0) return;

    // Start angle at top (-90 degrees)
    double currentAngle = -math.pi / 2;
    final totalSweepLimit = 2 * math.pi * progress;
    double accumulatedSweep = 0;

    for (final slice in slices) {
      if (accumulatedSweep >= totalSweepLimit) break;

      final sliceSweep = (slice.amount / total) * (2 * math.pi);
      final remainingSweep = totalSweepLimit - accumulatedSweep;
      final sweepToDraw = math.min(sliceSweep, remainingSweep);

      if (sweepToDraw > 0) {
        final slicePaint = Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

        // Draw the arc with subtle spacing
        final spacing = 0.035; // radians spacing
        final adjustedSweep = math.max(0.0, sweepToDraw - spacing);
        final adjustedStart = currentAngle + (spacing / 2);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          adjustedStart,
          adjustedSweep,
          false,
          slicePaint,
        );
      }

      currentAngle += sliceSweep;
      accumulatedSweep += sliceSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.slices != slices ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
