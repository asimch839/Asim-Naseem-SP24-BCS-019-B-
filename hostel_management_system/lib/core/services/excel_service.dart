import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

    final fileBytes = excel.encode();
    if (fileBytes == null) return null;

    final String defaultFileName = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    String? finalPath;

    // Try Desktop file save dialog on Windows/macOS/Linux
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final resultPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel Report',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (resultPath != null) {
          finalPath = resultPath;
          if (!finalPath.toLowerCase().endsWith('.xlsx')) {
            finalPath = '$finalPath.xlsx';
          }
        } else {
          // User explicitly cancelled save dialog
          return null;
        }
      } catch (_) {
        finalPath = null;
      }
    }

    // Mobile fallback or Desktop fallback if path picking failed
    if (finalPath == null) {
      Directory dir;
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          dir = downloadsDir;
        } else {
          dir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = (await getDownloadsDirectory()) ?? (await getApplicationDocumentsDirectory());
      }
      finalPath = p.join(dir.path, defaultFileName);
    }

    final file = File(finalPath);
    await file.writeAsBytes(fileBytes);
    return finalPath;
  }
}
