import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/salary_record.dart';
import '../services/salary_storage_service.dart';
import '../utils/tax_calculator.dart';
import '../widgets/salary_circle_graph.dart';

enum HistorySortOption { newest, highestNet, lowestTax }

class SavedRecordsScreen extends StatefulWidget {
  final Function(SalaryRecord record)? onRestoreRecord;
  final VoidCallback? onGoToCalculator;

  const SavedRecordsScreen({
    super.key,
    this.onRestoreRecord,
    this.onGoToCalculator,
  });

  @override
  State<SavedRecordsScreen> createState() => _SavedRecordsScreenState();
}

class _SavedRecordsScreenState extends State<SavedRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  HistorySortOption _sortOption = HistorySortOption.newest;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SalaryRecord> _filterAndSortRecords(List<SalaryRecord> records) {
    var filtered = records;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.grossSalary.toString().contains(q) ||
            r.netMonthlyIncome.toString().contains(q);
      }).toList();
    }

    switch (_sortOption) {
      case HistorySortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HistorySortOption.highestNet:
        filtered
            .sort((a, b) => b.netMonthlyIncome.compareTo(a.netMonthlyIncome));
        break;
      case HistorySortOption.lowestTax:
        filtered.sort((a, b) => a.taxDeduction.compareTo(b.taxDeduction));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: SalaryStorageService.listenable(),
      builder: (context, Box box, _) {
        final allRecords = SalaryStorageService.getAllRecords();
        final filteredRecords = _filterAndSortRecords(allRecords);

        // Compute aggregate metrics
        double totalTax = 0;
        double totalNet = 0;
        for (final r in allRecords) {
          totalTax += r.taxDeduction;
          totalNet += r.netMonthlyIncome;
        }
        final avgNet =
            allRecords.isNotEmpty ? totalNet / allRecords.length : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isTabletOrDesktop = screenWidth >= 700;
            final contentHorizontalPadding = screenWidth > 900
                ? 32.0
                : (screenWidth > 600 ? 24.0 : 16.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: CustomScrollView(
                  slivers: [
                    // Header, Stats, Search, and Filters
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentHorizontalPadding,
                          16,
                          contentHorizontalPadding,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top History Dashboard Banner
                            _buildHeroBanner(
                              context: context,
                              isDark: isDark,
                              allRecordsCount: allRecords.length,
                              avgNet: avgNet,
                              totalTax: totalTax,
                              isTabletOrDesktop: isTabletOrDesktop,
                            ),

                            if (allRecords.isNotEmpty) ...[
                              const SizedBox(height: 16),

                              // Responsive Search & Sort Controls
                              _buildSearchAndFilters(
                                theme: theme,
                                isTabletOrDesktop: isTabletOrDesktop,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Empty State or Responsive List/Grid of Records
                    if (filteredRecords.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(theme),
                      )
                    else if (isTabletOrDesktop)
                      // Tablet, iPad, and Laptop Grid View
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          contentHorizontalPadding,
                          4,
                          contentHorizontalPadding,
                          100,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 520,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildRecordCard(
                                context,
                                filteredRecords[index],
                              );
                            },
                            childCount: filteredRecords.length,
                          ),
                        ),
                      )
                    else
                      // Mobile View (Single Column)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          contentHorizontalPadding,
                          4,
                          contentHorizontalPadding,
                          100,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildRecordCard(
                                  context,
                                  filteredRecords[index],
                                ),
                              );
                            },
                            childCount: filteredRecords.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroBanner({
    required BuildContext context,
    required bool isDark,
    required int allRecordsCount,
    required double avgNet,
    required double totalTax,
    required bool isTabletOrDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isTabletOrDesktop ? 22 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Calculation History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (allRecordsCount > 0)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.white70, size: 22),
                  tooltip: 'Clear All History',
                  onPressed: () => _confirmClearAll(context),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Total Saved',
                  value: '$allRecordsCount',
                  subtext: 'Calculations',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Avg Take-Home',
                  value: TaxCalculator.formatCurrency(avgNet),
                  subtext: 'Per month',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Total Tax',
                  value: TaxCalculator.formatCurrency(totalTax),
                  subtext: 'All records',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 9.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters({
    required ThemeData theme,
    required bool isTabletOrDesktop,
  }) {
    final searchWidget = TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search history by label or amount...',
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );

    final sortChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSortChip(
            label: 'Newest First',
            icon: Icons.access_time_rounded,
            option: HistorySortOption.newest,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: 'Highest Take-Home',
            icon: Icons.trending_up_rounded,
            option: HistorySortOption.highestNet,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: 'Lowest Tax',
            icon: Icons.savings_outlined,
            option: HistorySortOption.lowestTax,
          ),
        ],
      ),
    );

    if (isTabletOrDesktop) {
      return Row(
        children: [
          Expanded(flex: 3, child: searchWidget),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: sortChips),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchWidget,
          const SizedBox(height: 10),
          sortChips,
        ],
      );
    }
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required HistorySortOption option,
  }) {
    final isSelected = _sortOption == option;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _sortOption = option;
        });
      },
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF1E3A8A)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildRecordCard(BuildContext context, SalaryRecord record) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(record.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showRecordDetails(context, record),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Title, Date, and Delete Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 10.5,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 19),
                      tooltip: 'Delete Calculation',
                      onPressed: () => _confirmDelete(context, record),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Adaptive Metrics Row (Wrap-safe & Auto-scaling)
                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final cardW = cardConstraints.maxWidth;
                    final isCompact = cardW < 320;

                    if (isCompact) {
                      // Ultra-narrow fallback: Take-Home on top, Tax & Gross underneath
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMetricTile(
                            label: 'Take-Home Pay',
                            amount: record.netMonthlyIncome,
                            color: const Color(0xFF059669),
                            bgColor:
                                const Color(0xFF10B981).withValues(alpha: 0.09),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  label: 'Tax Deducted',
                                  amount: record.taxDeduction,
                                  color: const Color(0xFFDC2626),
                                  bgColor: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.08),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildMetricTile(
                                  label: 'Gross Total',
                                  amount: record.grossSalary,
                                  color: theme.colorScheme.primary,
                                  bgColor: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Standard 3-column responsive layout
                    return Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildMetricTile(
                            label: 'Take-Home Pay',
                            amount: record.netMonthlyIncome,
                            color: const Color(0xFF059669),
                            bgColor:
                                const Color(0xFF10B981).withValues(alpha: 0.09),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: _buildMetricTile(
                            label: 'Tax Deducted',
                            amount: record.taxDeduction,
                            color: const Color(0xFFDC2626),
                            bgColor:
                                const Color(0xFFEF4444).withValues(alpha: 0.08),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: _buildMetricTile(
                            label: 'Gross Total',
                            amount: record.grossSalary,
                            color: theme.colorScheme.primary,
                            bgColor: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Responsive Bottom Action Row (Uses Wrap to prevent ANY RenderFlex overflow)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.taxMode == 'flatPercentage'
                            ? 'Flat Tax (${record.flatTaxRatePercent}%)'
                            : 'Progressive Tax Slabs',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showRecordDetails(context, record),
                          icon: const Icon(Icons.pie_chart_outline_rounded,
                              size: 14),
                          label: const Text(
                            'Graph',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                          onPressed: () {
                            widget.onRestoreRecord?.call(record);
                          },
                          icon: const Icon(Icons.upload_rounded, size: 14),
                          label: const Text(
                            'Load',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              TaxCalculator.formatCurrency(amount),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.history_rounded,
                size: 56,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No Matching Calculations'
                  : 'No Saved History Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different role title or amount.'
                  : 'Every time you calculate a salary, tap "Save" to build your compensation history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            if (_searchQuery.isEmpty && widget.onGoToCalculator != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onGoToCalculator,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calculate a Salary Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(BuildContext context, SalaryRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final result = record.toSalaryResult();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy • hh:mm a')
                            .format(record.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SalaryCircleGraph(result: result),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRestoreRecord?.call(record);
                        },
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text(
                          'Load This Record Into Calculator',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, SalaryRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Calculation?'),
        content: Text(
            'Are you sure you want to remove "${record.title}" from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await SalaryStorageService.deleteRecord(record.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
            'This will permanently delete all stored salary calculations from your local Hive database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await SalaryStorageService.clearAllRecords();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
