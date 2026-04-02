import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/task_model.dart';

class ExportService {
  static Future<String> tasksToCSV(List<TaskModel> tasks) async {
    final rows = [
      ['ID', 'Title', 'Description', 'DueDate', 'Completed', 'RepeatType', 'RepeatDays', 'Progress']
    ];
    for (final t in tasks) {
      rows.add([
        t.id?.toString() ?? '',
        t.title,
        t.description,
        t.dueDate.toIso8601String(),
        t.isCompleted ? 'Yes' : 'No',
        t.repeatType,
        t.repeatDays?.join(',') ?? '',

        (t.progress * 100).toStringAsFixed(0)
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    if (kIsWeb) {
      final blob = html.Blob([csv]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'tasks.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'web';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/tasks_export.csv';
      final file = File(path);
      await file.writeAsString(csv);
      return path;
    }
  }

  static Future<String> tasksToPdf(List<TaskModel> tasks) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(build: (context) {
      return [
        pw.Header(level: 0, child: pw.Text('Tasks Export')),
        pw.Table.fromTextArray(
          context: context,
          headers: ['ID', 'Title', 'Due', 'Completed', 'Progress'],
          data: tasks
              .map((t) => [t.id?.toString() ?? '', t.title, t.dueDate.toIso8601String(), t.isCompleted ? 'Yes' : 'No', '${(t.progress * 100).toStringAsFixed(0)}%'])
              .toList(),
        )
      ];
    }));
    final bytes = await pdf.save();
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'tasks.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'web';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/tasks_export.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }
  }

  static Future<void> shareFile(String path) async {
    if (kIsWeb || path == 'web') return;
    await Share.shareXFiles([XFile(path)], text: 'My tasks export');
  }
}
