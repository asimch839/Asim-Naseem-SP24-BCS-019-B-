class AppStrings {
  static const String appName = 'Sardar 4 Boys Hostel';
  static const String appTagline = 'Strength | Community | Comfort';
  static const String appVersion = 'v1.0.0 (Offline Edition)';
  static const String logoAsset = 'assets/images/logo.png';
  static const String logoSquareAsset = 'assets/images/logo_square.png';
  
  // Roles
  static const String roleAdmin = 'Admin';
  static const String roleStaff = 'Office Staff';

  // Room Statuses
  static const String roomStatusAvailable = 'Available';
  static const String roomStatusFull = 'Full';
  static const String roomStatusMaintenance = 'Maintenance';

  // Bed Statuses
  static const String bedStatusAvailable = 'Available';
  static const String bedStatusOccupied = 'Occupied';
  static const String bedStatusMaintenance = 'Maintenance';

  // Student Statuses
  static const String studentStatusActive = 'Active';
  static const String studentStatusLeft = 'Left';

  // Payment Statuses
  static const String paymentStatusPaid = 'Paid';
  static const String paymentStatusPartial = 'Partial';
  static const String paymentStatusPending = 'Pending';
  static const String paymentStatusOverdue = 'Overdue';

  // Payment Methods
  static const String paymentMethodCash = 'Cash';
  static const String paymentMethodBank = 'Bank Transfer';
  static const String paymentMethodSecurityDeposit = 'Security Deposit';
  static const String paymentMethodOther = 'Other';

  // Room Types
  static const List<String> roomTypes = [
    'Single',
    'Double',
    'Triple',
    'Four Bed',
    'Other'
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Electricity',
    'Gas',
    'Water',
    'Internet',
    'Maintenance',
    'Cleaning',
    'Staff Salary',
    'Food',
    'Rent',
    'Other'
  ];

  // Software House & Branding
  static const String developerCompany = 'Devnix Limited';
  static const String developerContact = '03007720839';
  static const String developerBrandingFull = 'Software Developed by Devnix Limited • Contact: 03007720839';
  static const String developerBrandingShort = 'Devnix Limited • 03007720839';
}
