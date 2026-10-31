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
  // JOB CARD / REPAIR ORDER / INVOICE PDF (MATCHING MANUAL PHYSICAL SHEET)
  // -------------------------------------------------------------
  static Future<void> printJobCard({
    required BusinessModel business,
    required JobModel job,
    String? customerName,
    String? companyName,
    String? contactNumber,
    String? currentAddress,
    String? regNo,
    String? vehicleModel,
    String? variant,
    String? modelYear,
    String? chassisNo,
    String? odometerIn,
    String? odometerOut,
    String? fuelGauge,
    List<String>? selectedServiceTypes,
    DateTime? receivingDate,
    DateTime? deliveryDate,
    String? paymentMode,
    String? specificInfo,
    List<Map<String, dynamic>>? damageChecklist,
    String? customerAuthSignature,
    String? customerDeliverySignature,
    String? serviceAdvisorSignature,
    String? authorizedSignature,
    double? serviceLabour,
    double? partsTotal,
    double? discount,
    double? grandTotal,
  }) async {
    final custAuthPath = customerAuthSignature ?? job.customerSignature;
    pw.MemoryImage? custAuthSigImage;
    if (custAuthPath != null && custAuthPath.isNotEmpty && File(custAuthPath).existsSync()) {
      try {
        custAuthSigImage = pw.MemoryImage(File(custAuthPath).readAsBytesSync());
      } catch (_) {}
    }

    final custDelivPath = customerDeliverySignature ?? job.customerSignature;
    pw.MemoryImage? custDelivSigImage;
    if (custDelivPath != null && custDelivPath.isNotEmpty && File(custDelivPath).existsSync()) {
      try {
        custDelivSigImage = pw.MemoryImage(File(custDelivPath).readAsBytesSync());
      } catch (_) {}
    }

    final advPath = serviceAdvisorSignature ?? job.serviceAdvisorSignature;
    pw.MemoryImage? advSigImage;
    if (advPath != null && advPath.isNotEmpty && File(advPath).existsSync()) {
      try {
        advSigImage = pw.MemoryImage(File(advPath).readAsBytesSync());
      } catch (_) {}
    }

    final authPath = authorizedSignature ?? job.authorizedSignature;
    pw.MemoryImage? authSigImage;
    if (authPath != null && authPath.isNotEmpty && File(authPath).existsSync()) {
      try {
        authSigImage = pw.MemoryImage(File(authPath).readAsBytesSync());
      } catch (_) {}
    }

    final effectiveCustName = customerName ?? job.customerName;
    final effectivePhone = contactNumber ?? job.customerPhone;
    final effectiveReg = regNo ?? job.vehicleRegNumber;
    final effectiveModel = vehicleModel ?? job.vehicleDisplayName;
    final effectiveVariant = variant ?? '';
    final effectiveYear = modelYear ?? '';
    final effectiveChassis = chassisNo ?? '';
    final effectiveOdoIn = odometerIn ?? '';
    final effectiveOdoOut = odometerOut ?? '';
    final effectiveFuel = fuelGauge ?? '1/2';
    final effectivePayment = paymentMode ?? 'Cash';
    final effectiveSpecific = specificInfo ?? job.notes ?? '';
    final effectiveLabour = serviceLabour ?? job.subtotal;
    final effectiveParts = partsTotal ?? 0.0;
    final effectiveDiscount = discount ?? job.discount;
    final effectiveGrandTotal = grandTotal ?? job.grandTotal;

    final defaultChecklistItems = [
      'Battery Code',
      'EVB/CR/USB',
      'CIG-LIGHTER',
      'ASHTRAY',
      'RADIO ANTENA',
      'FLOOR MATS',
      'WIPER BLADES',
      'MONOGRAMS',
      'WHEEL CAPS',
      'SPARE WHEEL',
      'SEAT COVERS',
      'LCD WORKING',
      'BACK CAMERA',
      'FRONT CAMERA',
      'JACK & WHEEL BRACE',
      'TOOLS',
      'NAVIGATION CARD',
      'Others',
    ];

    final effectiveTypes = selectedServiceTypes ?? ['PPF', 'Detailing'];

    final doc = pw.Document();

    final greenColor = PdfColor.fromHex('#0A6836');
    final lightGreenBg = PdfColor.fromHex('#F0F7F2');
    final borderColor = PdfColor.fromHex('#0A6836');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. TOP HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo block
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: greenColor, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text("Dawood's", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor, fontStyle: pw.FontStyle.italic)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          color: greenColor,
                          child: pw.Text('GARAGE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.2)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Detailing & Performance', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: greenColor)),
                      ],
                    ),
                  ),

                  // Center Titles
                  pw.Column(
                    children: [
                      pw.Text(business.name.toUpperCase(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: greenColor)),
                      pw.Text('DETAIL & PERFORMANCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: greenColor, letterSpacing: 1)),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: greenColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'REPAIR ORDER / INVOICE',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ),

                  // Right info box (R.O #, Date, Tech)
                  pw.Container(
                    width: 130,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1),
                    ),
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderColor, width: 0.5),
                      children: [
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text('R.O #', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text(job.jobNumber, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text('Date', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text(Formatters.date(job.createdAt), style: const pw.TextStyle(fontSize: 7.5))),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text('Tech', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text(job.assignedStaffNames.isNotEmpty ? job.assignedStaffNames.first : 'Lead Tech', style: const pw.TextStyle(fontSize: 7.5))),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              // 2. THREE COLUMN INFORMATION GRID
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 1)),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Col 1: Customer Information
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderColor, width: 1))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Center(child: pw.Text('Customer Information', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: greenColor))),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 4),
                            _buildInfoField('Customer Name:', effectiveCustName),
                            _buildInfoField('Company Name:', companyName ?? '-'),
                            _buildInfoField('Contact Number:', effectivePhone),
                            _buildInfoField('Current Address:', currentAddress ?? '-'),
                          ],
                        ),
                      ),
                    ),

                    // Col 2: Vehicle Information
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderColor, width: 1))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Center(child: pw.Text('Vehicle Information', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: greenColor))),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 4),
                            _buildInfoField('Reg. #:', effectiveReg, isBoldVal: true),
                            _buildInfoField('Model:', effectiveModel),
                            _buildInfoField('Varient:', effectiveVariant.isNotEmpty ? effectiveVariant : '-'),
                            _buildInfoField('Model Year:', effectiveYear.isNotEmpty ? effectiveYear : '-'),
                            _buildInfoField('Chassis #:', effectiveChassis.isNotEmpty ? effectiveChassis : '-'),
                            _buildInfoField('Odometer In:', effectiveOdoIn.isNotEmpty ? effectiveOdoIn : '-'),
                            _buildInfoField('Odometer Out:', effectiveOdoOut.isNotEmpty ? effectiveOdoOut : '-'),
                            // Fuel Gauge
                            pw.Row(
                              children: [
                                pw.Text('Fuel gauge:  ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: greenColor)),
                                pw.Text('E ', style: const pw.TextStyle(fontSize: 7)),
                                _buildCheckboxBox(effectiveFuel == 'E' || effectiveFuel == '1/4'),
                                _buildCheckboxBox(effectiveFuel == '1/4' || effectiveFuel == '1/2'),
                                _buildCheckboxBox(effectiveFuel == '1/2' || effectiveFuel == '3/4'),
                                _buildCheckboxBox(effectiveFuel == '3/4' || effectiveFuel == 'F'),
                                pw.Text(' F', style: const pw.TextStyle(fontSize: 7)),
                                pw.SizedBox(width: 4),
                                pw.Text('($effectiveFuel)', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Col 3: Service Information
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Center(child: pw.Text('Service Information', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: greenColor))),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 4),
                            pw.Text('Type of Service:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: greenColor)),
                            pw.SizedBox(height: 2),
                            pw.Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              children: ['PPF', 'Detailing', 'Wash', 'Tuning', 'Polish', 'Others'].map((st) {
                                final isSel = effectiveTypes.any((t) => t.toLowerCase() == st.toLowerCase());
                                return pw.Row(
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: [
                                    _buildCheckboxBox(isSel),
                                    pw.SizedBox(width: 2),
                                    pw.Text(st, style: const pw.TextStyle(fontSize: 6.5)),
                                  ],
                                );
                              }).toList(),
                            ),
                            pw.SizedBox(height: 3),
                            _buildInfoField('Receiving Date & Time:', Formatters.dateTime(receivingDate ?? job.createdAt)),
                            _buildInfoField('Promise/Delivery Date:', Formatters.dateTime(deliveryDate ?? job.createdAt.add(const Duration(hours: 4)))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. PAYMENT MODE & SPECIFIC INFORMATION
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 1),
                    right: pw.BorderSide(color: borderColor, width: 1),
                    bottom: pw.BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: pw.Row(
                  children: [
                    // Payment Mode
                    pw.Container(
                      width: 230,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderColor, width: 1))),
                      child: pw.Row(
                        children: [
                          pw.Text('Payment Mode: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                          pw.SizedBox(width: 3),
                          ...['Cash', 'BTC', 'Online', 'Others'].map((pm) {
                            final isSel = effectivePayment.toLowerCase().contains(pm.toLowerCase());
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 6),
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  _buildCheckboxBox(isSel),
                                  pw.SizedBox(width: 2),
                                  pw.Text(pm, style: const pw.TextStyle(fontSize: 6.5)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Specific Information
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        child: pw.Row(
                          children: [
                            pw.Text('Specific Info: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                            pw.Expanded(
                              child: pw.Text(
                                effectiveSpecific.isNotEmpty ? effectiveSpecific : 'Standard procedures applied.',
                                style: const pw.TextStyle(fontSize: 7),
                                maxLines: 1,
                                overflow: pw.TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt Text
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  '* Should any defects are detected in the inspection, indicate them with marks on the diagram.',
                  style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: greenColor, fontWeight: pw.FontWeight.bold),
                ),
              ),

              // 4. MIDDLE SECTION: SERVICES TABLE (LEFT) | 4-VIEW DIAGRAM (CENTER) | DAMAGE CHECKLIST (RIGHT)
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Services Table
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 1),
                        ),
                        child: pw.Column(
                          children: [
                            // Table header
                            pw.Container(
                              color: lightGreenBg,
                              padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
                              child: pw.Row(
                                children: [
                                  pw.Container(width: 20, child: pw.Text('Sr#', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                                  pw.Expanded(child: pw.Text('Description', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                                  pw.Container(width: 45, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor))),
                                ],
                              ),
                            ),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 1),
                            // Service rows
                            ...List.generate(7, (index) {
                              final hasService = index < job.services.length;
                              final s = hasService ? job.services[index] : null;
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.3)),
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Container(width: 20, child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 7))),
                                    pw.Expanded(child: pw.Text(s?.serviceName ?? '', style: const pw.TextStyle(fontSize: 7), maxLines: 1, overflow: pw.TextOverflow.clip)),
                                    pw.Container(
                                      width: 45,
                                      child: pw.Text(
                                        s != null ? Formatters.currency(s.price, symbol: '') : '',
                                        textAlign: pw.TextAlign.right,
                                        style: const pw.TextStyle(fontSize: 7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 4),

                    // Center Column: 4-Angle Vehicle Diagram
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 1),
                        ),
                        child: _buildPdfCarDiagram(greenColor, lightGreenBg),
                      ),
                    ),
                    pw.SizedBox(width: 4),

                    // Right Column: Check For Damage - Item Checklist
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Container(
                              color: lightGreenBg,
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Center(
                                child: pw.Text('Check For Damage\nItem Checklist', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                              ),
                            ),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 1),
                            // 18 Checklist rows
                            pw.Expanded(
                              child: pw.ListView.builder(
                                itemCount: defaultChecklistItems.length,
                                itemBuilder: (context, idx) {
                                  final itemTitle = defaultChecklistItems[idx];
                                  final itemMap = damageChecklist?.firstWhere(
                                    (m) => (m['item'] as String? ?? '').toLowerCase() == itemTitle.toLowerCase(),
                                    orElse: () => {'item': itemTitle, 'status': 'OK'},
                                  );
                                  final statusStr = itemMap?['status'] as String? ?? 'OK';
                                  final isPresent = statusStr == 'OK' || statusStr == 'Present' || statusStr == 'Checked';

                                  return pw.Container(
                                    height: 9.8,
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 2.5),
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.3)),
                                    ),
                                    child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Expanded(
                                          child: pw.Text(itemTitle, style: const pw.TextStyle(fontSize: 5.5), maxLines: 1),
                                        ),
                                        pw.Container(
                                          width: 8,
                                          height: 8,
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border.all(color: greenColor, width: 0.5),
                                            color: isPresent ? greenColor : null,
                                          ),
                                          child: isPresent
                                              ? pw.Center(child: pw.Text('v', style: pw.TextStyle(fontSize: 5, color: PdfColors.white, fontWeight: pw.FontWeight.bold)))
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // 5. BOTTOM SECTION: DISCLAIMERS & TOTALS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Disclaimers & Signatures
                  pw.Expanded(
                    flex: 8,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Authorisation clause
                          pw.Text(
                            "I hereby authorise the repair work set to be done along with necessary services and materials. I grant you and your employee permission to operate the vehicle in your premises. Any pre-existing faults are my responsibility. Dawood's Garage will not be responsible for any unforseen damage including accident, fire, theft or any other event beyond our control. All charges are to be paid before the delivery of the vehicle.",
                            style: const pw.TextStyle(fontSize: 5.2, height: 1.15),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Customer Signature:', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                              if (custAuthSigImage != null)
                                pw.Container(height: 18, width: 80, child: pw.Image(custAuthSigImage, fit: pw.BoxFit.contain))
                              else
                                pw.Container(width: 90, child: pw.Divider(color: greenColor, thickness: 0.5)),
                            ],
                          ),
                          pw.Divider(color: borderColor, thickness: 0.5, height: 4),

                          // Delivery clause
                          pw.Text(
                            "I am satisfied by all the jobs done on my car which are provided by Dawood's Garage. Now I have recieved the car with all my belongings.",
                            style: const pw.TextStyle(fontSize: 5.2, height: 1.15),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text('Customer Signature: ', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                                  if (custDelivSigImage != null)
                                    pw.Container(height: 16, width: 60, child: pw.Image(custDelivSigImage, fit: pw.BoxFit.contain))
                                  else
                                    pw.Container(width: 60, child: pw.Divider(color: greenColor, thickness: 0.5)),
                                ],
                              ),
                              pw.Row(
                                children: [
                                  pw.Text('Service Advisor: ', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                                  if (advSigImage != null)
                                    pw.Container(height: 16, width: 60, child: pw.Image(advSigImage, fit: pw.BoxFit.contain))
                                  else
                                    pw.Container(width: 60, child: pw.Divider(color: greenColor, thickness: 0.5)),
                                ],
                              ),
                              pw.Row(
                                children: [
                                  pw.Text('Authorized: ', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: greenColor)),
                                  if (authSigImage != null)
                                    pw.Container(height: 16, width: 60, child: pw.Image(authSigImage, fit: pw.BoxFit.contain))
                                  else
                                    pw.Container(width: 60, child: pw.Divider(color: greenColor, thickness: 0.5)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),

                  // Totals Table
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 1),
                      ),
                      child: pw.Table(
                        border: pw.TableBorder.all(color: borderColor, width: 0.5),
                        children: [
                          _buildTotalRow('Service Labour', Formatters.currency(effectiveLabour, symbol: business.currency), greenColor),
                          _buildTotalRow('Parts', Formatters.currency(effectiveParts, symbol: business.currency), greenColor),
                          _buildTotalRow('Discount', Formatters.currency(effectiveDiscount, symbol: business.currency), greenColor),
                          _buildTotalRow('Grand Total', Formatters.currency(effectiveGrandTotal, symbol: business.currency), greenColor, isBold: true, isFilled: true, lightGreenBg: lightGreenBg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // 6. FOOTER BANNER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 6,
                    height: 8,
                    decoration: pw.BoxDecoration(color: greenColor, shape: pw.BoxShape.circle),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    business.address,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: greenColor),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                color: greenColor,
                child: pw.Center(
                  child: pw.Text(
                    '${business.phone}  |  ${business.email}',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'JobCard_${job.jobNumber}.pdf',
    );
  }

  static pw.Widget _buildInfoField(String label, String value, {bool isBoldVal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800)),
          pw.SizedBox(width: 3),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 6.8, fontWeight: isBoldVal ? pw.FontWeight.bold : pw.FontWeight.normal),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckboxBox(bool checked) {
    return pw.Container(
      width: 7,
      height: 7,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
      ),
      child: checked
          ? pw.Center(child: pw.Text('x', style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold)))
          : null,
    );
  }

  static pw.TableRow _buildTotalRow(String title, String val, PdfColor greenColor, {bool isBold = false, bool isFilled = false, PdfColor? lightGreenBg}) {
    return pw.TableRow(
      decoration: isFilled ? pw.BoxDecoration(color: lightGreenBg) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
          child: pw.Text(title, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: greenColor)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
          child: pw.Text(val, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfCarDiagram(PdfColor color, PdfColor lightGreenBg) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Top View (Bird's eye)
        pw.Column(
          children: [
            pw.Text('TOP VIEW', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 1),
            pw.Container(
              width: 100,
              height: 48,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: color, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Container(
                    width: 20,
                    decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: color, width: 0.6))),
                    child: pw.Center(child: pw.Text('Hood', style: pw.TextStyle(fontSize: 5, color: color))),
                  ),
                  pw.Container(
                    width: 10,
                    decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: color, width: 0.6))),
                    child: pw.Center(child: pw.Text('Glass', style: pw.TextStyle(fontSize: 4, color: color))),
                  ),
                  pw.Expanded(
                    child: pw.Center(child: pw.Text('Roof', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: color))),
                  ),
                  pw.Container(
                    width: 10,
                    decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: color, width: 0.6))),
                    child: pw.Center(child: pw.Text('Glass', style: pw.TextStyle(fontSize: 4, color: color))),
                  ),
                  pw.Container(
                    width: 18,
                    decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: color, width: 0.6))),
                    child: pw.Center(child: pw.Text('Trunk', style: pw.TextStyle(fontSize: 5, color: color))),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 2. Front & Rear Views in a row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            // Front View
            pw.Column(
              children: [
                pw.Text('FRONT VIEW', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
                pw.Container(
                  width: 48,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: color, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Container(height: 8, width: 34, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5)), child: pw.Center(child: pw.Text('Glass', style: pw.TextStyle(fontSize: 4, color: color)))),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Container(width: 8, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5))),
                          pw.Container(width: 14, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5)), child: pw.Center(child: pw.Text('Grille', style: pw.TextStyle(fontSize: 3, color: color)))),
                          pw.Container(width: 8, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Rear View
            pw.Column(
              children: [
                pw.Text('REAR VIEW', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
                pw.Container(
                  width: 48,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: color, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Container(height: 8, width: 34, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5)), child: pw.Center(child: pw.Text('Glass', style: pw.TextStyle(fontSize: 4, color: color)))),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Container(width: 8, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5), color: PdfColors.grey300)),
                          pw.Container(width: 14, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5)), child: pw.Center(child: pw.Text('Trunk', style: pw.TextStyle(fontSize: 3, color: color)))),
                          pw.Container(width: 8, height: 6, decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.5), color: PdfColors.grey300)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3. Side View (Profile)
        pw.Column(
          children: [
            pw.Text('SIDE VIEW', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
            pw.Container(
              width: 105,
              height: 28,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: color, width: 0.8),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Stack(
                children: [
                  // Cabin Windows
                  pw.Positioned(
                    top: 2,
                    left: 22,
                    right: 22,
                    child: pw.Container(
                      height: 10,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: color, width: 0.5),
                        color: lightGreenBg,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Expanded(child: pw.Center(child: pw.Text('F-Door', style: pw.TextStyle(fontSize: 3.5, color: color)))),
                          pw.Container(width: 0.5, color: color),
                          pw.Expanded(child: pw.Center(child: pw.Text('R-Door', style: pw.TextStyle(fontSize: 3.5, color: color)))),
                        ],
                      ),
                    ),
                  ),
                  // Front wheel
                  pw.Positioned(
                    bottom: 0,
                    left: 16,
                    child: pw.Container(
                      width: 10,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: color, width: 0.8),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  // Rear wheel
                  pw.Positioned(
                    bottom: 0,
                    right: 16,
                    child: pw.Container(
                      width: 10,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: color, width: 0.8),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
            valLower.contains('fail') ||
            valLower.contains('worn') ||
            valLower.contains('missing') ||
            valLower.contains('repainted')) {
          color = PdfColors.red800;
        } else if (valLower.contains('attention') ||
            valLower.contains('swirl') ||
            valLower.contains('dusty') ||
            valLower.contains('fair') ||
            valLower.contains('stain') ||
            valLower.contains('low')) {
          color = PdfColors.amber900;
        }

        return pw.Container(
          width: 260,
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 100,
                child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
              ),
              pw.Expanded(
                child: pw.Text(
                  e.value,
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: color),
                ),
              ),
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
