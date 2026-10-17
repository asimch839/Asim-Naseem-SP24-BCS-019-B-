import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/repositories/dashboard_report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportRepo = DashboardReportRepository();

  String _selectedReport = 'income_expense';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _reportData = [];

  final Map<String, String> _reportTypes = {
    'income_expense': 'Income & Expenses (P&L)',
    'customers': 'Customer Directory Report',
    'vehicles': 'Vehicle Fleet & Customer Links',
    'service_history': 'Vehicle Service & Odometer History',
    'garage_expenses': 'Garage Expenses Report',
    'vendor_expenses': 'Vendor-Wise Expenses Report',
    'inventory': 'Inventory Valuation & Stock Details',
    'invoices': 'Invoices & Billing Summary',
    'payments': 'Payments Received Report',
  };

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await _reportRepo.getReportData(
        _selectedReport,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) setState(() => _reportData = res);
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate report: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exportCsv() async {
    if (_reportData.isEmpty) {
      Get.snackbar('No Data', 'Report has no records to export');
      return;
    }

    final headers = _reportData.first.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final row in _reportData) {
      final line = headers.map((h) {
        final val = row[h]?.toString().replaceAll('"', '""') ?? '';
        return '"$val"';
      }).join(',');
      buffer.writeln(line);
    }

    try {
      final fileName = '${_selectedReport}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final path = await StorageService.saveLocalFile(
        bytes: buffer.toString().codeUnits,
        fileName: fileName,
        subfolder: 'reports',
      );
      Get.snackbar('CSV Exported', 'Saved to: $path', duration: const Duration(seconds: 4), backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'CSV export failed: $e');
    }
  }

  void _printPdf() async {
    if (_reportData.isEmpty) {
      Get.snackbar('No Data', 'Report has no records to print');
      return;
    }

    final headers = _reportData.first.keys.map((k) => k.replaceAll('_', ' ').toUpperCase()).toList();
    final data = _reportData.map((row) {
      return _reportData.first.keys.map((k) => row[k]?.toString() ?? '').toList();
    }).toList();

    await PdfService.printReportTable(
      title: _reportTypes[_selectedReport] ?? 'Management Report',
      subtitle: 'Date Range: ${Formatters.date(_startDate)} to ${Formatters.date(_endDate)} | Total Records: ${_reportData.length}',
      headers: headers,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.reports,
      title: 'Management Reports & Audits',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Controls Bar (Report Type, Date Pickers, CSV, Print)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Report Type Selector
                    DropdownButton<String>(
                      value: _selectedReport,
                      underline: const SizedBox(),
                      items: _reportTypes.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedReport = val);
                          _fetchReport();
                        }
                      },
                    ),

                    // Date Range Controls
                    OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (range != null) {
                          setState(() {
                            _startDate = range.start;
                            _endDate = range.end;
                          });
                          _fetchReport();
                        }
                      },
                      icon: const Icon(Icons.date_range_rounded, size: 16),
                      label: Text('${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh Query',
                      onPressed: _fetchReport,
                    ),

                    const SizedBox(width: 8),

                    // Export Buttons
                    ElevatedButton.icon(
                      onPressed: _reportData.isEmpty ? null : _exportCsv,
                      icon: const Icon(Icons.table_view_rounded, size: 16),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      label: const Text('Export CSV'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _reportData.isEmpty ? null : _printPdf,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print / PDF'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Results Table
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Generating SQLite report...')
                  : _reportData.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.assessment_outlined,
                          title: 'No Records Match Filter',
                          description: 'Change the report type or expand the date range to view audit records.',
                        )
                      : Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_reportTypes[_selectedReport]} (${_reportData.length} records)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Audited locally from SQLite',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppColors.cardDark),
                                      columns: _reportData.first.keys.map((k) {
                                        return DataColumn(
                                          label: Text(
                                            k.replaceAll('_', ' ').toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      rows: _reportData.map((row) {
                                        return DataRow(
                                          cells: _reportData.first.keys.map((k) {
                                            return DataCell(
                                              Text(row[k]?.toString() ?? '-', style: const TextStyle(fontSize: 12)),
                                            );
                                          }).toList(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
