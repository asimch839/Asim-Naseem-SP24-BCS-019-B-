import 'package:flutter/material.dart';
import '../models/salary_model.dart';
import '../utils/tax_calculator.dart';

class ResultCard extends StatelessWidget {
  final SalaryResult result;

  const ResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Calculation Results',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
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
                    backgroundColor: const Color(0xFFFFF3E0),
                    borderColor: const Color(0xFFFFB74D),
                    textColor: const Color(0xFFC62828),
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
                    backgroundColor: const Color(0xFFE8F5E9),
                    borderColor: const Color(0xFF81C784),
                    textColor: const Color(0xFF1B5E20),
                    badgeLabel: 'Take-Home Pay',
                    isFirst: false,
                  ),

                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Detailed breakdown section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salary Breakdown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
                    highlightColor: const Color(0xFF1B5E20),
                    fontSize: 16,
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
          Text(
            TaxCalculator.formatCurrency(amount),
            style: TextStyle(
              fontSize: isFirst ? 24 : 26,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
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
            ? const Color(0xFFC62828)
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
