import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/formatters.dart';
import '../../data/models/business_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/job_model.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/salary_model.dart';

class PdfService {
  // -------------------------------------------------------------
  // INVOICE & RECEIPT PDF
  // -------------------------------------------------------------
  static Future<void> printInvoice({
    required BusinessModel business,
    required InvoiceModel invoice,
  }) async {
    final doc = pw.Document();

    doc.addPage(
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
                        business.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(business.address, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Phone: ${business.phone} | Email: ${business.email}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('Date: ${Formatters.date(invoice.createdAt)}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Status: ${invoice.status}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.status == 'Paid' ? PdfColors.green700 : PdfColors.amber800,
                          )),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Customer & Vehicle Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.customerAddress != null && invoice.customerAddress!.isNotEmpty)
                        pw.Text('Address: ${invoice.customerAddress}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  if (invoice.vehicleRegNumber != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('VEHICLE DETAILS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(invoice.vehicleDisplayName ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Plate #: ${invoice.vehicleRegNumber}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.jobId != null)
                          pw.Text('Job Ref: ${invoice.jobId}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.type.toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.quantity.toStringAsFixed(1), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(Formatters.currency(item.unitPrice, symbol: business.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(Formatters.currency(item.total, symbol: business.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              // Summary & Balances
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Method: ${invoice.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.notes != null && invoice.notes!.isNotEmpty)
                        pw.Text('Notes: ${invoice.notes}', style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.terms != null && invoice.terms!.isNotEmpty)
                        pw.Text('Terms: ${invoice.terms}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Subtotal:', Formatters.currency(invoice.subtotal, symbol: business.currency)),
                        if (invoice.discount > 0)
                          _buildSummaryRow('Discount:', '-${Formatters.currency(invoice.discount, symbol: business.currency)}'),
                        if (invoice.tax > 0)
                          _buildSummaryRow('Tax:', Formatters.currency(invoice.tax, symbol: business.currency)),
                        pw.Divider(color: PdfColors.grey400),
                        _buildSummaryRow('Grand Total:', Formatters.currency(invoice.grandTotal, symbol: business.currency), isBold: true),
                        _buildSummaryRow('Paid Amount:', Formatters.currency(invoice.paidAmount, symbol: business.currency)),
                        _buildSummaryRow('Remaining:', Formatters.currency(invoice.remainingAmount, symbol: business.currency), isBold: true, color: PdfColors.red800),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for choosing ${business.name}!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                  pw.Text('Authorized Signature: _______________________', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  // -------------------------------------------------------------
  // JOB CARD PDF
  // -------------------------------------------------------------
  static Future<void> printJobCard({
    required BusinessModel business,
    required JobModel job,
  }) async {
    pw.MemoryImage? custSigImage;
    if (job.customerSignature != null && job.customerSignature!.isNotEmpty && File(job.customerSignature!).existsSync()) {
      try {
        custSigImage = pw.MemoryImage(File(job.customerSignature!).readAsBytesSync());
      } catch (_) {}
    }
    pw.MemoryImage? advSigImage;
    if (job.serviceAdvisorSignature != null && job.serviceAdvisorSignature!.isNotEmpty && File(job.serviceAdvisorSignature!).existsSync()) {
      try {
        advSigImage = pw.MemoryImage(File(job.serviceAdvisorSignature!).readAsBytesSync());
      } catch (_) {}
    }
    pw.MemoryImage? authSigImage;
    if (job.authorizedSignature != null && job.authorizedSignature!.isNotEmpty && File(job.authorizedSignature!).existsSync()) {
      try {
        authSigImage = pw.MemoryImage(File(job.authorizedSignature!).readAsBytesSync());
      } catch (_) {}
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.name,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(business.address, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Phone: ${business.phone} | Email: ${business.email}', style: const pw.TextStyle(fontSize: 9)),
                    if (business.whatsapp != null && business.whatsapp!.isNotEmpty)
                      pw.Text('WhatsApp: ${business.whatsapp}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'DIGITAL JOB CARD / REPAIR ORDER',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Job #: ${job.jobNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Date: ${Formatters.date(job.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Status: ${job.status.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey400),
            pw.SizedBox(height: 8),

            // Customer & Vehicle Information Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text('Name: ${job.customerName}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Phone: ${job.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('VEHICLE DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text('Vehicle: ${job.vehicleDisplayName}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Reg Plate: ${job.vehicleRegNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Services / Operations Table
            pw.Text('SERVICES & WORK REQUESTED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Service / Task Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                ...job.services.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(s.serviceName, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(Formatters.currency(s.price, symbol: business.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),

            // Financial Summary & Assigned Personnel
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (job.assignedStaffNames.isNotEmpty) ...[
                      pw.Text('ASSIGNED TECHNICIAN(S):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text(job.assignedStaffNames.join(', '), style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 8),
                    ],
                    if (job.notes != null && job.notes!.isNotEmpty) ...[
                      pw.Text('INSTRUCTIONS & SPECIFIC INFO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        width: 260,
                        child: pw.Text(job.notes!, style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _buildSummaryRow('Services Total:', Formatters.currency(job.subtotal, symbol: business.currency)),
                      if (job.discount > 0)
                        _buildSummaryRow('Discount:', '-${Formatters.currency(job.discount, symbol: business.currency)}'),
                      pw.Divider(color: PdfColors.grey400),
                      _buildSummaryRow('Grand Total:', Formatters.currency(job.grandTotal, symbol: business.currency), isBold: true),
                      _buildSummaryRow('Advance / Paid:', Formatters.currency(job.paidAmount, symbol: business.currency)),
                      _buildSummaryRow('Balance Due:', Formatters.currency(job.remainingAmount, symbol: business.currency), isBold: true, color: job.remainingAmount > 0 ? PdfColors.red800 : PdfColors.green800),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Signatures
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    if (custSigImage != null)
                      pw.Container(height: 35, width: 120, child: pw.Image(custSigImage, fit: pw.BoxFit.contain))
                    else
                      pw.SizedBox(height: 35),
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    if (advSigImage != null)
                      pw.Container(height: 35, width: 120, child: pw.Image(advSigImage, fit: pw.BoxFit.contain))
                    else
                      pw.SizedBox(height: 35),
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Service Advisor', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    if (authSigImage != null)
                      pw.Container(height: 35, width: 120, child: pw.Image(authSigImage, fit: pw.BoxFit.contain))
                    else
                      pw.SizedBox(height: 35),
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'JobCard_${job.jobNumber}.pdf',
    );
  }

  // -------------------------------------------------------------
  // SALARY SLIP PDF
  // -------------------------------------------------------------
  static Future<void> printSalarySlip({
    required BusinessModel business,
    required SalaryModel salary,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(business.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('STAFF SALARY SLIP - ${salary.month}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Staff Member: ${salary.staffName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('Attendance: ${salary.presentDays} Present | ${salary.absentDays} Absent | ${salary.halfDays} Half-day', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Earnings / Allowances', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Deductions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Basic Salary')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.currency(salary.basicSalary, symbol: business.currency), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Advances')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.currency(salary.advanceDeduction, symbol: business.currency), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Overtime')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.currency(salary.overtimeAmount, symbol: business.currency), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Other Deductions')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.currency(salary.otherDeduction, symbol: business.currency), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Bonus / Commissions')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.currency(salary.bonusAmount + salary.commissionAmount, symbol: business.currency), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Gross Salary:', Formatters.currency(salary.grossSalary, symbol: business.currency)),
                        _buildSummaryRow('Net Salary Payable:', Formatters.currency(salary.netSalary, symbol: business.currency), isBold: true),
                        _buildSummaryRow('Amount Disbursed:', Formatters.currency(salary.paidAmount, symbol: business.currency)),
                        _buildSummaryRow('Balance Due:', Formatters.currency(salary.remainingAmount, symbol: business.currency), isBold: true, color: PdfColors.red800),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Staff Signature: _________________', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Management Signature: _________________', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'SalarySlip_${salary.staffName}_${salary.month}.pdf',
    );
  }

  // -------------------------------------------------------------
  // VEHICLE INSPECTION REPORT PDF (5-VIEW & ALL SECTIONS)
  // -------------------------------------------------------------
  static Future<void> printInspectionReport({
    required BusinessModel business,
    required InspectionModel inspection,
    required String vehicleReg,
    required String vehicleName,
    required String customerName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Business & Inspection Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.name,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(business.address, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Phone: ${business.phone} | Email: ${business.email}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'VEHICLE INSPECTION REPORT',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ${Formatters.date(inspection.inspectionDate)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Inspector: ${inspection.inspectorStaffName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey400),
            pw.SizedBox(height: 6),

            // Vehicle & Customer Info Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Vehicle: $vehicleName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Plate: $vehicleReg', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 1. Interactive Diagram Parts Inspection
            if (inspection.diagramParts.isNotEmpty) ...[
              pw.Text(
                '1. VEHICLE DIAGRAM PARTS INSPECTION (5 VIEWS & BODY)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Part Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('View', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Condition', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Damage & Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                    ],
                  ),
                  ...inspection.diagramParts.map((part) {
                    final isDamaged = part.hasDamage ||
                        (part.damageDescription != null && part.damageDescription!.isNotEmpty);
                    final textColor = isDamaged ? PdfColors.red800 : PdfColors.green800;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(part.partName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(part.view, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(part.condition, style: pw.TextStyle(fontSize: 8, color: textColor, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            [
                              if (part.damageDescription != null && part.damageDescription!.isNotEmpty)
                                part.damageDescription!,
                              if (part.notes != null && part.notes!.isNotEmpty) part.notes!,
                            ].join(' | '),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 2. Sections Inspection (Exterior, Interior, Engine, Tires, Suspension, etc.)
            if (inspection.sectionConditions.isNotEmpty) ...[
              pw.Text(
                '2. DETAILED SYSTEMS & SECTIONS CONDITION',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 4),
              _buildAreaConditionsGrid(inspection.sectionConditions),
              pw.SizedBox(height: 12),
            ],

            // 3. Drive & Mechanical Condition
            if (inspection.driveCondition.isNotEmpty) ...[
              pw.Text(
                '3. DRIVE & MECHANICAL PERFORMANCE',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 4),
              _buildAreaConditionsGrid(inspection.driveCondition),
              pw.SizedBox(height: 12),
            ],

            // 4. Vehicle Belongings & Checklist
            if (inspection.checklist.isNotEmpty) ...[
              pw.Text(
                '4. VEHICLE BELONGINGS & INVENTORY CHECKLIST',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 10,
                runSpacing: 4,
                children: inspection.checklist.map((item) {
                  PdfColor statusColor = PdfColors.green800;
                  if (item.status == 'Missing') statusColor = PdfColors.red800;
                  if (item.status == 'Damaged') statusColor = PdfColors.amber900;

                  return pw.Container(
                    width: 170,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(item.item, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(item.status, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: statusColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // Remarks
            if (inspection.staffRemarks != null && inspection.staffRemarks!.isNotEmpty) ...[
              pw.Text('Staff / Inspector Remarks:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(inspection.staffRemarks!, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
            ],
            if (inspection.customerRemarks != null && inspection.customerRemarks!.isNotEmpty) ...[
              pw.Text('Customer Remarks:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(inspection.customerRemarks!, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
            ],

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Signatures Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Customer Sign-off', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Inspector Signature', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey700)),
                    pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Inspection_$vehicleReg.pdf',
    );
  }

  static pw.Widget _buildAreaConditionsGrid(Map<String, String> conditions) {
    final entries = conditions.entries.toList();
    return pw.Wrap(
      spacing: 12,
      runSpacing: 4,
      children: entries.map((e) {
        PdfColor color = PdfColors.green800;
        final valLower = e.value.toLowerCase();
        if (valLower.contains('damage') ||
            valLower.contains('dent') ||
            valLower.contains('scratch') ||
            valLower.contains('broken') ||
            valLower.contains('crack') ||
            valLower.contains('leak') ||
            valLower.contains('fault') ||
            valLower.contains('fail')) {
          color = PdfColors.red800;
        } else if (valLower.contains('attention') ||
            valLower.contains('wear') ||
            valLower.contains('average') ||
            valLower.contains('fair')) {
          color = PdfColors.amber900;
        }

        return pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(e.value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10, color: color)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // GENERIC TABULAR REPORT PDF & PRINTING
  // -------------------------------------------------------------
  static Future<void> printReportTable({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    String? subtitle,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              if (subtitle != null) pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }
}
