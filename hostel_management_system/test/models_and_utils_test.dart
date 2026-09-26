import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_system/core/utils/password_hasher.dart';
import 'package:hostel_management_system/core/utils/currency_formatter.dart';
import 'package:hostel_management_system/core/utils/date_formatter.dart';
import 'package:hostel_management_system/data/models/student_model.dart';
import 'package:hostel_management_system/data/models/rent_record_model.dart';
import 'package:hostel_management_system/data/models/receipt_model.dart';
import 'package:hostel_management_system/data/models/hostel_settings_model.dart';
import 'package:hostel_management_system/core/services/whatsapp_service.dart';

void main() {
  group('Security & Password Hasher Tests', () {
    test('Salted password generation and verification', () {
      final salt = PasswordHasher.generateSalt();
      expect(salt.isNotEmpty, true);

      final hash = PasswordHasher.hashPassword('admin@123', salt);
      expect(hash.isNotEmpty, true);

      final isMatch = PasswordHasher.verifyPassword('admin@123', salt, hash);
      expect(isMatch, true);

      final isWrong = PasswordHasher.verifyPassword('wrongpass', salt, hash);
      expect(isWrong, false);
    });
  });

  group('Formatter Tests', () {
    test('Currency Formatter formats properly', () {
      final formatted = CurrencyFormatter.format(15000);
      expect(formatted.contains('15,000'), true);
    });

    test('Date Formatter ISO and Display formats', () {
      final now = DateTime(2026, 9, 20);
      final iso = DateFormatter.toIsoDate(now);
      expect(iso, '2026-09-20');

      final display = DateFormatter.formatDate(now);
      expect(display, '20-Sep-2026');
    });
  });

  group('Model Integrity & Serialization Tests', () {
    test('StudentModel serialization', () {
      final student = StudentModel(
        id: 1,
        studentIdCode: 'STU-001',
        fullName: 'Muhammad Ahmed',
        fatherName: 'Ahmed Khan',
        cnic: '35201-1234567-1',
        phone: '03001234567',
        emergencyContact: '03217654321',
        address: 'Model Town, Lahore',
        university: 'COMSATS University',
        department: 'Computer Science',
        semester: '5th',
        admissionDate: '2026-09-01',
        monthlyRent: 15000,
        status: 'Active',
        securityDeposit: 5000,
        createdAt: '2026-09-01T10:00:00',
      );

      final map = student.toMap();
      expect(map['full_name'], 'Muhammad Ahmed');
      expect(map['security_deposit'], 5000.0);

      final fromMap = StudentModel.fromMap(map);
      expect(fromMap.fullName, 'Muhammad Ahmed');
      expect(fromMap.securityDeposit, 5000.0);
    });

    test('RentRecordModel remaining balance & status logic', () {
      final record = RentRecordModel(
        id: 1,
        studentId: 1,
        roomId: 1,
        bedId: 1,
        rentMonth: '2026-09',
        rentAmount: 15000,
        paidAmount: 5000,
        remainingAmount: 10000,
        dueDate: '2026-09-05',
        status: 'Partial',
        createdAt: '2026-09-01T10:00:00',
        updatedAt: null,
      );

      expect(record.isPartial, true);
      expect(record.remainingAmount, 10000.0);
    });
  });

  group('WhatsApp Service Tests', () {
    test('Phone number normalization for WhatsApp', () {
      expect(WhatsAppService.normalizePhone('03007720839'), '923007720839');
      expect(WhatsAppService.normalizePhone('+92-300-7720839'), '923007720839');
      expect(WhatsAppService.normalizePhone('00923007720839'), '923007720839');
      expect(WhatsAppService.normalizePhone('3007720839'), '923007720839');
      expect(WhatsAppService.normalizePhone(null), '');
      expect(WhatsAppService.normalizePhone(''), '');
    });

    test('Receipt WhatsApp message generation contains key details & branding', () {
      final receipt = ReceiptModel(
        receiptNumber: 'REC-2026-001',
        paymentId: 10,
        studentId: 1,
        studentName: 'Ali Khan',
        studentIdCode: 'STU-101',
        studentPhone: '03007720839',
        roomNumber: '101',
        bedNumber: 'B1',
        rentMonth: '2026-09',
        amountPaid: 15000,
        remainingAmount: 0,
        paymentDate: '2026-09-20',
        paymentMethod: 'Cash',
        createdAt: '2026-09-20T12:00:00',
      );

      final settings = HostelSettingsModel(
        hostelName: 'Al-Madina Boys Hostel',
        address: 'Main Campus',
        phone: '03001234567',
        email: 'info@hostel.com',
        receiptPrefix: 'REC-',
        receiptFooter: 'Thank you for your timely payment!',
        authorizedPerson: 'Manager',
        defaultMonthlyRent: 15000,
        rentDueDay: 5,
        currency: 'PKR',
        updatedAt: '2026-09-20',
      );

      final message = WhatsAppService.generateReceiptMessage(
        receipt: receipt,
        settings: settings,
      );

      expect(message.contains('REC-2026-001'), true);
      expect(message.contains('Ali Khan'), true);
      expect(message.contains('Al-Madina Boys Hostel'), true);
      expect(message.contains('15,000'), true);
      expect(message.contains('Devnix Limited'), true);
      expect(message.contains('03007720839'), true);
    });
  });
}
