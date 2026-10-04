class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String notes;
  final String recordedBy;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    DateTime? date,
    this.paymentMethod = 'Cash',
    this.notes = '',
    this.recordedBy = '',
  }) : date = date ?? DateTime.now();

  static const List<String> categories = [
    'Rent',
    'Electricity',
    'Internet',
    'Salaries',
    'Transport',
    'Shop Maintenance',
    'Repair Tools',
    'Marketing',
    'Tea & Refreshments',
    'Miscellaneous',
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'recorded_by': recordedBy,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      category: (map['category'] as String?) ?? 'Miscellaneous',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      notes: (map['notes'] as String?) ?? '',
      recordedBy: (map['recorded_by'] as String?) ?? '',
    );
  }
}
