import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/hostel_settings_model.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';

class PdfService {
  static Future<pw.ThemeData> _getPdfTheme() async {
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      final italicFont = await PdfGoogleFonts.robotoItalic();
      return pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
        italic: italicFont,
        boldItalic: boldFont,
      );
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  /// Generate A4 Receipt PDF
  static Future<Uint8List> generateReceiptPdfA4({
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
  }) async {
    final theme = await _getPdfTheme();
    final pdf = pw.Document(theme: theme);

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_square.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 52,
                            height: 52,
                            margin: const pw.EdgeInsets.only(right: 14),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              settings.hostelName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(settings.address, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                            pw.Text('Phone: ${settings.phone} | Email: ${settings.email}',
                                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'RENT PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.blueGrey300),
                pw.SizedBox(height: 12),

                // Receipt No & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: ${receipt.receiptNumber}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900)),
                    pw.Text('Date: ${DateFormatter.formatDate(DateTime.tryParse(receipt.paymentDate))}',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Student Details Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Student Name:', receipt.studentName ?? '-'),
                            _buildInfoRow('Student ID:', receipt.studentIdCode ?? '-'),
                            _buildInfoRow('Phone:', receipt.studentPhone ?? '-'),
                            _buildInfoRow('Security Deposit:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.securityDeposit ?? 0.0)}'),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Room No:', receipt.roomNumber ?? '-'),
                            _buildInfoRow('Bed No:', receipt.bedNumber ?? '-'),
                            _buildInfoRow('Rent Month:', DateFormatter.formatMonthYearString(receipt.rentMonth)),
                            _buildInfoRow('Monthly Rent:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.rentAmount ?? 0.0)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Payment Breakdown Table
                () {
                  final secAmt = (receipt.securityDeposit != null && receipt.securityDeposit! > 0)
                      ? receipt.securityDeposit!
                      : 0.0;
                  final rentPortion = receipt.amountPaid >= secAmt ? (receipt.amountPaid - secAmt) : receipt.amountPaid;

                  return pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                        children: [
                          _buildTableHeader('Description'),
                          _buildTableHeader('Rent Month'),
                          _buildTableHeader('Payment Method'),
                          _buildTableHeader('Amount Paid (${settings.currency})', align: pw.TextAlign.right),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildTableCell('Hostel Monthly Room & Bed Rent'),
                          _buildTableCell(DateFormatter.formatMonthYearString(receipt.rentMonth)),
                          _buildTableCell(receipt.paymentMethod),
                          _buildTableCell(CurrencyFormatter.formatPlain(rentPortion), align: pw.TextAlign.right),
                        ],
                      ),
                      if (secAmt > 0)
                        pw.TableRow(
                          children: [
                            _buildTableCell('Security Deposit (Refundable)'),
                            _buildTableCell(DateFormatter.formatMonthYearString(receipt.rentMonth)),
                            _buildTableCell(receipt.paymentMethod),
                            _buildTableCell(CurrencyFormatter.formatPlain(secAmt), align: pw.TextAlign.right),
                          ],
                        ),
                    ],
                  );
                }(),
                pw.SizedBox(height: 16),

                // Totals & Balance
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 260,
                      child: pw.Column(
                        children: [
                          () {
                            final secAmt = (receipt.securityDeposit != null && receipt.securityDeposit! > 0)
                                ? receipt.securityDeposit!
                                : 0.0;
                            final rentPortion = receipt.amountPaid >= secAmt ? (receipt.amountPaid - secAmt) : receipt.amountPaid;

                            if (secAmt > 0) {
                              return pw.Column(
                                children: [
                                  _buildSummaryRow('Rent Amount:', '${settings.currency} ${CurrencyFormatter.formatPlain(rentPortion)}'),
                                  pw.Divider(color: PdfColors.grey300),
                                  _buildSummaryRow('Security Deposit:', '${settings.currency} ${CurrencyFormatter.formatPlain(secAmt)}'),
                                  pw.Divider(color: PdfColors.grey300),
                                  _buildSummaryRow('Total Paid:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.amountPaid)}', isBold: true),
                                ],
                              );
                            } else {
                              return _buildSummaryRow('Amount Paid:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.amountPaid)}', isBold: true);
                            }
                          }(),
                          pw.Divider(color: PdfColors.grey300),
                          _buildSummaryRow('Remaining Due:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.remainingAmount)}',
                              isHighlight: receipt.remainingAmount > 0),
                          pw.Divider(color: PdfColors.grey300),
                          _buildSummaryRow('Security Balance:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.securityDeposit ?? 0.0)}'),
                          pw.Divider(color: PdfColors.grey300),
                          _buildSummaryRow('Status:', receipt.remainingAmount <= 0 ? 'FULLY PAID' : 'PARTIAL PAYMENT',
                              color: receipt.remainingAmount <= 0 ? PdfColors.green800 : PdfColors.amber800),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Signatures & Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 140, child: pw.Divider(color: PdfColors.grey600)),
                        pw.Text('Student Signature', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 160, child: pw.Divider(color: PdfColors.grey600)),
                        pw.Text('Authorized Signature (${settings.authorizedPerson})',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Center(
                  child: pw.Text(
                    settings.receiptFooter,
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'Software Developed by Devnix Limited • Contact: 03007720839',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate Thermal 80mm Receipt PDF
  static Future<Uint8List> generateReceiptPdfThermal({
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
  }) async {
    final theme = await _getPdfTheme();
    final pdf = pw.Document(theme: theme);

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_square.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    const thermalFormat = PdfPageFormat(
      72 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: thermalFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  width: 42,
                  height: 42,
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ],
              pw.Text(settings.hostelName.toUpperCase(),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              pw.Text('Phone: ${settings.phone}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('RENT PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildThermalRow('Receipt No:', receipt.receiptNumber),
                    _buildThermalRow('Date:', DateFormatter.formatDate(DateTime.tryParse(receipt.paymentDate))),
                    _buildThermalRow('Student:', receipt.studentName ?? '-'),
                    _buildThermalRow('ID:', receipt.studentIdCode ?? '-'),
                    _buildThermalRow('Room / Bed:', '${receipt.roomNumber ?? '-'} / ${receipt.bedNumber ?? '-'}'),
                    _buildThermalRow('Rent Month:', DateFormatter.formatMonthYearString(receipt.rentMonth)),
                    _buildThermalRow('Method:', receipt.paymentMethod),
                    () {
                      final secAmt = (receipt.securityDeposit != null && receipt.securityDeposit! > 0)
                          ? receipt.securityDeposit!
                          : 0.0;
                      final rentPortion = receipt.amountPaid >= secAmt ? (receipt.amountPaid - secAmt) : receipt.amountPaid;

                      if (secAmt > 0) {
                        return pw.Column(
                          children: [
                            pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                            _buildThermalRow('Rent Portion:', '${settings.currency} ${CurrencyFormatter.formatPlain(rentPortion)}'),
                            _buildThermalRow('Security Deposit:', '${settings.currency} ${CurrencyFormatter.formatPlain(secAmt)}'),
                            pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                            _buildThermalRow('Total Paid:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.amountPaid)}', isBold: true),
                          ],
                        );
                      } else {
                        return pw.Column(
                          children: [
                            _buildThermalRow('Security Balance:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.securityDeposit ?? 0.0)}'),
                            pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                            _buildThermalRow('Paid Amount:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.amountPaid)}', isBold: true),
                          ],
                        );
                      }
                    }(),
                    _buildThermalRow('Remaining:', '${settings.currency} ${CurrencyFormatter.formatPlain(receipt.remainingAmount)}'),
                    _buildThermalRow('Status:', receipt.remainingAmount <= 0 ? 'PAID' : 'PARTIAL'),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('----------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 12),
              pw.Text('Authorized Signature: ______________', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Text(settings.receiptFooter, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text(
                'Powered by Devnix Limited | 03007720839',
                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Share PDF
  static Future<void> printOrPreview(Uint8List pdfBytes, {String name = 'Document'}) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: name,
    );
  }

  // PDF Table / Helper Components
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isHighlight = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (isHighlight ? PdfColors.red800 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
