/// Application Constants for Car Detailing Center Management Software
class AppConstants {
  static const String appName = 'AutoDetail Pro';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Devnix Limited';

  // Local Storage Keys
  static const String keyActiveBusinessId = 'active_business_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserRole = 'user_role';
  static const String keyFCMToken = 'fcm_token';

  // Default Business Settings
  static const String defaultCurrency = 'Rs.';
  static const double defaultTaxRate = 0.0;
  static const String defaultJobPrefix = 'JOB-';
  static const String defaultInvoicePrefix = 'INV-';
  static const String defaultInspectionPrefix = 'INSP-';

  // Roles (Strictly Admin and Manager per Section 5)
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';

  // Global Inventory Threshold Default
  static const double defaultLowStockThreshold = 5.0;

  // Job Statuses
  static const String jobStatusNew = 'New';
  static const String jobStatusInspectionPending = 'Inspection Pending';
  static const String jobStatusWaiting = 'Waiting';
  static const String jobStatusInProgress = 'In Progress';
  static const String jobStatusCompleted = 'Completed';
  static const String jobStatusReadyForDelivery = 'Ready for Delivery';
  static const String jobStatusDelivered = 'Delivered';
  static const String jobStatusCancelled = 'Cancelled';

  static const List<String> allJobStatuses = [
    jobStatusNew,
    jobStatusInspectionPending,
    jobStatusWaiting,
    jobStatusInProgress,
    jobStatusCompleted,
    jobStatusReadyForDelivery,
    jobStatusDelivered,
    jobStatusCancelled,
  ];

  // Inspection Condition Options
  static const String conditionGood = 'Good';
  static const String conditionAverage = 'Average';
  static const String conditionDamaged = 'Damaged';
  static const String conditionNeedsAttention = 'Needs Attention';

  static const List<String> inspectionConditions = [
    conditionGood,
    conditionAverage,
    conditionDamaged,
    conditionNeedsAttention,
  ];

  // Inspection Inspection Areas
  static const List<String> exteriorAreas = [
    'Front Bumper',
    'Rear Bumper',
    'Bonnet / Hood',
    'Roof',
    'Boot / Trunk',
    'Left Front Door',
    'Left Rear Door',
    'Right Front Door',
    'Right Rear Door',
    'Windshield & Glass',
    'Headlights & Taillights',
    'Wheels & Tires',
  ];

  static const List<String> interiorAreas = [
    'Driver Seat',
    'Passenger Seat',
    'Rear Seats',
    'Dashboard & Console',
    'Steering Wheel',
    'Floor & Carpets',
    'Roof Lining',
    'Door Panels',
  ];

  static const List<String> engineAreas = [
    'Engine Condition',
    'Oil Leakage',
    'Battery & Wiring',
    'Fluid Levels & Radiator',
  ];

  // Attendance Statuses
  static const String attendancePresent = 'Present';
  static const String attendanceAbsent = 'Absent';
  static const String attendanceHalfDay = 'Half Day';
  static const String attendanceLeave = 'Leave';

  static const List<String> attendanceStatuses = [
    attendancePresent,
    attendanceAbsent,
    attendanceHalfDay,
    attendanceLeave,
  ];

  // Salary Types
  static const String salaryTypeMonthly = 'Monthly';
  static const String salaryTypeDaily = 'Daily';
  static const String salaryTypeWeekly = 'Weekly';
  static const String salaryTypeCommission = 'Commission';
  static const String salaryTypeMixed = 'Mixed';

  static const List<String> salaryTypes = [
    salaryTypeMonthly,
    salaryTypeDaily,
    salaryTypeWeekly,
    salaryTypeCommission,
    salaryTypeMixed,
  ];

  // Staff Expense Categories
  static const List<String> staffExpenseCategories = [
    'Salary',
    'Advance',
    'Bonus',
    'Overtime',
    'Commission',
    'Loan',
    'Other',
  ];

  // Center Expense Categories
  static const List<String> centerExpenseCategories = [
    'Electricity',
    'Water',
    'Rent',
    'Internet',
    'Equipment',
    'Equipment Maintenance',
    'Cleaning Supplies',
    'Chemicals',
    'Office Expenses',
    'Fuel',
    'Marketing',
    'Repairs',
    'Other',
  ];

  // Payment Methods
  static const String paymentCash = 'Cash';
  static const String paymentBankTransfer = 'Bank Transfer';
  static const String paymentCard = 'Card';
  static const String paymentOther = 'Other';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentBankTransfer,
    paymentCard,
    paymentOther,
  ];

  // Payment Status
  static const String paymentStatusUnpaid = 'Unpaid';
  static const String paymentStatusPartial = 'Partial';
  static const String paymentStatusPaid = 'Paid';

  // Stock Adjustment Reasons
  static const List<String> stockAdjustmentReasons = [
    'Damaged',
    'Expired',
    'Missing',
    'Correction',
    'Manual Increase',
    'Manual Decrease',
  ];

  // Default Detailing Services
  static const List<Map<String, dynamic>> defaultServices = [
    {'name': 'Car Wash & Foam Bath', 'price': 1500.0, 'durationMinutes': 45},
    {'name': 'Exterior Detailing & Wax', 'price': 5000.0, 'durationMinutes': 120},
    {'name': 'Interior Deep Detailing', 'price': 6000.0, 'durationMinutes': 150},
    {'name': 'Full Detailing (Interior + Exterior)', 'price': 10000.0, 'durationMinutes': 240},
    {'name': 'Ceramic Coating (1 Year)', 'price': 25000.0, 'durationMinutes': 360},
    {'name': 'Ceramic Coating (3 Year)', 'price': 45000.0, 'durationMinutes': 480},
    {'name': 'Multi-Stage Paint Correction', 'price': 15000.0, 'durationMinutes': 300},
    {'name': 'Paint Protection Film (PPF)', 'price': 80000.0, 'durationMinutes': 600},
    {'name': 'Engine Bay Detailing', 'price': 3000.0, 'durationMinutes': 60},
    {'name': 'Headlight Restoration', 'price': 2500.0, 'durationMinutes': 60},
    {'name': 'Glass Treatment & Rain Repellent', 'price': 3500.0, 'durationMinutes': 60},
    {'name': 'Leather Conditioning & Protection', 'price': 4000.0, 'durationMinutes': 90},
  ];

  // Firestore Collection Names
  static const String colBusinesses = 'businesses';
  static const String colUsers = 'users';
  static const String colCustomers = 'customers';
  static const String colVehicles = 'vehicles';
  static const String colInspections = 'inspections';
  static const String colServices = 'services';
  static const String colJobs = 'jobs';
  static const String colStaff = 'staff';
  static const String colAttendance = 'attendance';
  static const String colSalaries = 'salaries';
  static const String colStaffExpenses = 'staff_expenses';
  static const String colGarageExpenses = 'garage_expenses';
  static const String colCenterExpenses = 'garage_expenses'; // alias
  static const String colServiceRecords = 'service_records';
  static const String colInventoryItems = 'inventory_items';
  static const String colInventoryBatches = 'inventory_batches';
  static const String colInventoryTransactions = 'inventory_transactions';
  static const String colStockPurchases = 'stock_purchases';
  static const String colStockSales = 'stock_sales';
  static const String colSuppliers = 'suppliers';
  static const String colSupplierReturns = 'supplier_returns';
  static const String colInvoices = 'invoices';
  static const String colPayments = 'payments';
  static const String colNotifications = 'notifications';
  static const String colDevices = 'devices';
  static const String colSettings = 'settings';
  static const String colAuditLogs = 'audit_logs';
}
