import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {
  /// Export tabular data to an Excel file with header, styling, and metadata
  static Future<String?> exportToExcel({
    required String fileNamePrefix,
    required String sheetTitle,
    required String dateRangeText,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = sheetTitle.replaceAll(RegExp(r'[\\/?*\[\]]'), '').trim();
    final sheet = excel[sheetName.isNotEmpty ? sheetName : 'Sheet1'];
    excel.setDefaultSheet(sheetName.isNotEmpty ? sheetName : 'Sheet1');

    // Title Row
    sheet.appendRow([TextCellValue(sheetTitle)]);
    // Date Range Row
    sheet.appendRow([TextCellValue('Report Period: $dateRangeText')]);
    // Blank line
    sheet.appendRow([]);

    // Header Row
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data Rows
    for (final row in rows) {
      final List<CellValue?> cellValues = row.map((val) {
        if (val == null) return TextCellValue('-');
        if (val is int) {
          return IntCellValue(val);
        } else if (val is double) {
          return DoubleCellValue(val);
        }
        return TextCellValue(val.toString());
      }).toList();
      sheet.appendRow(cellValues);
    }

    // Save File using Desktop FilePicker save dialog
    final String defaultFileName = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final resultPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel Report',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (resultPath != null) {
      String finalPath = resultPath;
      if (!finalPath.toLowerCase().endsWith('.xlsx')) {
        finalPath = '$finalPath.xlsx';
      }
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(finalPath);
        await file.writeAsBytes(fileBytes);
        return finalPath;
      }
    }
    return null;
  }
}
