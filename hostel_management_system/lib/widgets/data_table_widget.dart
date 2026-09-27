import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import 'empty_state_widget.dart';

class TableColumnDef {
  final String title;
  final double? width;
  final bool isNumeric;
  final Alignment alignment;

  const TableColumnDef({
    required this.title,
    this.width,
    this.isNumeric = false,
    this.alignment = Alignment.centerLeft,
  });
}

class DataTableWidget extends StatefulWidget {
  final List<TableColumnDef> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final String? emptyActionText;
  final VoidCallback? onEmptyAction;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyTitle = 'No Records Found',
    this.emptySubtitle = 'There are no records matching your current filter criteria.',
    this.emptyActionText,
    this.onEmptyAction,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        height: 300,
        decoration: AppStyles.cardDecoration,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (widget.rows.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 280),
        decoration: AppStyles.cardDecoration,
        child: EmptyStateWidget(
          title: widget.emptyTitle,
          description: widget.emptySubtitle,
          actionText: widget.emptyActionText,
          onAction: widget.onEmptyAction,
        ),
      );
    }

    return Container(
      decoration: AppStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget tableContent = SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                dataRowMaxHeight: 52,
                dataRowMinHeight: 48,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 1,
                headingTextStyle: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                columns: widget.columns.map((col) {
                  return DataColumn(
                    label: Align(
                      alignment: col.alignment,
                      child: Text(col.title),
                    ),
                    numeric: col.isNumeric,
                  );
                }).toList(),
                rows: widget.rows.map((rowCells) {
                  return DataRow(
                    cells: rowCells.map((cellWidget) {
                      return DataCell(cellWidget);
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          );

          if (constraints.maxHeight.isFinite) {
            return SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: tableContent,
            );
          }

          return tableContent;
        },
      ),
    );
  }
}
