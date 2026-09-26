import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_system/data/models/student_model.dart';
import 'package:hostel_management_system/data/models/rent_record_model.dart';

void main() {
  group('Student Model with Rent Status Tests', () {
    test('StudentModel includes current rent status and remaining due', () {
      final student = StudentModel(
        id: 1,
        studentIdCode: 'STU-001',
        fullName: 'Ali Khan',
        fatherName: 'Tariq Khan',
        cnic: '35201-1111111-1',
        phone: '03001234567',
        emergencyContact: '03007654321',
        address: 'Lahore',
        university: 'UET Lahore',
        department: 'CS',
        semester: '3rd',
        admissionDate: '2026-08-01',
        monthlyRent: 12000,
        status: 'Active',
        createdAt: '2026-08-01T00:00:00',
        currentRentStatus: 'Pending',
        currentRentRemaining: 12000,
      );

      final map = student.toMap();
      expect(map['full_name'], 'Ali Khan');

      final joinedMap = {
        ...map,
        'current_rent_status': 'Paid',
        'current_rent_remaining': 0.0,
      };

      final fromMap = StudentModel.fromMap(joinedMap);
      expect(fromMap.currentRentStatus, 'Paid');
      expect(fromMap.currentRentRemaining, 0.0);

      final updated = fromMap.copyWith(
        currentRentStatus: 'Pending',
        currentRentRemaining: 12000.0,
      );
      expect(updated.currentRentStatus, 'Pending');
      expect(updated.currentRentRemaining, 12000.0);
    });
  });

  group('Monthly Rent Status Transition Logic Tests', () {
    test('Month 1 payment cycle: Pending -> Paid', () {
      // 1. Month 1 generated: Ali has rent for 2026-08
      final month1Record = RentRecordModel(
        id: 1,
        studentId: 1,
        roomId: 1,
        bedId: 1,
        rentMonth: '2026-08',
        rentAmount: 15000,
        paidAmount: 0.0,
        remainingAmount: 15000,
        dueDate: '2026-08-05',
        status: 'Pending',
        createdAt: '2026-08-01T10:00:00',
      );

      expect(month1Record.isPending, true);
      expect(month1Record.isPaid, false);
      expect(month1Record.remainingAmount, 15000.0);

      // 2. Student pays full rent for Month 1
      final paidRecordMonth1 = month1Record.copyWith(
        paidAmount: 15000,
        remainingAmount: 0.0,
        status: 'Paid',
        updatedAt: '2026-08-04T12:00:00',
      );

      expect(paidRecordMonth1.isPaid, true);
      expect(paidRecordMonth1.remainingAmount, 0.0);

      // 3. Next month (2026-09) starts:
      // Month 1 record MUST remain Paid
      expect(paidRecordMonth1.status, 'Paid');

      // Month 2 record is generated for the new month with Pending status
      final month2Record = RentRecordModel(
        id: 2,
        studentId: 1,
        roomId: 1,
        bedId: 1,
        rentMonth: '2026-09',
        rentAmount: 15000,
        paidAmount: 0.0,
        remainingAmount: 15000,
        dueDate: '2026-09-05',
        status: 'Pending',
        createdAt: '2026-09-01T00:00:00',
      );

      // Student's new month status is Pending (unpaid) until payment is made
      expect(month2Record.rentMonth, '2026-09');
      expect(month2Record.status, 'Pending');
      expect(month2Record.isPaid, false);
      expect(month2Record.remainingAmount, 15000.0);

      // 4. Student pays partially in Month 2 (e.g. 5000)
      final partialMonth2 = month2Record.copyWith(
        paidAmount: 5000,
        remainingAmount: 10000,
        status: 'Partial',
      );
      expect(partialMonth2.isPartial, true);
      expect(partialMonth2.isPaid, false);

      // 5. Student clears remaining dues in Month 2
      final fullyPaidMonth2 = partialMonth2.copyWith(
        paidAmount: 15000,
        remainingAmount: 0.0,
        status: 'Paid',
      );
      expect(fullyPaidMonth2.isPaid, true);
      expect(fullyPaidMonth2.remainingAmount, 0.0);
    });

    test('Overdue status condition when due date passed with unpaid balance', () {
      final record = RentRecordModel(
        id: 3,
        studentId: 2,
        roomId: 2,
        bedId: 3,
        rentMonth: '2026-09',
        rentAmount: 15000,
        paidAmount: 0.0,
        remainingAmount: 15000,
        dueDate: '2026-09-05',
        status: 'Overdue',
        createdAt: '2026-09-01T00:00:00',
      );

      expect(record.isOverdue, true);
      expect(record.isPaid, false);
    });
  });

  group('Security Deposit & Departure Settlement Tests', () {
    test('Rent payment from security deposit reduces student security balance', () {
      double studentSecurity = 10000.0;
      final rentDue = 6000.0;

      // Adjust 6000 from security
      expect(studentSecurity >= rentDue, true);
      studentSecurity -= rentDue;

      expect(studentSecurity, 4000.0);
    });

    test('Departure settlement: Security adjusts pending rent and refunds remainder', () {
      final securityDeposit = 15000.0;
      final pendingRent = 8000.0;

      // Settle: adjust pending rent from security
      final adjustAmount = securityDeposit >= pendingRent ? pendingRent : securityDeposit;
      final refundAmount = securityDeposit - adjustAmount;

      expect(adjustAmount, 8000.0);
      expect(refundAmount, 7000.0);

      final finalSecurityBalance = (securityDeposit - adjustAmount - refundAmount).clamp(0.0, double.infinity);
      expect(finalSecurityBalance, 0.0);
    });

    test('RentRecordModel includes studentSecurityDeposit joined field', () {
      final rent = RentRecordModel(
        id: 10,
        studentId: 5,
        roomId: 1,
        bedId: 1,
        rentMonth: '2026-09',
        rentAmount: 15000,
        remainingAmount: 15000,
        dueDate: '2026-09-05',
        studentSecurityDeposit: 10000.0,
        createdAt: '2026-09-01T00:00:00',
      );

      expect(rent.studentSecurityDeposit, 10000.0);
    });
  });
}
