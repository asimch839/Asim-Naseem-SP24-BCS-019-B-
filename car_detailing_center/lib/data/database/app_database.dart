import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'car_detailing_center.db');
    debugPrint('Initializing SQLite database at: $dbPath');

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Settings Table
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 2. Local Users Table (Offline authentication for Admin & Manager)
    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Customers Table
    batch.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        registration_date TEXT NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'Active',
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Vehicles Table
    batch.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        vehicle_name TEXT NOT NULL,
        registration_number TEXT NOT NULL,
        model TEXT,
        model_year TEXT,
        color TEXT,
        current_odometer REAL DEFAULT 0,
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // 5. Vehicle Service History Table (Permanent, never overwritten)
    batch.execute('''
      CREATE TABLE vehicle_service_history (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        job_id TEXT,
        date TEXT NOT NULL,
        service_description TEXT NOT NULL,
        odometer REAL DEFAULT 0,
        amount REAL DEFAULT 0,
        delivery_date TEXT,
        payment_status TEXT DEFAULT 'Unpaid',
        staff_names TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // 6. Inspections Table
    batch.execute('''
      CREATE TABLE inspections (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        job_id TEXT,
        inspector_name TEXT,
        inspection_date TEXT NOT NULL,
        status TEXT DEFAULT 'Completed',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // 7. Inspection Sections (Customizable sections)
    batch.execute('''
      CREATE TABLE inspection_sections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    // 8. Inspection Items Table
    batch.execute('''
      CREATE TABLE inspection_items (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        section_name TEXT NOT NULL,
        part_name TEXT NOT NULL,
        condition TEXT,
        damage_description TEXT,
        staff_remarks TEXT,
        customer_remarks TEXT,
        notes TEXT,
        view_type TEXT,
        x_pos REAL DEFAULT 0,
        y_pos REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    // 9. Inspection Photos Table
    batch.execute('''
      CREATE TABLE inspection_photos (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        item_id TEXT,
        photo_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    // 10. Jobs / Digital Job Cards Table
    batch.execute('''
      CREATE TABLE jobs (
        id TEXT PRIMARY KEY,
        job_number TEXT NOT NULL UNIQUE,
        customer_id TEXT NOT NULL,
        vehicle_id TEXT NOT NULL,
        technician_name TEXT,
        service_advisor TEXT,
        status TEXT NOT NULL,
        receiving_date TEXT NOT NULL,
        expected_delivery_date TEXT,
        actual_delivery_date TEXT,
        odometer_in REAL DEFAULT 0,
        odometer_out REAL DEFAULT 0,
        special_instructions TEXT,
        service_labour REAL DEFAULT 0,
        parts_total REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        remaining_amount REAL DEFAULT 0,
        customer_signature TEXT,
        service_advisor_signature TEXT,
        authorized_signature TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    // 11. Job Services Table
    batch.execute('''
      CREATE TABLE job_services (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        sr_no INTEGER DEFAULT 1,
        description TEXT NOT NULL,
        amount REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE
      )
    ''');

    // 12. Job Staff Table
    batch.execute('''
      CREATE TABLE job_staff (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        staff_id TEXT NOT NULL,
        role TEXT,
        notes TEXT,
        FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE
      )
    ''');

    // 13. Staff Table
    batch.execute('''
      CREATE TABLE staff (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        father_name TEXT,
        cnic TEXT,
        phone TEXT NOT NULL,
        address TEXT,
        joining_date TEXT NOT NULL,
        designation TEXT NOT NULL,
        salary_type TEXT NOT NULL,
        basic_salary REAL DEFAULT 0,
        commission_rate REAL DEFAULT 0,
        status TEXT DEFAULT 'Active',
        photo_path TEXT,
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 14. Attendance Table
    batch.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        staff_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        check_in_time TEXT,
        check_out_time TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        UNIQUE (staff_id, date),
        FOREIGN KEY (staff_id) REFERENCES staff (id) ON DELETE CASCADE
      )
    ''');

    // 15. Salaries Table
    batch.execute('''
      CREATE TABLE salaries (
        id TEXT PRIMARY KEY,
        staff_id TEXT NOT NULL,
        pay_period TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        salary_type TEXT NOT NULL,
        basic_salary REAL DEFAULT 0,
        present_days INTEGER DEFAULT 0,
        absent_days INTEGER DEFAULT 0,
        half_days INTEGER DEFAULT 0,
        overtime_hours REAL DEFAULT 0,
        overtime_amount REAL DEFAULT 0,
        bonus REAL DEFAULT 0,
        commission REAL DEFAULT 0,
        advance_deductions REAL DEFAULT 0,
        other_deductions REAL DEFAULT 0,
        gross_salary REAL DEFAULT 0,
        net_salary REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        remaining_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'Pending',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (staff_id) REFERENCES staff (id) ON DELETE CASCADE
      )
    ''');

    // 16. Salary Payments Table
    batch.execute('''
      CREATE TABLE salary_payments (
        id TEXT PRIMARY KEY,
        salary_id TEXT NOT NULL,
        staff_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        is_advance INTEGER DEFAULT 0,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (salary_id) REFERENCES salaries (id) ON DELETE CASCADE,
        FOREIGN KEY (staff_id) REFERENCES staff (id) ON DELETE CASCADE
      )
    ''');

    // 17. Staff Expenses Table
    batch.execute('''
      CREATE TABLE staff_expenses (
        id TEXT PRIMARY KEY,
        staff_id TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        vendor_details TEXT,
        reference TEXT,
        receipt_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (staff_id) REFERENCES staff (id) ON DELETE CASCADE
      )
    ''');

    // 18. Garage Expenses Table
    batch.execute('''
      CREATE TABLE garage_expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        vendor_name TEXT,
        vendor_company TEXT,
        vendor_contact TEXT,
        vendor_address TEXT,
        vendor_invoice_ref TEXT,
        receipt_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 19. Inventory Items Table
    batch.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        current_quantity REAL DEFAULT 0,
        brand TEXT,
        unit TEXT NOT NULL,
        purchase_price REAL DEFAULT 0,
        purchase_date TEXT,
        description TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 20. Inventory Transactions Table
    batch.execute('''
      CREATE TABLE inventory_transactions (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        previous_quantity REAL NOT NULL,
        quantity_change REAL NOT NULL,
        new_quantity REAL NOT NULL,
        transaction_type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        user_name TEXT,
        job_id TEXT,
        vendor_reference TEXT,
        reason_notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES inventory_items (id) ON DELETE CASCADE
      )
    ''');

    // 21. Invoices Table
    batch.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        vehicle_id TEXT NOT NULL,
        job_id TEXT,
        description TEXT,
        subtotal REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        remaining_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'Unpaid',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    // 22. Invoice Items Table
    batch.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit_price REAL DEFAULT 0,
        total_price REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 23. Payments Table
    batch.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        vehicle_id TEXT,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        reference_number TEXT,
        is_refund INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // 24. Local Notifications Table (Reminders)
    batch.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        related_id TEXT,
        is_read INTEGER DEFAULT 0,
        date_time TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 25. Audit Logs Table
    batch.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        module TEXT NOT NULL,
        details TEXT,
        user_name TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // Performance Indexes
    batch.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    batch.execute('CREATE INDEX idx_vehicles_customer ON vehicles(customer_id)');
    batch.execute('CREATE INDEX idx_vehicles_reg ON vehicles(registration_number)');
    batch.execute('CREATE INDEX idx_jobs_status ON jobs(status)');
    batch.execute('CREATE INDEX idx_jobs_customer ON jobs(customer_id)');
    batch.execute('CREATE INDEX idx_attendance_staff_date ON attendance(staff_id, date)');
    batch.execute('CREATE INDEX idx_salaries_staff_period ON salaries(staff_id, pay_period)');
    batch.execute('CREATE INDEX idx_garage_expenses_date ON garage_expenses(date)');
    batch.execute('CREATE INDEX idx_inv_transactions_item ON inventory_transactions(item_id)');
    batch.execute('CREATE INDEX idx_invoices_status ON invoices(status)');
    batch.execute('CREATE INDEX idx_payments_invoice ON payments(invoice_id)');

    await batch.commit(noResult: true);

    // Initial Seeds
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Default Settings
    final defaultSettings = {
      'business_name': 'Apex Car Detailing & Studio',
      'logo_path': '',
      'phone': '+92 300 1234567',
      'whatsapp': '+92 300 1234567',
      'email': 'contact@apexautodetail.com',
      'address': 'Plot 42, Auto Sector, Main Boulevard',
      'currency': 'PKR',
      'timezone': 'Asia/Karachi',
      'tax_rate': '0',
      'invoice_prefix': 'INV-',
      'job_card_prefix': 'JC-',
      'low_stock_threshold': '5',
      'theme_mode': 'dark',
    };

    final batch = db.batch();
    defaultSettings.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value});
    });

    // Default Users: Admin and Manager for offline use
    batch.insert('users', {
      'id': 'usr_admin_001',
      'username': 'admin',
      'email': 'admin@autodetail.com',
      'password_hash': 'admin123',
      'full_name': 'Center Administrator',
      'role': AppConstants.roleAdmin,
      'is_active': 1,
      'created_at': now,
    });

    batch.insert('users', {
      'id': 'usr_manager_001',
      'username': 'manager',
      'email': 'manager@autodetail.com',
      'password_hash': 'manager123',
      'full_name': 'Operations Manager',
      'role': AppConstants.roleManager,
      'is_active': 1,
      'created_at': now,
    });

    // Seed Standard Inspection Sections (Editable by user)
    final sections = [
      'Exterior Body & Paint',
      'Windscreen & Glass',
      'Wheels & Tires',
      'Interior Cabin & Seats',
      'Engine Bay & Fluids',
      'Suspension & Undercarriage',
      'Lighting & Electronics',
      'Drive & Mechanical Condition',
    ];

    for (var i = 0; i < sections.length; i++) {
      batch.insert('inspection_sections', {
        'id': 'sec_${i + 1}',
        'name': sections[i],
        'sort_order': i + 1,
        'is_custom': 0,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Incremental migration handling
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
