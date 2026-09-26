import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/salary_model.dart';
import '../models/salary_record.dart';
import '../services/salary_storage_service.dart';
import '../utils/tax_calculator.dart';
import 'salary_circle_graph.dart';

class ResultCard extends StatefulWidget {
  final SalaryResult result;
  final TaxCalculationMode mode;
  final double flatRate;
  final VoidCallback? onSaved;

  const ResultCard({
    super.key,
    required this.result,
    this.mode = TaxCalculationMode.progressive,
    this.flatRate = 5.0,
    this.onSaved,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isSaved = false;

  void _saveRecord() {
    final titleController = TextEditingController(
      text: 'Salary • ${TaxCalculator.formatCurrency(widget.result.netMonthlyIncome)}',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bookmark_add_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Save',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Give this calculation a label to easily locate it in your saved history:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Record Title / Label',
                  hintText: 'e.g. Senior Software Engineer',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              onPressed: () async {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final record = SalaryRecord.fromResult(
                  id: id,
                  title: titleController.text,
                  result: widget.result,
                  mode: widget.mode,
                  flatRate: widget.flatRate,
                );

                try {
                  await SalaryStorageService.saveRecord(record);
                } catch (e) {
                  debugPrint('saveRecord error: $e');
                }
                if (mounted) {
                  setState(() {
                    _isSaved = true;
                  });
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Saved "${record.title}" to local Hive database!',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }

                widget.onSaved?.call();
              },
            ),
          ],
        );
      },
    );
  }

  void _copySummary() {
    final res = widget.result;
    final summary = StringBuffer();
    summary.writeln('📋 Salary Calculation Summary:');
    summary.writeln('--------------------------------');
    summary.writeln('Basic Salary: ${TaxCalculator.formatCurrency(res.input.basicSalary)}');
    summary.writeln('House Rent Allowance: ${TaxCalculator.formatCurrency(res.input.houseRentAllowance)}');
    summary.writeln('Medical Allowance: ${TaxCalculator.formatCurrency(res.input.medicalAllowance)}');
    summary.writeln('Travel Allowance: ${TaxCalculator.formatCurrency(res.input.travelAllowance)}');
    summary.writeln('--------------------------------');
    summary.writeln('Gross Monthly Salary: ${TaxCalculator.formatCurrency(res.grossSalary)}');
    summary.writeln('Tax Deduction: ${TaxCalculator.formatCurrency(res.taxDeduction)} (${res.taxDescription})');
    summary.writeln('Net Monthly Take-Home: ${TaxCalculator.formatCurrency(res.netMonthlyIncome)}');

    Clipboard.setData(ClipboardData(text: summary.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Salary summary copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

    return Container(
      margin: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Elegant Header banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.88),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Calculation Results',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                        tooltip: 'Copy Summary',
                        onPressed: _copySummary,
                      ),
                      IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: _isSaved ? 'Saved' : 'Save',
                        onPressed: _saveRecord,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. TAX DEDUCTION (Shown FIRST as required)
                  _buildResultHighlightBox(
                    context: context,
                    label: 'Tax Deduction',
                    amount: result.taxDeduction,
                    subtitle: result.taxDescription,
                    icon: Icons.trending_down_rounded,
                    backgroundColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    textColor: const Color(0xFFDC2626),
                    badgeLabel: 'Deduction',
                    isFirst: true,
                  ),

                  const SizedBox(height: 16),

                  // 2. NET MONTHLY INCOME (Shown SECOND as required)
                  _buildResultHighlightBox(
                    context: context,
                    label: 'Net Monthly Income',
                    amount: result.netMonthlyIncome,
                    subtitle: 'Gross Salary − Tax Deduction',
                    icon: Icons.account_balance_wallet_rounded,
                    backgroundColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFFA7F3D0),
                    textColor: const Color(0xFF059669),
                    badgeLabel: 'Take-Home Pay',
                    isFirst: false,
                  ),

                  const SizedBox(height: 22),

                  // Circle Graph (Embedded Circle Graph visual representation)
                  SalaryCircleGraph(
                    result: result,
                    isCompact: true,
                  ),

                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Detailed breakdown section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Salary Breakdown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildBreakdownRow(
                    context,
                    label: 'Basic Salary',
                    amount: result.input.basicSalary,
                  ),
                  _buildBreakdownRow(
                    context,
                    label: 'House Rent Allowance (HRA)',
                    amount: result.input.houseRentAllowance,
                  ),
                  _buildBreakdownRow(
                    context,
                    label: 'Medical Allowance',
                    amount: result.input.medicalAllowance,
                  ),
                  _buildBreakdownRow(
                    context,
                    label: 'Travel Allowance',
                    amount: result.input.travelAllowance,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(thickness: 0.8),
                  ),

                  _buildBreakdownRow(
                    context,
                    label: 'Total Allowances',
                    amount: result.input.totalAllowances,
                    isMuted: true,
                  ),
                  _buildBreakdownRow(
                    context,
                    label: 'Gross Salary',
                    amount: result.grossSalary,
                    isBold: true,
                  ),
                  _buildBreakdownRow(
                    context,
                    label: 'Tax Deduction',
                    amount: result.taxDeduction,
                    isDeduction: true,
                    isBold: true,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(thickness: 1.2),
                  ),

                  _buildBreakdownRow(
                    context,
                    label: 'Net Monthly Income',
                    amount: result.netMonthlyIncome,
                    isBold: true,
                    highlightColor: const Color(0xFF059669),
                    fontSize: 16,
                  ),

                  const SizedBox(height: 20),

                  // Quick Action: Save Record
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saveRecord,
                      icon: Icon(
                        _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                        color: _isSaved ? const Color(0xFF10B981) : theme.colorScheme.primary,
                      ),
                      label: Text(
                        _isSaved ? 'Saved' : 'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isSaved ? const Color(0xFF10B981) : theme.colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: _isSaved
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHighlightBox({
    required BuildContext context,
    required String label,
    required double amount,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required String badgeLabel,
    required bool isFirst,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: textColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              TaxCalculator.formatCurrency(amount),
              style: TextStyle(
                fontSize: isFirst ? 24 : 26,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context, {
    required String label,
    required double amount,
    bool isBold = false,
    bool isMuted = false,
    bool isDeduction = false,
    Color? highlightColor,
    double fontSize = 14,
  }) {
    final theme = Theme.of(context);
    final color = highlightColor ??
        (isDeduction
            ? const Color(0xFFDC2626)
            : (isMuted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isMuted
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isDeduction ? '-' : ''}${TaxCalculator.formatCurrency(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
