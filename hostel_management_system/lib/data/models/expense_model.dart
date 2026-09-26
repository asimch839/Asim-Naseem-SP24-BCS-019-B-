class ExpenseModel {
  final int? id;
  final String title;
  final String category; // 'Electricity', 'Gas', 'Water', 'Internet', 'Maintenance', 'Cleaning', 'Staff Salary', 'Food', 'Other'
  final double amount;
  final String expenseDate; // YYYY-MM-DD
  final String paymentMethod; // 'Cash', 'Bank Transfer', 'Other'
  final String? description;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.paymentMethod = 'Cash',
    this.description,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'description': description,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: (map['category'] as String?) ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expense_date'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  ExpenseModel copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? expenseDate,
    String? paymentMethod,
    String? description,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
