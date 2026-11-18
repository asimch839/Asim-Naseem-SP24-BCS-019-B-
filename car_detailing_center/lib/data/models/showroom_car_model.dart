class ShowroomCarModel {
  final String id;
  final String dealType; // 'inventory' (Showroom Car) or 'commission' (Commission / Brokerage Deal)
  final String carName; // e.g. Civic, Corolla, Sportage
  final String model; // e.g. 2022, 2024, Rebirth, Grande
  final int year; // integer year parsed from model or created
  final String registrationNumber; // Plate #
  final String customerName; // Customer / Owner / Client Name
  final String customerPhone; // Customer Phone / Mobile Number
  final double demandPrice; // Demand Price (PKR)
  final double customerPrice; // Customer Price / Offer (PKR)
  final double soldPrice; // Final Sold Price when closed
  final DateTime? saleDate;
  final String? buyerName; // Buyer Name when sold
  final String? buyerPhone; // Buyer Phone when sold
  final double buyerCommission; // Commission received from Buyer (PKR)
  final double sellerCommission; // Commission received from Seller (PKR)
  final double commissionAmount; // Total commission (buyer + seller)
  final double profitAmount; // Realized commission/profit for business income
  final String status; // 'Available', 'Booked', 'Sold'
  final double tokenAmount; // Token advance if booked
  final String? color; // Car Exterior Color (e.g. White, Black, Silver)
  final String? condition; // Vehicle condition (e.g. Total Genuine, 2 Pieces Touchup, Shower)
  final String? notes;
  final String paymentMethod;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShowroomCarModel({
    required this.id,
    this.dealType = 'inventory',
    required this.carName,
    required this.model,
    int? year,
    required this.registrationNumber,
    required this.customerName,
    required this.customerPhone,
    this.demandPrice = 0.0,
    this.customerPrice = 0.0,
    this.soldPrice = 0.0,
    this.saleDate,
    this.buyerName,
    this.buyerPhone,
    this.buyerCommission = 0.0,
    this.sellerCommission = 0.0,
    this.commissionAmount = 0.0,
    this.profitAmount = 0.0,
    this.status = 'Available',
    this.tokenAmount = 0.0,
    this.color,
    this.condition,
    this.notes,
    this.paymentMethod = 'Cash',
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : year = year ?? (int.tryParse(model.replaceAll(RegExp(r'[^0-9]'), '')) ?? DateTime.now().year),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayName => '$carName ($model)';
  String get make => carName; // alias for compatibility
  String get sellerName => customerName; // alias
  String get sellerPhone => customerPhone; // alias
  double get totalCommission => (buyerCommission > 0 || sellerCommission > 0)
      ? (buyerCommission + sellerCommission)
      : commissionAmount;
  int get mileage => 0;
  String get transmission => 'Automatic';
  String get fuelType => 'Petrol';
  String? get registrationCity => null;
  String? get conditionGrade => condition;
  String? get features => null;
  String? get documentsStatus => null;
  String? get buyerCnic => null;
  String? get engineCapacity => null;
  String? get commissionPayer => null;

  double get purchasePrice => customerPrice;
  double get extraExpenses => 0.0;
  double get totalInvestmentCost => customerPrice;
  double get expectedProfit => 0.0; // Demand and Customer Price are not added to profit

  bool get isSold => status == 'Sold';
  bool get isAvailable => status == 'Available';
  bool get isBooked => status == 'Booked';
  bool get isCommission => dealType == 'commission';

  double get effectiveProfit => isSold ? (profitAmount > 0 ? profitAmount : totalCommission) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deal_type': dealType,
      'make': carName,
      'car_name': carName,
      'model': model,
      'year': year,
      'registration_number': registrationNumber,
      'color': color,
      'condition_grade': condition,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'seller_name': customerName,
      'seller_phone': customerPhone,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_commission': buyerCommission,
      'seller_commission': sellerCommission,
      'demand_price': demandPrice,
      'customer_price': customerPrice,
      'purchase_price': customerPrice,
      'sold_price': soldPrice,
      'sale_date': saleDate?.toIso8601String(),
      'commission_amount': totalCommission,
      'profit_amount': effectiveProfit,
      'status': status,
      'token_amount': tokenAmount,
      'notes': notes,
      'payment_method': paymentMethod,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShowroomCarModel.fromMap(Map<String, dynamic> map) {
    final cName = map['car_name']?.toString() ?? map['make']?.toString() ?? 'Car';
    final custName = map['customer_name']?.toString() ?? map['seller_name']?.toString() ?? map['buyer_name']?.toString() ?? 'Customer';
    final custPhone = map['customer_phone']?.toString() ?? map['seller_phone']?.toString() ?? map['buyer_phone']?.toString() ?? '';
    final custPrice = (map['customer_price'] as num?)?.toDouble() ?? (map['purchase_price'] as num?)?.toDouble() ?? 0.0;
    final dPrice = (map['demand_price'] as num?)?.toDouble() ?? 0.0;
    final sPrice = (map['sold_price'] as num?)?.toDouble() ?? 0.0;
    final buyerComm = (map['buyer_commission'] as num?)?.toDouble() ?? 0.0;
    final sellerComm = (map['seller_commission'] as num?)?.toDouble() ?? 0.0;
    final commAmt = (map['commission_amount'] as num?)?.toDouble() ?? (buyerComm + sellerComm);
    final pAmt = (map['profit_amount'] as num?)?.toDouble() ?? commAmt;

    return ShowroomCarModel(
      id: map['id']?.toString() ?? '',
      dealType: map['deal_type']?.toString() ?? 'inventory',
      carName: cName,
      model: map['model']?.toString() ?? (map['year']?.toString() ?? ''),
      year: (map['year'] as num?)?.toInt(),
      registrationNumber: map['registration_number']?.toString() ?? '',
      color: map['color']?.toString(),
      condition: map['condition_grade']?.toString() ?? map['condition']?.toString(),
      customerName: custName,
      customerPhone: custPhone,
      demandPrice: dPrice,
      customerPrice: custPrice,
      soldPrice: sPrice,
      saleDate: map['sale_date'] != null ? DateTime.tryParse(map['sale_date'].toString()) : null,
      buyerName: map['buyer_name']?.toString(),
      buyerPhone: map['buyer_phone']?.toString(),
      buyerCommission: buyerComm,
      sellerCommission: sellerComm,
      commissionAmount: commAmt,
      profitAmount: pAmt,
      status: map['status']?.toString() ?? 'Available',
      tokenAmount: (map['token_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes']?.toString(),
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      isDeleted: (map['is_deleted'] == 1 || map['is_deleted'] == true),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }


  ShowroomCarModel copyWith({
    String? id,
    String? dealType,
    String? carName,
    String? model,
    int? year,
    String? registrationNumber,
    String? color,
    String? condition,
    String? customerName,
    String? customerPhone,
    double? demandPrice,
    double? customerPrice,
    double? soldPrice,
    DateTime? saleDate,
    String? buyerName,
    String? buyerPhone,
    double? buyerCommission,
    double? sellerCommission,
    double? commissionAmount,
    double? profitAmount,
    String? status,
    double? tokenAmount,
    String? notes,
    String? paymentMethod,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShowroomCarModel(
      id: id ?? this.id,
      dealType: dealType ?? this.dealType,
      carName: carName ?? this.carName,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      color: color ?? this.color,
      condition: condition ?? this.condition,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      demandPrice: demandPrice ?? this.demandPrice,
      customerPrice: customerPrice ?? this.customerPrice,
      soldPrice: soldPrice ?? this.soldPrice,
      saleDate: saleDate ?? this.saleDate,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerCommission: buyerCommission ?? this.buyerCommission,
      sellerCommission: sellerCommission ?? this.sellerCommission,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      status: status ?? this.status,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
