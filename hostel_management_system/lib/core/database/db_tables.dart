class DbTables {
  static const String users = 'users';
  static const String hostelSettings = 'hostel_settings';
  static const String rooms = 'rooms';
  static const String beds = 'beds';
  static const String students = 'students';
  static const String admissions = 'admissions';
  static const String roomAllocations = 'room_allocations';
  static const String rentRecords = 'rent_records';
  static const String payments = 'payments';
  static const String receipts = 'receipts';
  static const String expenses = 'expenses';
  static const String activityLogs = 'activity_logs';

  static const List<String> createTablesQueries = [
    // 1. Users Table
    '''
    CREATE TABLE IF NOT EXISTS $users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      full_name TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'Office Staff',
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT
    );
    ''',

    // 2. Hostel Settings Table
    '''
    CREATE TABLE IF NOT EXISTS $hostelSettings (
      id INTEGER PRIMARY KEY DEFAULT 1,
      hostel_name TEXT NOT NULL DEFAULT 'Sardar 4 Boys Hostel',
      address TEXT NOT NULL DEFAULT 'Main Campus Road, City',
      phone TEXT NOT NULL DEFAULT '+92 300 1234567',
      email TEXT NOT NULL DEFAULT 'info@hostel.local',
      logo_path TEXT,
      receipt_prefix TEXT NOT NULL DEFAULT 'REC-',
      receipt_footer TEXT NOT NULL DEFAULT 'Thank you for staying with us. Please keep this receipt safe.',
      authorized_person TEXT NOT NULL DEFAULT 'Hostel Administrator',
      default_monthly_rent REAL NOT NULL DEFAULT 15000.0,
      rent_due_day INTEGER NOT NULL DEFAULT 5,
      currency TEXT NOT NULL DEFAULT 'PKR',
      backup_path TEXT,
      updated_at TEXT NOT NULL
    );
    ''',

    // 3. Rooms Table
    '''
    CREATE TABLE IF NOT EXISTS $rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      room_number TEXT NOT NULL UNIQUE,
      block TEXT NOT NULL DEFAULT 'Main',
      floor TEXT NOT NULL DEFAULT 'Ground Floor',
      room_type TEXT NOT NULL DEFAULT 'Single',
      total_beds INTEGER NOT NULL DEFAULT 1,
      monthly_rent REAL NOT NULL DEFAULT 0.0,
      room_status TEXT NOT NULL DEFAULT 'Available',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    );
    ''',

    // 4. Beds Table
    '''
    CREATE TABLE IF NOT EXISTS $beds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      room_id INTEGER NOT NULL,
      bed_number TEXT NOT NULL,
      bed_status TEXT NOT NULL DEFAULT 'Available',
      current_student_id INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (room_id) REFERENCES $rooms (id) ON DELETE CASCADE,
      FOREIGN KEY (current_student_id) REFERENCES $students (id) ON DELETE SET NULL,
      UNIQUE(room_id, bed_number)
    );
    ''',

    // 5. Students Table
    '''
    CREATE TABLE IF NOT EXISTS $students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id_code TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      father_name TEXT NOT NULL DEFAULT '',
      cnic TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      emergency_contact TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT '',
      university TEXT NOT NULL DEFAULT '',
      department TEXT NOT NULL DEFAULT '',
      semester TEXT NOT NULL DEFAULT '',
      admission_date TEXT NOT NULL,
      current_room_id INTEGER,
      current_bed_id INTEGER,
      monthly_rent REAL NOT NULL DEFAULT 0.0,
      security_deposit REAL NOT NULL DEFAULT 0.0,
      status TEXT NOT NULL DEFAULT 'Active',
      leaving_date TEXT,
      profile_photo TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (current_room_id) REFERENCES $rooms (id) ON DELETE SET NULL,
      FOREIGN KEY (current_bed_id) REFERENCES $beds (id) ON DELETE SET NULL
    );
    ''',

    // 6. Admissions Table
    '''
    CREATE TABLE IF NOT EXISTS $admissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL,
      room_id INTEGER NOT NULL,
      bed_id INTEGER NOT NULL,
      admission_date TEXT NOT NULL,
      monthly_rent REAL NOT NULL,
      security_deposit REAL NOT NULL DEFAULT 0.0,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE CASCADE,
      FOREIGN KEY (room_id) REFERENCES $rooms (id) ON DELETE CASCADE,
      FOREIGN KEY (bed_id) REFERENCES $beds (id) ON DELETE CASCADE
    );
    ''',

    // 7. Room Allocations Table (Historical Bed Timeline)
    '''
    CREATE TABLE IF NOT EXISTS $roomAllocations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL,
      room_id INTEGER NOT NULL,
      bed_id INTEGER NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT,
      reason TEXT NOT NULL DEFAULT 'Admission',
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE CASCADE,
      FOREIGN KEY (room_id) REFERENCES $rooms (id) ON DELETE CASCADE,
      FOREIGN KEY (bed_id) REFERENCES $beds (id) ON DELETE CASCADE
    );
    ''',

    // 8. Rent Records Table
    '''
    CREATE TABLE IF NOT EXISTS $rentRecords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL,
      room_id INTEGER NOT NULL,
      bed_id INTEGER NOT NULL,
      rent_month TEXT NOT NULL,
      rent_amount REAL NOT NULL,
      paid_amount REAL NOT NULL DEFAULT 0.0,
      remaining_amount REAL NOT NULL,
      due_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'Pending',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE CASCADE,
      FOREIGN KEY (room_id) REFERENCES $rooms (id) ON DELETE CASCADE,
      FOREIGN KEY (bed_id) REFERENCES $beds (id) ON DELETE CASCADE,
      UNIQUE(student_id, rent_month)
    );
    ''',

    // 9. Payments Table
    '''
    CREATE TABLE IF NOT EXISTS $payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rent_record_id INTEGER NOT NULL,
      student_id INTEGER NOT NULL,
      receipt_number TEXT NOT NULL UNIQUE,
      amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      payment_method TEXT NOT NULL DEFAULT 'Cash',
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (rent_record_id) REFERENCES $rentRecords (id) ON DELETE CASCADE,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE CASCADE
    );
    ''',

    // 10. Receipts Table
    '''
    CREATE TABLE IF NOT EXISTS $receipts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      receipt_number TEXT NOT NULL UNIQUE,
      payment_id INTEGER NOT NULL,
      student_id INTEGER NOT NULL,
      rent_month TEXT NOT NULL,
      amount_paid REAL NOT NULL,
      remaining_amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      payment_method TEXT NOT NULL DEFAULT 'Cash',
      pdf_path TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (payment_id) REFERENCES $payments (id) ON DELETE CASCADE,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE CASCADE
    );
    ''',

    // 11. Expenses Table
    '''
    CREATE TABLE IF NOT EXISTS $expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'Other',
      amount REAL NOT NULL,
      expense_date TEXT NOT NULL,
      payment_method TEXT NOT NULL DEFAULT 'Cash',
      description TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    );
    ''',

    // 12. Activity Logs Table
    '''
    CREATE TABLE IF NOT EXISTS $activityLogs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_type TEXT NOT NULL,
      description TEXT NOT NULL,
      user_id INTEGER,
      username TEXT NOT NULL DEFAULT 'Admin',
      student_id INTEGER,
      record_id INTEGER,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE SET NULL,
      FOREIGN KEY (student_id) REFERENCES $students (id) ON DELETE SET NULL
    );
    ''',

    // Indexes for fast querying & high performance analytics
    'CREATE INDEX IF NOT EXISTS idx_students_status ON $students(status);',
    'CREATE INDEX IF NOT EXISTS idx_rent_records_month ON $rentRecords(rent_month);',
    'CREATE INDEX IF NOT EXISTS idx_rent_records_status ON $rentRecords(status);',
    'CREATE INDEX IF NOT EXISTS idx_payments_date ON $payments(payment_date);',
    'CREATE INDEX IF NOT EXISTS idx_expenses_date ON $expenses(expense_date);',
    'CREATE INDEX IF NOT EXISTS idx_expenses_category ON $expenses(category);',
    'CREATE INDEX IF NOT EXISTS idx_activity_logs_date ON $activityLogs(created_at);',
    'CREATE INDEX IF NOT EXISTS idx_allocations_student ON $roomAllocations(student_id);'
  ];
}
