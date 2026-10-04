import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale.dart';
import '../models/repair_job.dart';
import '../models/payment_record.dart';
import '../models/business_settings.dart';
import '../utils/formatters.dart';

class PrintService {
  // A4 Standard Sale Invoice
  static Future<void> printSaleInvoice({
    required Sale sale,
    required BusinessSettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.shopName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(settings.tagline, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(settings.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Phone: ${settings.phone} | ${settings.altPhone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (settings.ntn.isNotEmpty)
                        pw.Text('NTN / Tax ID: ${settings.ntn}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blue300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('SALE INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('Invoice #: ${sale.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${AppFormatters.dateTime(sale.saleDate)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Cashier: ${sale.cashierName}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // Customer Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO (CUSTOMER)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(sale.customerName.isNotEmpty ? sale.customerName : 'Walk-in Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (sale.customerPhone.isNotEmpty)
                        pw.Text('Contact: ${sale.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Payment Mode: ${sale.paymentMethod}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (sale.notes.isNotEmpty)
                        pw.Text('Notes: ${sale.notes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('#'),
                      _th('Item Description & Serial / IMEI'),
                      _th('Qty'),
                      _th('Unit Price'),
                      _th('Discount'),
                      _th('Total'),
                    ],
                  ),
                  ...List.generate(sale.items.length, (idx) {
                    final item = sale.items[idx];
                    return pw.TableRow(
                      children: [
                        _td('${idx + 1}', align: pw.TextAlign.center),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              if (item.imei.isNotEmpty)
                                pw.Text('IMEI / S/N: ${item.imei}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
                              if (item.warrantyMonths > 0)
                                pw.Text('Warranty: ${item.warrantyMonths} Months Shop Warranty', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                        _td('${item.quantity}', align: pw.TextAlign.center),
                        _td(AppFormatters.currency(item.unitPrice), align: pw.TextAlign.right),
                        _td(AppFormatters.currency(item.discount), align: pw.TextAlign.right),
                        _td(AppFormatters.currency(item.total), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text(settings.termsAndConditions, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal:', AppFormatters.currency(sale.subtotal)),
                        if (sale.discount > 0)
                          _summaryRow('Special Discount:', '- ${AppFormatters.currency(sale.discount)}', color: PdfColors.red700),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        _summaryRow('Grand Total:', AppFormatters.currency(sale.grandTotal), isBold: true, fontSize: 13),
                        _summaryRow('Paid Amount:', AppFormatters.currency(sale.paidAmount), color: PdfColors.green800),
                        if (sale.dueAmount > 0)
                          _summaryRow('Balance Due:', AppFormatters.currency(sale.dueAmount), isBold: true, color: PdfColors.red800),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(settings.invoiceFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }

  // Thermal 80mm Receipt
  static Future<void> printThermalReceipt({
    required Sale sale,
    required BusinessSettings settings,
    bool is58mm = false,
  }) async {
    final pdf = pw.Document();
    final double width = is58mm ? 58 * PdfPageFormat.mm : 80 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, double.infinity, marginAll: 8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(settings.shopName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              pw.Text(settings.tagline, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              pw.Text(settings.address, style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
              pw.Text('Tel: ${settings.phone}', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Inv: ${sale.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(AppFormatters.date(sale.saleDate), style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
              if (sale.customerName.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Customer: ${sale.customerName} (${sale.customerPhone})', style: const pw.TextStyle(fontSize: 7.5)),
                ),
              pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.productName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      if (item.imei.isNotEmpty)
                        pw.Text('IMEI: ${item.imei}', style: const pw.TextStyle(fontSize: 6.5)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${item.quantity} x ${AppFormatters.currency(item.unitPrice)}', style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Text(AppFormatters.currency(item.total), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
              _thermalSummaryRow('Total:', AppFormatters.currency(sale.subtotal)),
              if (sale.discount > 0)
                _thermalSummaryRow('Discount:', '- ${AppFormatters.currency(sale.discount)}'),
              _thermalSummaryRow('Net Total:', AppFormatters.currency(sale.grandTotal), isBold: true),
              _thermalSummaryRow('Paid (${sale.paymentMethod}):', AppFormatters.currency(sale.paidAmount)),
              if (sale.dueAmount > 0)
                _thermalSummaryRow('Due Balance:', AppFormatters.currency(sale.dueAmount), isBold: true),
              pw.SizedBox(height: 6),
              pw.Text('Thank you for your visit!', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
              pw.Text('Software by Antigravity POS', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${sale.invoiceNumber}.pdf',
    );
  }

  // Repair Job Card
  static Future<void> printRepairJobCard({
    required RepairJob job,
    required BusinessSettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.shopName,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                      pw.Text('Mobile Repairing & Chip-Level Hardware Lab', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Hafeez Centre Lahore | Tel: ${settings.phone}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.red400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('REPAIR JOB CARD', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Job ID: #${job.jobId}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Received: ${AppFormatters.dateTime(job.createdAt)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Status: ${job.status.displayName}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // Customer & Device Information Cards
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Name: ${job.customerName}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Phone: ${job.customerPhone}', style: const pw.TextStyle(fontSize: 9)),
                          if (job.customerAltPhone.isNotEmpty)
                            pw.Text('Alt Phone: ${job.customerAltPhone}', style: const pw.TextStyle(fontSize: 9)),
                          if (job.customerAddress.isNotEmpty)
                            pw.Text('Address: ${job.customerAddress}', style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DEVICE DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Model: ${job.deviceBrand} ${job.deviceModel}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          if (job.imei.isNotEmpty)
                            pw.Text('IMEI / Serial: ${job.imei}', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Color: ${job.color.isNotEmpty ? job.color : "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Physical Condition: ${job.deviceCondition}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Fault & Accessories Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.amber300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('REPORTED FAULT / PROBLEM:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.SizedBox(height: 2),
                    pw.Text(job.reportedProblem, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Accessories Received: ${job.accessoriesReceived}', style: const pw.TextStyle(fontSize: 8.5)),
                        ),
                        pw.Expanded(
                          child: pw.Text('Assigned Technician: ${job.technicianName}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue900)),
                        ),
                      ],
                    ),
                    if (job.technicianNotes.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Technician Notes: ${job.technicianNotes}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Financial Breakdown & Estimates
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LAB TERMS & DISCLAIMER', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('1. Original Job Card receipt must be produced when collecting the device.', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('2. Lab is not responsible for existing data loss. Customers must backup before submission.', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('3. Devices not collected within 45 days will be disposed of to recover service costs.', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('4. 15-day service warranty applies strictly to replaced parts only.', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        _summaryRow('Estimated Cost:', AppFormatters.currency(job.estimatedCost)),
                        if (job.laborCharges > 0)
                          _summaryRow('Labor Charges:', AppFormatters.currency(job.laborCharges)),
                        if (job.partsTotalSelling > 0)
                          _summaryRow('Parts Cost:', AppFormatters.currency(job.partsTotalSelling)),
                        if (job.discount > 0)
                          _summaryRow('Discount:', '- ${AppFormatters.currency(job.discount)}', color: PdfColors.red700),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        _summaryRow('Final Amount:', AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost), isBold: true),
                        _summaryRow('Advance Received:', AppFormatters.currency(job.advancePaid), color: PdfColors.green800),
                        _summaryRow('Balance Due:', AppFormatters.currency(job.remainingDue), isBold: true, color: PdfColors.red800),
                        pw.SizedBox(height: 4),
                        pw.Text('Expected: ${AppFormatters.date(job.expectedDeliveryDate)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Lab Technician Stamp & Sign', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'JobCard_${job.jobId}.pdf',
    );
  }

  // Payment Receipt
  static Future<void> printPaymentReceipt({
    required PaymentRecord payment,
    required BusinessSettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(settings.shopName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('RECEIPT: #${payment.receiptNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Contact: ${settings.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              _receiptRow('Received From / Paid To:', payment.entityName),
              _receiptRow('Type of Payment:', payment.typeDisplayName),
              _receiptRow('Reference / Invoice #:', payment.referenceId.isNotEmpty ? payment.referenceId : '-'),
              _receiptRow('Payment Date:', AppFormatters.dateTime(payment.paymentDate)),
              _receiptRow('Payment Method:', payment.paymentMethod),
              if (payment.notes.isNotEmpty)
                _receiptRow('Notes / Narration:', payment.notes),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('AMOUNT RECEIVED:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(AppFormatters.currency(payment.amount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Collected By: ${payment.collectedBy}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 3),
                      pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PaymentReceipt_${payment.receiptNumber}.pdf',
    );
  }

  // Helpers
  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _thermalSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static pw.Widget _receiptRow(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(val, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }
}
