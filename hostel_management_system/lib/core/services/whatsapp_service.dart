import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_styles.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/rent_record_model.dart';
import '../../data/models/hostel_settings_model.dart';
import '../../widgets/custom_text_field.dart';
import 'pdf_service.dart';

class WhatsAppService {
  /// Automatically brings active WhatsApp desktop window into foreground focus,
  /// pastes (Ctrl + V) the receipt slip from clipboard, and sends (Enter).
  static void _simulatePasteAndSend({
    int delayMs = 2800,
    bool sendEnter = true,
  }) {
    if (!Platform.isWindows) return;

    Future.delayed(Duration(milliseconds: delayMs), () async {
      try {
        final tempDir = await getTemporaryDirectory();
        final ps1File = File('${tempDir.path}\\whatsapp_auto_send.ps1');

        final scriptContent = r'''
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32Key {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
}
"@ -ErrorAction SilentlyContinue

$wshell = New-Object -ComObject WScript.Shell

function Activate-WhatsApp {
    try { $wshell.AppActivate("WhatsApp") } catch {}
}

# 1. Bring WhatsApp Desktop into active focus
Activate-WhatsApp
Start-Sleep -Milliseconds 600

# 2. Hardware low-level keybd_event simulation for Ctrl + V
# VK_CONTROL = 0x11, 'V' = 0x56, KEYEVENTF_KEYUP = 0x0002
[Win32Key]::keybd_event(0x11, 0, 0, [UIntPtr]::Zero)
[Win32Key]::keybd_event(0x56, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100
[Win32Key]::keybd_event(0x56, 0, 2, [UIntPtr]::Zero)
[Win32Key]::keybd_event(0x11, 0, 2, [UIntPtr]::Zero)

try { $wshell.SendKeys("^v") } catch {}

# 3. Wait for WhatsApp image preview overlay screen to open
Start-Sleep -Milliseconds 1800

# 4. Activate WhatsApp again and send Ctrl + Enter & Enter to auto-send!
Activate-WhatsApp
Start-Sleep -Milliseconds 300
[Win32Key]::keybd_event(0x11, 0, 0, [UIntPtr]::Zero)
[Win32Key]::keybd_event(0x0D, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100
[Win32Key]::keybd_event(0x0D, 0, 2, [UIntPtr]::Zero)
[Win32Key]::keybd_event(0x11, 0, 2, [UIntPtr]::Zero)

try { $wshell.SendKeys("^{ENTER}") } catch {}
try { $wshell.SendKeys("{ENTER}") } catch {}

# 5. Safety fallback pulse 1.2s later
Start-Sleep -Milliseconds 1200
Activate-WhatsApp
Start-Sleep -Milliseconds 200
[Win32Key]::keybd_event(0x0D, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100
[Win32Key]::keybd_event(0x0D, 0, 2, [UIntPtr]::Zero)
try { $wshell.SendKeys("{ENTER}") } catch {}
''';

        await ps1File.writeAsString(scriptContent);
        await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', ps1File.path]);
      } catch (_) {}
    });
  }

  /// Normalize any phone number format (e.g. 0300-1234567, +92300..., 03001234567)
  /// into international standard digits for WhatsApp (e.g. 923001234567).
  static String normalizePhone(String? rawPhone) {
    if (rawPhone == null) return '';
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('0092')) {
      digits = '92${digits.substring(4)}';
    } else if (digits.startsWith('03')) {
      digits = '92${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('3')) {
      digits = '92$digits';
    }
    return digits;
  }

  /// Create a clean, formatted receipt text message
  static String generateReceiptMessage({
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
  }) {
    final hostelName = settings.hostelName.trim().isNotEmpty
        ? settings.hostelName.trim()
        : 'Hostel Management';
    final amountPaidStr = CurrencyFormatter.format(receipt.amountPaid);
    final remainingStr = CurrencyFormatter.format(receipt.remainingAmount);
    final studentName = receipt.studentName ?? 'Student';
    final studentCode = receipt.studentIdCode != null ? ' (${receipt.studentIdCode})' : '';
    final room = receipt.roomNumber ?? '-';
    final bed = receipt.bedNumber ?? '-';

    final buffer = StringBuffer();
    buffer.writeln('🧾 *FEE PAYMENT RECEIPT*');
    buffer.writeln('🏢 *$hostelName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 *Receipt No:* ${receipt.receiptNumber}');
    buffer.writeln('📅 *Payment Date:* ${receipt.paymentDate}');
    buffer.writeln('👤 *Student:* $studentName$studentCode');
    buffer.writeln('🚪 *Room / Bed:* Room $room (Bed $bed)');
    buffer.writeln('🗓️ *Billing Month:* ${receipt.rentMonth}');
    buffer.writeln('💰 *Amount Paid:* $amountPaidStr');
    buffer.writeln('💳 *Payment Method:* ${receipt.paymentMethod}');
    if (receipt.remainingAmount > 0) {
      buffer.writeln('⚠️ *Remaining Dues:* $remainingStr');
    } else {
      buffer.writeln('✅ *Status:* Fully Paid (Nil Dues)');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    if (settings.receiptFooter.trim().isNotEmpty) {
      buffer.writeln(settings.receiptFooter.trim());
    }
    buffer.writeln('');
    buffer.writeln('_${AppStrings.developerBrandingShort}_');

    return buffer.toString();
  }

  /// Create a respectful, structured WhatsApp rent due / overdue reminder message
  static String generateRentReminderMessage({
    required RentRecordModel rent,
    required HostelSettingsModel settings,
    String? customNote,
  }) {
    final hostelName = settings.hostelName.trim().isNotEmpty
        ? settings.hostelName.trim()
        : AppStrings.appName;
    final studentName = rent.studentName ?? 'Student';
    final studentCode = rent.studentIdCode != null ? ' (${rent.studentIdCode})' : '';
    final room = rent.roomNumber != null ? 'Room ${rent.roomNumber}' : '-';
    final bed = rent.bedNumber != null ? 'Bed ${rent.bedNumber}' : '-';
    final billingMonth = DateFormatter.formatMonthYearString(rent.rentMonth);
    final rentAmountStr = CurrencyFormatter.format(rent.rentAmount);
    final paidAmountStr = CurrencyFormatter.format(rent.paidAmount);
    final remainingStr = CurrencyFormatter.format(rent.remainingAmount);

    final dueDateTime = DateTime.tryParse(rent.dueDate);
    final dueDateStr = DateFormatter.formatDate(dueDateTime);

    // Calculate overdue duration
    String overdueText = '';
    if (dueDateTime != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);
      final diff = today.difference(dueDay).inDays;
      if (diff > 0) {
        overdueText = '🚨 *Status:* OVERDUE ($diff days past due date)';
      } else if (diff == 0) {
        overdueText = '⚠️ *Status:* DUE TODAY';
      } else {
        overdueText = '📅 *Status:* Due in ${diff.abs()} days';
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('⚠️ *HOSTEL RENT PAYMENT REMINDER*');
    buffer.writeln('🏢 *$hostelName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Student:* $studentName$studentCode');
    buffer.writeln('🚪 *Room / Bed:* $room ($bed)');
    buffer.writeln('🗓️ *Billing Month:* $billingMonth');
    buffer.writeln('💰 *Total Rent:* $rentAmountStr');
    if (rent.paidAmount > 0) {
      buffer.writeln('💵 *Amount Paid:* $paidAmountStr');
    }
    buffer.writeln('🔴 *Outstanding Balance:* $remainingStr');
    buffer.writeln('📅 *Due Date:* $dueDateStr');
    if (overdueText.isNotEmpty) {
      buffer.writeln(overdueText);
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📢 *Notice / اطلاع:*');
    buffer.writeln('Assalam-o-Alaikum,');
    buffer.writeln(
        'This is a gentle reminder that your hostel rent of *$remainingStr* for the month of *$billingMonth* is due/overdue. Kindly submit your outstanding dues at the hostel office or via online payment at your earliest convenience.');
    buffer.writeln('');
    buffer.writeln(
        'اگر آپ پہلے ہی ادا کر چکے ہیں تو برائے مہربانی رسید یا اسکرین شاٹ ہاسٹل آفس کو شیئر کر دیں۔ شکریہ۔');
    buffer.writeln('(If you have already paid, please share the payment confirmation/slip with the office.)');

    if (customNote != null && customNote.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 *Note:* ${customNote.trim()}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    if (settings.phone.trim().isNotEmpty) {
      buffer.writeln('📞 *Office Phone:* ${settings.phone.trim()}');
    }
    if (settings.address.trim().isNotEmpty) {
      buffer.writeln('📍 *Hostel Address:* ${settings.address.trim()}');
    }
    buffer.writeln('');
    buffer.writeln('_${AppStrings.developerBrandingShort}_');

    return buffer.toString();
  }

  /// Interactive dialog to review and send WhatsApp Rent Reminder to student/parent
  static void showRentReminderDialog({
    required BuildContext context,
    required RentRecordModel rent,
    required HostelSettingsModel settings,
  }) {
    final phoneCtrl = TextEditingController(text: rent.studentPhone ?? '');
    final initialMessage = generateRentReminderMessage(
      rent: rent,
      settings: settings,
    );
    final messageCtrl = TextEditingController(text: initialMessage);

    final dueDateTime = DateTime.tryParse(rent.dueDate);
    final isOverdue = dueDateTime != null &&
        dueDateTime.isBefore(DateTime.now()) &&
        rent.remainingAmount > 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.whatsappDark.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: AppColors.whatsappDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send WhatsApp Rent Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rent.studentName ?? "Student"} (${rent.studentIdCode ?? "-"}) • Room ${rent.roomNumber ?? "-"}',
                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () {
                        if (Get.isDialogOpen == true) Get.back();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Due Dues Status Summary Banner
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;
                    final pendingCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pending Balance: ',
                              style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              CurrencyFormatter.format(rent.remainingAmount),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Billing Month: ${DateFormatter.formatMonthYearString(rent.rentMonth)}',
                          style: AppStyles.caption,
                        ),
                      ],
                    );

                    final statusCol = Column(
                      crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? AppColors.danger : AppColors.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : 'DUE SOON',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${DateFormatter.formatDate(DateTime.tryParse(rent.dueDate))}',
                          style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.danger.withValues(alpha: 0.08)
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOverdue
                              ? AppColors.danger.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                pendingCol,
                                const SizedBox(height: 8),
                                statusCol,
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                pendingCol,
                                statusCol,
                              ],
                            ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Recipient Contact Phone
                CustomTextField(
                  label: 'Student / Parent WhatsApp Number',
                  hint: 'e.g. 03001234567 or 923001234567',
                  controller: phoneCtrl,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pre-filled with student contact number. Change if sending to parent/guardian.',
                  style: AppStyles.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),

                // Editable Message Preview
                const Text(
                  'Reminder Message Preview (Editable):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TextField(
                    controller: messageCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Message'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: messageCtrl.text));
                          Get.snackbar(
                            'Copied to Clipboard',
                            'Reminder message copied successfully!',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 3),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Send on WhatsApp',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsappDark,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final phone = phoneCtrl.text.trim();
                          final msg = messageCtrl.text.trim();
                          if (Get.isDialogOpen == true) Get.back();

                          final success = await openWhatsApp(
                            phone: phone,
                            message: msg,
                          );

                          if (success) {
                            Get.snackbar(
                              'WhatsApp Opened',
                              'Opening chat with ${rent.studentName ?? "student"}. Message is ready in the chat!',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surface,
                              colorText: AppColors.textPrimary,
                              icon: const Icon(Icons.check_circle_rounded, color: AppColors.whatsappDark),
                              duration: const Duration(seconds: 4),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Open WhatsApp on desktop or browser with optional phone and optional text message
  static Future<bool> openWhatsApp({
    String? phone,
    String? message,
  }) async {
    final cleanPhone = normalizePhone(phone);
    final hasMessage = message != null && message.trim().isNotEmpty;
    final encodedText = hasMessage ? Uri.encodeComponent(message) : '';

    // Copy message text to clipboard automatically as a fallback
    if (hasMessage) {
      try {
        await Clipboard.setData(ClipboardData(text: message));
      } catch (_) {}
    }

    // 1. On Windows Desktop, try native app scheme first so it launches WhatsApp Desktop instantly!
    if (Platform.isWindows && cleanPhone.isNotEmpty) {
      final nativeUri = hasMessage
          ? Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText')
          : Uri.parse('whatsapp://send?phone=$cleanPhone');
      try {
        if (await canLaunchUrl(nativeUri)) {
          final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (_) {}
    }

    // 2. Try universal wa.me URI (for web / non-windows)
    if (cleanPhone.isNotEmpty) {
      final waUri = hasMessage
          ? Uri.parse('https://wa.me/$cleanPhone?text=$encodedText')
          : Uri.parse('https://wa.me/$cleanPhone');
      try {
        if (await canLaunchUrl(waUri)) {
          final launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (_) {}
    }

    // 3. Fallback to native desktop scheme on other platforms
    final nativeUri = cleanPhone.isNotEmpty
        ? (hasMessage
            ? Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText')
            : Uri.parse('whatsapp://send?phone=$cleanPhone'))
        : (hasMessage
            ? Uri.parse('whatsapp://send?text=$encodedText')
            : Uri.parse('whatsapp://'));

    try {
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (_) {}

    // 3. Fallback to official web/universal link: https://api.whatsapp.com/send
    final webUri = cleanPhone.isNotEmpty
        ? (hasMessage
            ? Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedText')
            : Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone'))
        : (hasMessage
            ? Uri.parse('https://api.whatsapp.com/send?text=$encodedText')
            : Uri.parse('https://web.whatsapp.com/'));

    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // 4. Last fallback: web.whatsapp.com
    final webDirectUri = cleanPhone.isNotEmpty
        ? (hasMessage
            ? Uri.parse('https://web.whatsapp.com/send?phone=$cleanPhone&text=$encodedText')
            : Uri.parse('https://web.whatsapp.com/send?phone=$cleanPhone'))
        : Uri.parse('https://web.whatsapp.com/');

    try {
      return await launchUrl(webDirectUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Notice',
        'Could not open WhatsApp automatically.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  /// Open default Email client (Outlook, Mail, Gmail) with receipt details
  static Future<bool> shareViaEmail({
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
    String? recipientEmail,
  }) async {
    final subject = 'Payment Receipt ${receipt.receiptNumber} - ${settings.hostelName}';
    final body = generateReceiptMessage(receipt: receipt, settings: settings);
    final emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail ?? '',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(emailUri);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open email application: $e');
      return false;
    }
  }

  /// 🖼️ SHARE AS PICTURE (IMAGE / SLIP) ON WHATSAPP:
  /// Converts the receipt to a high-resolution PNG image, puts the image directly
  /// onto the Windows Clipboard / Mobile Share Sheet, opens WhatsApp chat with the student,
  /// and automatically sends the receipt picture to that person!
  static Future<void> shareReceiptImageViaWhatsApp({
    BuildContext? context,
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
    bool isThermal = false,
    String? customPhone,
  }) async {
    try {
      // 1. Generate PDF bytes
      final Uint8List pdfBytes = isThermal
          ? await PdfService.generateReceiptPdfThermal(receipt: receipt, settings: settings)
          : await PdfService.generateReceiptPdfA4(receipt: receipt, settings: settings);

      // 2. Render PDF to PNG Image
      Uint8List? pngBytes;
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 180)) {
        pngBytes = await page.toPng();
        break;
      }
      if (pngBytes == null) throw Exception('Could not render receipt to picture');

      // 3. Save PNG Image to file
      final tempDir = await getTemporaryDirectory();
      final cleanNum = receipt.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final imageFile = File('${tempDir.path}/Receipt_$cleanNum.png');
      await imageFile.writeAsBytes(pngBytes);

      // Save a copy to Downloads/Hostel_Receipts on desktop if available
      try {
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        final receiptsFolder = Directory('${targetDir.path}\\Hostel_Receipts');
        if (!await receiptsFolder.exists()) {
          await receiptsFolder.create(recursive: true);
        }
        final desktopImageFile = File('${receiptsFolder.path}\\Receipt_$cleanNum.png');
        await desktopImageFile.writeAsBytes(pngBytes);
      } catch (_) {}

      final phone = customPhone ?? receipt.studentPhone;
      final textMsg = generateReceiptMessage(receipt: receipt, settings: settings);

      // 4. Mobile Platform (Android / iOS) - Shares ONLY picture slip image
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(imageFile.path, mimeType: 'image/png')],
          subject: 'Receipt ${receipt.receiptNumber}',
        );
        return;
      }

      // 5. Windows Desktop Platform
      if (Platform.isWindows) {
        // Copy Image directly to Windows Clipboard using .ps1 file
        try {
          final tempDir = await getTemporaryDirectory();
          final copyPs1 = File('${tempDir.path}\\whatsapp_copy_clip.ps1');

          final escapedPath = imageFile.path.replaceAll("'", "''");
          final copyScriptContent = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$filePath = '$escapedPath'
if (Test-Path \$filePath) {
    \$img = [System.Drawing.Image]::FromFile(\$filePath)
    \$data = New-Object System.Windows.Forms.DataObject
    \$data.SetImage(\$img)
    \$files = New-Object System.Collections.Specialized.StringCollection
    \$files.Add(\$filePath)
    \$data.SetFileDropList(\$files)
    [System.Windows.Forms.Clipboard]::SetDataObject(\$data, \$true)
}
''';

          await copyPs1.writeAsString(copyScriptContent);
          await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', copyPs1.path]);
        } catch (_) {}

        // Open WhatsApp chat with student WITHOUT text message (so only picture slip is pasted & sent!)
        await openWhatsApp(phone: phone, message: null);

        // Native Win32 hardware simulation: Automatically pastes Ctrl+V and sends Enter without user intervention!
        _simulatePasteAndSend(delayMs: 2800, sendEnter: true);
      } else {
        await Share.shareXFiles(
          [XFile(imageFile.path, mimeType: 'image/png')],
        );
      }

      Get.snackbar(
        'Sending Receipt Picture...',
        'WhatsApp chat opened! Receipt picture is being pasted and sent automatically.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.send_rounded, color: AppColors.whatsappDark),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate receipt image: $e');
    }
  }

  /// 📄 SHARE AS PDF DOCUMENT ON WHATSAPP:
  /// Generates the PDF, saves it to disk, copies the file to clipboard,
  /// opens WhatsApp chat, and automatically sends the PDF document!
  static Future<void> shareReceiptPdfViaWhatsApp({
    BuildContext? context,
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
    bool isThermal = false,
    String? customPhone,
  }) async {
    try {
      // 1. Generate PDF bytes
      final Uint8List pdfBytes = isThermal
          ? await PdfService.generateReceiptPdfThermal(receipt: receipt, settings: settings)
          : await PdfService.generateReceiptPdfA4(receipt: receipt, settings: settings);

      // 2. Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final cleanNum = receipt.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final pdfFile = File('${tempDir.path}/Receipt_$cleanNum.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      try {
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        final receiptsFolder = Directory('${targetDir.path}\\Hostel_Receipts');
        if (!await receiptsFolder.exists()) {
          await receiptsFolder.create(recursive: true);
        }
        final desktopPdfFile = File('${receiptsFolder.path}\\Receipt_$cleanNum.pdf');
        await desktopPdfFile.writeAsBytes(pdfBytes);
      } catch (_) {}

      final phone = customPhone ?? receipt.studentPhone;
      final textMsg = generateReceiptMessage(receipt: receipt, settings: settings);

      // 3. Mobile Platform (Android / iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(pdfFile.path, mimeType: 'application/pdf')],
          text: textMsg,
          subject: 'Receipt ${receipt.receiptNumber}',
        );
        return;
      }

      // 4. Windows Desktop Platform
      if (Platform.isWindows) {
        // Put PDF file reference on Windows Clipboard using .ps1 file
        try {
          final tempDir = await getTemporaryDirectory();
          final copyPs1 = File('${tempDir.path}\\whatsapp_copy_pdf.ps1');

          final escapedPath = pdfFile.path.replaceAll("'", "''");
          final copyScriptContent = '''
Add-Type -AssemblyName System.Windows.Forms
\$filePath = '$escapedPath'
if (Test-Path \$filePath) {
    \$data = New-Object System.Windows.Forms.DataObject
    \$files = New-Object System.Collections.Specialized.StringCollection
    \$files.Add(\$filePath)
    \$data.SetFileDropList(\$files)
    [System.Windows.Forms.Clipboard]::SetDataObject(\$data, \$true)
}
''';

          await copyPs1.writeAsString(copyScriptContent);
          await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', copyPs1.path]);
        } catch (_) {}

        // Open WhatsApp chat with student
        await openWhatsApp(phone: phone, message: textMsg);

        // Native Win32 hardware simulation: Automatically pastes Ctrl+V and sends Enter without user intervention!
        _simulatePasteAndSend(delayMs: 2800, sendEnter: true);
      } else {
        await Share.shareXFiles(
          [XFile(pdfFile.path, mimeType: 'application/pdf')],
          text: textMsg,
        );
      }

      Get.snackbar(
        'Sending Receipt PDF...',
        'WhatsApp chat opened! Receipt PDF document is being pasted and sent automatically.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.send_rounded, color: AppColors.whatsappDark),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to prepare receipt PDF: $e');
    }
  }

  /// Interactive multi-app Share Modal allowing user to choose Picture, PDF, Email, etc.
  static void showShareDialog({
    required BuildContext context,
    required ReceiptModel receipt,
    required HostelSettingsModel settings,
    bool isThermal = false,
  }) {
    final phoneCtrl = TextEditingController(text: receipt.studentPhone ?? '');
    final message = generateReceiptMessage(receipt: receipt, settings: settings);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 730),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share Receipt (Picture / PDF)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Receipt: ${receipt.receiptNumber} • ${receipt.studentName ?? "Student"} (${isThermal ? "Thermal" : "A4"})',
                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () {
                        if (Get.isDialogOpen == true) Get.back();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Recipient Contact Phone
                CustomTextField(
                  label: 'Recipient WhatsApp / Contact Number',
                  hint: 'e.g. 03001234567 or 923001234567',
                  controller: phoneCtrl,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 6),
                Text(
                  'Pre-filled with student phone number. Change if sending to parent/guardian.',
                  style: AppStyles.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Choose How You Want to Share:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),

                // Multi-App Share Options
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Option 1: WhatsApp as Picture (Image / Slip)
                        _buildAppOptionTile(
                          icon: Icons.image_rounded,
                          iconColor: Colors.white,
                          iconBgColor: AppColors.whatsapp,
                          title: 'WhatsApp — Send as Picture (Image / Slip)',
                          subtitle: 'Automatically opens chat, pastes picture & sends (no Ctrl+V needed!)',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            await shareReceiptImageViaWhatsApp(
                              context: context,
                              receipt: receipt,
                              settings: settings,
                              isThermal: isThermal,
                              customPhone: phoneCtrl.text.trim(),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 2: WhatsApp as PDF Document
                        _buildAppOptionTile(
                          icon: Icons.picture_as_pdf_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFF059669),
                          title: 'WhatsApp — Send as PDF Document',
                          subtitle: 'Automatically opens chat, pastes PDF & sends (no Ctrl+V needed!)',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            await shareReceiptPdfViaWhatsApp(
                              context: context,
                              receipt: receipt,
                              settings: settings,
                              isThermal: isThermal,
                              customPhone: phoneCtrl.text.trim(),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 3: WhatsApp as Formatted Text Message
                        _buildAppOptionTile(
                          icon: Icons.chat_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFF0D9488),
                          title: 'WhatsApp — Send as Text Message',
                          subtitle: 'Opens WhatsApp chat with receipt details pre-filled in the message box',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            await openWhatsApp(
                              phone: phoneCtrl.text.trim(),
                              message: message,
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 4: Default Email
                        _buildAppOptionTile(
                          icon: Icons.email_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFF4F46E5),
                          title: 'Email (Outlook / Mail / Gmail)',
                          subtitle: 'Opens email client with subject & receipt details ready to send',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            await shareViaEmail(receipt: receipt, settings: settings);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 4: Windows Native Share Sheet
                        _buildAppOptionTile(
                          icon: Icons.share_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFF0284C7),
                          title: 'Windows System Share Sheet',
                          subtitle: 'Choose from any installed Windows apps or nearby sharing to transfer the PDF',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            try {
                              final pdfBytes = isThermal
                                  ? await PdfService.generateReceiptPdfThermal(receipt: receipt, settings: settings)
                                  : await PdfService.generateReceiptPdfA4(receipt: receipt, settings: settings);
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename: 'Receipt_${receipt.receiptNumber}.pdf',
                              );
                            } catch (e) {
                              Get.snackbar('Error', 'Could not invoke system share: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 5: Save & Show in File Explorer
                        _buildAppOptionTile(
                          icon: Icons.folder_open_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFFD97706),
                          title: 'Save to Computer & Open Folder',
                          subtitle: 'Saves both Image and PDF to your Hostel_Receipts folder and opens Explorer',
                          onTap: () async {
                            if (Get.isDialogOpen == true) Get.back();
                            try {
                              final pdfBytes = isThermal
                                  ? await PdfService.generateReceiptPdfThermal(receipt: receipt, settings: settings)
                                  : await PdfService.generateReceiptPdfA4(receipt: receipt, settings: settings);

                              Directory? targetDir;
                              try {
                                targetDir = await getDownloadsDirectory();
                              } catch (_) {}
                              targetDir ??= await getApplicationDocumentsDirectory();

                              final receiptsFolder = Directory('${targetDir.path}\\Hostel_Receipts');
                              if (!await receiptsFolder.exists()) {
                                await receiptsFolder.create(recursive: true);
                              }

                              final cleanNum = receipt.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
                              final targetFile = File('${receiptsFolder.path}\\Receipt_$cleanNum.pdf');
                              await targetFile.writeAsBytes(pdfBytes);

                              if (Platform.isWindows) {
                                await Process.run('explorer.exe', ['/select,', targetFile.path]);
                              }

                              Get.snackbar(
                                'Saved Successfully',
                                'Saved to ${targetFile.path}',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } catch (e) {
                              Get.snackbar('Error', 'Failed to save: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 6: Copy Text
                        _buildAppOptionTile(
                          icon: Icons.copy_rounded,
                          iconColor: Colors.white,
                          iconBgColor: const Color(0xFF475569),
                          title: 'Copy Plain Text Summary',
                          subtitle: 'Copy formatted text details to clipboard',
                          onTap: () {
                            if (Get.isDialogOpen == true) Get.back();
                            Clipboard.setData(ClipboardData(text: message));
                            Get.snackbar(
                              'Copied',
                              'Receipt details copied to clipboard!',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 3),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildAppOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: AppColors.background,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
