import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../models/repair_job.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../utils/formatters.dart';

class ExportService {
  static String rowsToCsv(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (var row in rows) {
      final line = row.map((cell) {
        final str = cell?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  static Future<String> exportSalesToCsv(List<Sale> sales) async {
    final rows = <List<dynamic>>[];
    rows.add(['Invoice #', 'Date', 'Customer', 'Phone', 'Payment Mode', 'Subtotal', 'Discount', 'Grand Total', 'Paid', 'Due', 'Status']);

    for (var s in sales) {
      rows.add([
        s.invoiceNumber,
        AppFormatters.dateTime(s.saleDate),
        s.customerName,
        s.customerPhone,
        s.paymentMethod,
        s.subtotal,
        s.discount,
        s.grandTotal,
        s.paidAmount,
        s.dueAmount,
        s.status,
      ]);
    }

    return _saveCsvFile('sales_report', rows);
  }

  static Future<String> exportRepairsToCsv(List<RepairJob> repairs) async {
    final rows = <List<dynamic>>[];
    rows.add(['Job ID', 'Customer', 'Phone', 'Device', 'IMEI', 'Problem', 'Technician', 'Status', 'Estimated', 'Final Total', 'Advance', 'Remaining Due', 'Date']);

    for (var r in repairs) {
      rows.add([
        r.jobId,
        r.customerName,
        r.customerPhone,
        '${r.deviceBrand} ${r.deviceModel}',
        r.imei,
        r.reportedProblem,
        r.technicianName,
        r.status.displayName,
        r.estimatedCost,
        r.finalTotal,
        r.advancePaid,
        r.remainingDue,
        AppFormatters.date(r.createdAt),
      ]);
    }

    return _saveCsvFile('repair_jobs_report', rows);
  }

  static Future<String> exportInventoryToCsv(List<Product> products) async {
    final rows = <List<dynamic>>[];
    rows.add(['Product Name', 'SKU', 'Barcode', 'Category', 'Brand', 'Purchase Price', 'Sale Price', 'Current Stock', 'Stock Value (Cost)', 'Stock Value (Retail)']);

    for (var p in products) {
      rows.add([
        p.name,
        p.sku,
        p.barcode,
        p.category,
        p.brand,
        p.purchasePrice,
        p.salePrice,
        p.stockQuantity,
        p.purchasePrice * p.stockQuantity,
        p.salePrice * p.stockQuantity,
      ]);
    }

    return _saveCsvFile('inventory_valuation', rows);
  }

  static Future<String> exportCustomerDuesToCsv(List<Customer> customers) async {
    final rows = <List<dynamic>>[];
    rows.add(['Customer Name', 'Phone', 'Alternate Phone', 'Address', 'Total Purchases', 'Total Paid', 'Outstanding Due']);

    for (var c in customers.where((c) => c.totalDue > 0)) {
      rows.add([
        c.name,
        c.phone,
        c.alternatePhone,
        c.address,
        c.totalPurchases,
        c.totalPaid,
        c.totalDue,
      ]);
    }

    return _saveCsvFile('customer_dues_ledger', rows);
  }

  static Future<String> exportSupplierDuesToCsv(List<Supplier> suppliers) async {
    final rows = <List<dynamic>>[];
    rows.add(['Supplier Name', 'Company', 'Phone', 'Address', 'Total Purchases', 'Total Paid', 'Payable Due']);

    for (var s in suppliers.where((s) => s.dueAmount > 0)) {
      rows.add([
        s.name,
        s.company,
        s.phone,
        s.address,
        s.totalPurchases,
        s.paidAmount,
        s.dueAmount,
      ]);
    }

    return _saveCsvFile('supplier_dues_ledger', rows);
  }

  static Future<String> _saveCsvFile(String prefix, List<List<dynamic>> rows) async {
    final csvData = rowsToCsv(rows);
    final docs = await getApplicationDocumentsDirectory();
    final exportDir = Directory(join(docs.path, 'MobileShopLab', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(join(exportDir.path, '${prefix}_$timestamp.csv'));
    await file.writeAsString(csvData);
    return file.path;
  }
}
