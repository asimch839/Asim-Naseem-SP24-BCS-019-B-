import '../../core/constants/app_constants.dart';

class PaymentModel {
  final String id;
  final String businessId;
  final String invoiceId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final double amount;
  final String paymentMethod; // Cash, Bank Transfer, Card, Other
  final String? reference;
  final String? notes;
  final String createdBy;
  final DateTime timestamp;

  PaymentModel({
    required this.id,
    required this.businessId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.paymentMethod = AppConstants.paymentCash,
    this.reference,
    this.notes,
    required this.createdBy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DateTime get paymentDate => timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'notes': notes,
      'createdBy': createdBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      invoiceId: map['invoiceId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? AppConstants.paymentCash,
      reference: map['reference'],
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
