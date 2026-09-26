import 'package:flutter/material.dart';
import '../models/salary_model.dart';
import '../models/salary_record.dart';
import '../utils/tax_calculator.dart';
import '../widgets/result_card.dart';
import '../widgets/salary_input_field.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  final Function(SalaryResult result, TaxCalculationMode mode, double flatRate)?
      onCalculated;
  final VoidCallback? onOpenSavedRecords;
  final VoidCallback? onOpenAnalytics;
  final SalaryRecord? recordToLoad;

  const SalaryCalculatorScreen({
    super.key,
    this.onCalculated,
    this.onOpenSavedRecords,
    this.onOpenAnalytics,
    this.recordToLoad,
  });

  @override
  State<SalaryCalculatorScreen> createState() => SalaryCalculatorScreenState();
}

class SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers for the 4 required fields
  final _basicSalaryController = TextEditingController();
  final _houseRentController = TextEditingController();
  final _medicalAllowanceController = TextEditingController();
  final _travelAllowanceController = TextEditingController();

  // Tax options
  TaxCalculationMode _taxMode = TaxCalculationMode.progressive;
  final _flatRateController = TextEditingController(text: '5');

  // Calculation result state
  SalaryResult? _salaryResult;

  @override
  void initState() {
    super.initState();
    if (widget.recordToLoad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.recordToLoad != null) {
          loadRecord(widget.recordToLoad!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SalaryCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recordToLoad != null &&
        widget.recordToLoad != oldWidget.recordToLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.recordToLoad != null) {
          loadRecord(widget.recordToLoad!);
        }
      });
    }
  }

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _houseRentController.dispose();
    _medicalAllowanceController.dispose();
    _travelAllowanceController.dispose();
    _flatRateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load a saved record into the form fields and recalculate
  void loadRecord(SalaryRecord record) {
    setState(() {
      _basicSalaryController.text = record.basicSalary.toStringAsFixed(0);
      _houseRentController.text = record.houseRentAllowance.toStringAsFixed(0);
      _medicalAllowanceController.text =
          record.medicalAllowance.toStringAsFixed(0);
      _travelAllowanceController.text =
          record.travelAllowance.toStringAsFixed(0);
      _taxMode = record.calculationMode;
      _flatRateController.text =
          record.flatTaxRatePercent.toStringAsFixed(1);
    });

    _calculateSalary(scrollDown: false);
  }

  void _calculateSalary({bool scrollDown = true}) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final basic = double.parse(_basicSalaryController.text.trim());
      final hra = double.parse(_houseRentController.text.trim());
      final medical = double.parse(_medicalAllowanceController.text.trim());
      final travel = double.parse(_travelAllowanceController.text.trim());

      final flatRate = double.tryParse(_flatRateController.text.trim()) ?? 5.0;

      final input = SalaryInput(
        basicSalary: basic,
        houseRentAllowance: hra,
        medicalAllowance: medical,
        travelAllowance: travel,
      );

      final result = TaxCalculator.calculate(
        input: input,
        mode: _taxMode,
        flatTaxRatePercent: flatRate,
      );

      setState(() {
        _salaryResult = result;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onCalculated?.call(result, _taxMode, flatRate);
        }
      });

      if (scrollDown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Please fill in all salary fields properly.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();
    _basicSalaryController.clear();
    _houseRentController.clear();
    _medicalAllowanceController.clear();
    _travelAllowanceController.clear();
    _formKey.currentState?.reset();

    setState(() {
      _salaryResult = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All form fields have been reset.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyPreset({
    required double basic,
    required double hra,
    required double med,
    required double travel,
  }) {
    setState(() {
      _basicSalaryController.text = basic.toStringAsFixed(0);
      _houseRentController.text = hra.toStringAsFixed(0);
      _medicalAllowanceController.text = med.toStringAsFixed(0);
      _travelAllowanceController.text = travel.toStringAsFixed(0);
    });
    _calculateSalary(scrollDown: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Professional Hero Welcome Card
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF38BDF8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Executive Salary Calculator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Accurate tax deductions, circle graph visual analytics, and local Hive data storage.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Quick Presets Bar
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Presets:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Junior (45k)',
                  onTap: () => _applyPreset(
                    basic: 30000,
                    hra: 8000,
                    med: 4000,
                    travel: 3000,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Mid-Level (95k)',
                  onTap: () => _applyPreset(
                    basic: 65000,
                    hra: 18000,
                    med: 6000,
                    travel: 6000,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Senior (180k)',
                  onTap: () => _applyPreset(
                    basic: 120000,
                    hra: 35000,
                    med: 12000,
                    travel: 13000,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Executive (320k)',
                  onTap: () => _applyPreset(
                    basic: 220000,
                    hra: 60000,
                    med: 20000,
                    travel: 20000,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Main Salary Form Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Earnings & Allowances',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _resetForm,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.restart_alt_rounded, size: 16),
                              SizedBox(width: 4),
                              Text('Clear', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field 1: Basic Salary
                    SalaryInputField(
                      controller: _basicSalaryController,
                      label: 'Basic Salary',
                      hint: 'e.g. 50000',
                      icon: Icons.account_balance_wallet_outlined,
                    ),

                    // Field 2: House Rent Allowance
                    SalaryInputField(
                      controller: _houseRentController,
                      label: 'House Rent Allowance (HRA)',
                      hint: 'e.g. 15000',
                      icon: Icons.home_work_outlined,
                    ),

                    // Field 3: Medical Allowance
                    SalaryInputField(
                      controller: _medicalAllowanceController,
                      label: 'Medical Allowance',
                      hint: 'e.g. 5000',
                      icon: Icons.medical_services_outlined,
                    ),

                    // Field 4: Travel Allowance
                    SalaryInputField(
                      controller: _travelAllowanceController,
                      label: 'Travel Allowance',
                      hint: 'e.g. 5000',
                      icon: Icons.directions_car_outlined,
                    ),

                    // Tax Calculation Settings
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: theme.colorScheme.secondary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          'Tax Calculation Settings',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        subtitle: Text(
                          _taxMode == TaxCalculationMode.progressive
                              ? 'Standard Progressive Slabs (0% - 15%)'
                              : 'Flat Tax: ${_flatRateController.text}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SegmentedButton<TaxCalculationMode>(
                                  segments: const [
                                    ButtonSegment(
                                      value: TaxCalculationMode.progressive,
                                      label: Text('Progressive Slabs'),
                                      icon: Icon(Icons.stacked_line_chart_rounded),
                                    ),
                                    ButtonSegment(
                                      value: TaxCalculationMode.flatPercentage,
                                      label: Text('Flat Rate'),
                                      icon: Icon(Icons.percent_rounded),
                                    ),
                                  ],
                                  selected: {_taxMode},
                                  onSelectionChanged: (newSelection) {
                                    setState(() {
                                      _taxMode = newSelection.first;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                if (_taxMode == TaxCalculationMode.progressive)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '• Up to 50k: 0% Tax\n'
                                      '• 50k - 100k: 5% on excess\n'
                                      '• 100k - 200k: Rs. 2,500 + 10% on excess\n'
                                      '• Above 200k: Rs. 12,500 + 15% on excess',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.4,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                else
                                  TextFormField(
                                    controller: _flatRateController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Flat Tax Percentage (%)',
                                      hintText: 'e.g. 5',
                                      suffixText: '%',
                                      prefixIcon: const Icon(Icons.percent_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Primary Action Button: Calculate
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _calculateSalary(scrollDown: true),
                        icon: const Icon(Icons.calculate_rounded, size: 22),
                        label: const Text(
                          'Calculate Salary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Result Section (Displays Tax Deduction FIRST, then Net Monthly Income, embedded Circle Graph, Breakdown, and Hive Save button)
          if (_salaryResult != null) ...[
            ResultCard(
              result: _salaryResult!,
              mode: _taxMode,
              flatRate:
                  double.tryParse(_flatRateController.text.trim()) ?? 5.0,
            ),
          ],
        ],
      ),
    ),
  ),
);
  }

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      side: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
