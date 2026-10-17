import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'vehicle_repository.dart';

class JobRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<String> generateNextJobNumber() async {
    final db = await _db;
    final prefixRes = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: ['job_card_prefix']);
    final prefix = prefixRes.isNotEmpty ? prefixRes.first['value'] as String : 'JC-';

    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM jobs');
    final count = (Sqflite.firstIntValue(countRes) ?? 0) + 1;
    return '$prefix${count.toString().padLeft(5, '0')}';
  }

  Future<List<Map<String, dynamic>>> getJobs({
    String? status,
    String? customerId,
    String? vehicleId,
    String? searchQuery,
    String? dateFilter,
  }) async {
    final db = await _db;
    String sql = '''
      SELECT j.*, c.name as customer_name, c.phone as customer_phone, c.address as customer_address,
             v.vehicle_name, v.registration_number, v.color, v.model_year,
             (SELECT COUNT(*) FROM job_services WHERE job_id = j.id) as services_count
      FROM jobs j
      INNER JOIN customers c ON j.customer_id = c.id
      INNER JOIN vehicles v ON j.vehicle_id = v.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'All') {
      sql += ' AND j.status = ?';
      args.add(status);
    }
    if (customerId != null && customerId.isNotEmpty) {
      sql += ' AND j.customer_id = ?';
      args.add(customerId);
    }
    if (vehicleId != null && vehicleId.isNotEmpty) {
      sql += ' AND j.vehicle_id = ?';
      args.add(vehicleId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(j.job_number) LIKE ? OR LOWER(c.name) LIKE ? OR c.phone LIKE ? OR LOWER(v.registration_number) LIKE ?)';
      args.addAll([q, q, q, q]);
    }

    sql += ' ORDER BY j.receiving_date DESC';
    return await db.rawQuery(sql, args);
  }

  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    final db = await _db;
    final jobs = await db.rawQuery('''
      SELECT j.*, c.name as customer_name, c.phone as customer_phone, c.address as customer_address,
             v.vehicle_name, v.registration_number, v.color, v.model_year, v.model
      FROM jobs j
      INNER JOIN customers c ON j.customer_id = c.id
      INNER JOIN vehicles v ON j.vehicle_id = v.id
      WHERE j.id = ?
    ''', [jobId]);

    if (jobs.isEmpty) return null;

    final job = Map<String, dynamic>.from(jobs.first);
    final services = await db.query('job_services', where: 'job_id = ?', whereArgs: [jobId], orderBy: 'sr_no ASC');
    final staff = await db.rawQuery('''
      SELECT js.*, s.name as staff_name, s.designation
      FROM job_staff js
      INNER JOIN staff s ON js.staff_id = s.id
      WHERE js.job_id = ?
    ''', [jobId]);

    job['services'] = services;
    job['staff'] = staff;
    return job;
  }

  Future<String> saveJob({
    String? id,
    String? jobNumber,
    required String customerId,
    required String vehicleId,
    String? technicianName,
    String? serviceAdvisor,
    required String status,
    required DateTime receivingDate,
    DateTime? expectedDeliveryDate,
    DateTime? actualDeliveryDate,
    double odometerIn = 0,
    double odometerOut = 0,
    String? specialInstructions,
    double serviceLabour = 0,
    double partsTotal = 0,
    double discount = 0,
    double paidAmount = 0,
    String? customerSignature,
    String? serviceAdvisorSignature,
    String? authorizedSignature,
    String? notes,
    required List<Map<String, dynamic>> services,
    List<String> assignedStaffIds = const [],
  }) async {
    final db = await _db;
    final jobId = id ?? 'job_${const Uuid().v4().substring(0, 8)}';
    final jobNum = jobNumber ?? await generateNextJobNumber();
    final grandTotal = (serviceLabour + partsTotal) - discount;
    final remainingAmount = (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0.0;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(
        'jobs',
        {
          'id': jobId,
          'job_number': jobNum,
          'customer_id': customerId,
          'vehicle_id': vehicleId,
          'technician_name': technicianName ?? '',
          'service_advisor': serviceAdvisor ?? '',
          'status': status,
          'receiving_date': receivingDate.toIso8601String(),
          'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
          'actual_delivery_date': actualDeliveryDate?.toIso8601String(),
          'odometer_in': odometerIn,
          'odometer_out': odometerOut > 0 ? odometerOut : odometerIn,
          'special_instructions': specialInstructions ?? '',
          'service_labour': serviceLabour,
          'parts_total': partsTotal,
          'discount': discount,
          'grand_total': grandTotal,
          'paid_amount': paidAmount,
          'remaining_amount': remainingAmount,
          'customer_signature': customerSignature ?? '',
          'service_advisor_signature': serviceAdvisorSignature ?? '',
          'authorized_signature': authorizedSignature ?? '',
          'notes': notes ?? '',
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save service rows
      await txn.delete('job_services', where: 'job_id = ?', whereArgs: [jobId]);
      for (var i = 0; i < services.length; i++) {
        final s = services[i];
        final serviceId = 'jsvc_${const Uuid().v4().substring(0, 8)}';
        await txn.insert('job_services', {
          'id': serviceId,
          'job_id': jobId,
          'sr_no': i + 1,
          'description': s['description'] ?? 'Detailing Service',
          'amount': (s['amount'] as num?)?.toDouble() ?? 0.0,
          'created_at': now,
        });
      }

      // Save staff assignment
      await txn.delete('job_staff', where: 'job_id = ?', whereArgs: [jobId]);
      for (final staffId in assignedStaffIds) {
        await txn.insert('job_staff', {
          'id': 'js_${const Uuid().v4().substring(0, 8)}',
          'job_id': jobId,
          'staff_id': staffId,
          'role': 'Assigned Tech',
          'notes': '',
        });
      }
    });

    // Update vehicle service history and odometer if completed or delivered
    if (status == 'Completed' || status == 'Ready for Delivery' || status == 'Delivered') {
      final descList = services.map((s) => s['description']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
      await VehicleRepository().addServiceHistory(
        vehicleId: vehicleId,
        customerId: customerId,
        jobId: jobId,
        date: receivingDate,
        serviceDescription: descList.isNotEmpty ? descList : 'Detailing Package',
        odometer: odometerOut > 0 ? odometerOut : odometerIn,
        amount: grandTotal,
        deliveryDate: actualDeliveryDate ?? expectedDeliveryDate,
        paymentStatus: remainingAmount <= 0 ? 'Paid' : (paidAmount > 0 ? 'Partial' : 'Unpaid'),
      );
    }

    return jobId;
  }

  Future<void> updateJobStatus(String jobId, String status, {DateTime? actualDeliveryDate, double? odometerOut}) async {
    final db = await _db;
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (actualDeliveryDate != null) {
      updateData['actual_delivery_date'] = actualDeliveryDate.toIso8601String();
    }
    if (odometerOut != null && odometerOut > 0) {
      updateData['odometer_out'] = odometerOut;
    }

    await db.update('jobs', updateData, where: 'id = ?', whereArgs: [jobId]);

    if (status == 'Delivered' && actualDeliveryDate != null) {
      final job = await getJobById(jobId);
      if (job != null) {
        final vehicleId = job['vehicle_id'] as String;
        final customerId = job['customer_id'] as String;
        final odo = (job['odometer_out'] as num?)?.toDouble() ?? 0.0;
        final grandTotal = (job['grand_total'] as num?)?.toDouble() ?? 0.0;
        final paid = (job['paid_amount'] as num?)?.toDouble() ?? 0.0;

        await VehicleRepository().addServiceHistory(
          vehicleId: vehicleId,
          customerId: customerId,
          jobId: jobId,
          date: DateTime.tryParse(job['receiving_date']) ?? DateTime.now(),
          serviceDescription: 'Completed Job Card #${job['job_number']}',
          odometer: odo,
          amount: grandTotal,
          deliveryDate: actualDeliveryDate,
          paymentStatus: paid >= grandTotal ? 'Paid' : 'Partial',
        );
      }
    }
  }

  Future<void> deleteJob(String id) async {
    final db = await _db;
    await db.delete('jobs', where: 'id = ?', whereArgs: [id]);
  }
}
