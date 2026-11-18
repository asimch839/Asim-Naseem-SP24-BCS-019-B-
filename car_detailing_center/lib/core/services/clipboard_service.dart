import 'dart:io';
import 'package:flutter/services.dart';

class WindowsClipboardService {
  /// Copies an image file to the Windows Clipboard as a native Bitmap AND File Drop
  /// so pressing Ctrl+V in WhatsApp Web / Desktop, Telegram, or any chat immediately
  /// pastes the full A4 picture of the inspection report.
  static Future<bool> copyImageToClipboard(String imagePath, {String? pdfPath}) async {
    if (!Platform.isWindows) {
      // Non-Windows fallback (plain text path)
      await Clipboard.setData(ClipboardData(text: imagePath));
      return true;
    }

    final normalizedImg = File(imagePath).absolute.path.replaceAll('/', '\\').replaceAll("'", "''");
    final normalizedPdf = pdfPath != null && pdfPath.isNotEmpty
        ? File(pdfPath).absolute.path.replaceAll('/', '\\').replaceAll("'", "''")
        : '';

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$imgPath = '$normalizedImg'
\$pdfPath = '$normalizedPdf'

try {
    if (Test-Path \$imgPath) {
        \$img = [System.Drawing.Image]::FromFile(\$imgPath)
        \$do = New-Object System.Windows.Forms.DataObject
        \$do.SetImage(\$img)

        \$files = New-Object System.Collections.Specialized.StringCollection
        if (\$pdfPath -ne '' -and (Test-Path \$pdfPath)) {
            \$files.Add(\$pdfPath)
        } else if (Test-Path \$imgPath) {
            \$files.Add(\$imgPath)
        }
        \$do.SetFileDropList(\$files)
        [System.Windows.Forms.Clipboard]::SetDataObject(\$do, \$true)
        Write-Output "COPIED_SINGLE_FILE"
    } else {
        Write-Output "IMAGE_NOT_FOUND"
    }
} catch {
    try {
        Set-Clipboard -Path \$imgPath
        Write-Output "COPIED_PATH_FALLBACK"
    } catch {
        Write-Output "FAILED"
    }
}
''';

    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Copies a file (e.g. PDF) directly to the Windows Clipboard file drop list.
  static Future<bool> copyFileToClipboard(String filePath) async {
    if (!Platform.isWindows) {
      await Clipboard.setData(ClipboardData(text: filePath));
      return true;
    }

    final normalized = File(filePath).absolute.path.replaceAll('/', '\\').replaceAll("'", "''");
    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$filePath = '$normalized'
try {
    if (Test-Path \$filePath) {
        \$do = New-Object System.Windows.Forms.DataObject
        \$files = New-Object System.Collections.Specialized.StringCollection
        \$files.Add(\$filePath)
        \$do.SetFileDropList(\$files)
        [System.Windows.Forms.Clipboard]::SetDataObject(\$do, \$true)
        Write-Output "COPIED_FILE"
    }
} catch {
    Set-Clipboard -Path \$filePath
}
''';

    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

