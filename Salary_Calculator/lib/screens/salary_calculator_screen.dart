import 'package:flutter/material.dart';
import '../models/salary_model.dart';
import '../utils/tax_calculator.dart';
import '../widgets/result_card.dart';
import '../widgets/salary_input_field.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key});

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
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
  void dispose() {
    _basicSalaryController.dispose();
    _houseRentController.dispose();
    _medicalAllowanceController.dispose();
    _travelAllowanceController.dispose();
    _flatRateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateSalary() {
    FocusScope.of(context).unfocus();

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

      // Scroll smoothly down to result
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
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
        content: Text('All fields have been reset.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _fillSampleData() {
    setState(() {
      _basicSalaryController.text = '60000';
      _houseRentController.text = '15000';
      _medicalAllowanceController.text = '5000';
      _travelAllowanceController.text = '5000';
    });
    _calculateSalary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calculate_rounded, size: 26),
            SizedBox(width: 10),
            Text(
              'Salary Calculator',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Fill Sample Data',
            onPressed: _fillSampleData,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset All',
            onPressed: _resetForm,
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome / Info Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payments_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Net Salary Estimator',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter your salary & allowances to calculate Tax Deduction and Net Monthly Income.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Section
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Earnings & Allowances',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
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
                          label: 'House Rent Allowance',
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

                        // Tax Mode Expansion / Options
                        Theme(
                          data: theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.tune_rounded,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            title: Text(
                              'Tax Calculation Settings',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            subtitle: Text(
                              _taxMode == TaxCalculationMode.progressive
                                  ? 'Mode: Progressive Slabs (0% - 15%)'
                                  : 'Mode: Flat ${_flatRateController.text}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          'Slabs: 0% up to 50k | 5% (50k-100k) | 10% (100k-200k) | 15% (>200k)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                          vertical: 6.0,
                                        ),
                                        child: TextFormField(
                                          controller: _flatRateController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Tax Rate (%)',
                                            hintText: 'e.g. 5',
                                            suffixText: '%',
                                            isDense: true,
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

                        // Action Buttons: Calculate and Reset
                        Row(
                          children: [
                            // Calculate Button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: _calculateSalary,
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text(
                                  'Calculate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Reset Button
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: _resetForm,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Result Section (Displays Tax Deduction FIRST, then Net Monthly Income)
              if (_salaryResult != null)
                ResultCard(result: _salaryResult!),
            ],
          ),
        ),
      ),
    );
  }
}
