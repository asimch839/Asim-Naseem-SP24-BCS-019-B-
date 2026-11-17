import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/showroom_car_model.dart';

class ShowroomRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Fetch all showroom cars with optional status, deal type, and search filters
  Future<List<ShowroomCarModel>> getCars({
    String? status,
    String? dealType,
    String? searchQuery,
  }) async {
    final db = await _db;
    String sql = 'SELECT * FROM showroom_cars WHERE is_deleted = 0';
    final List<dynamic> args = [];

    if (status != null && status != 'All') {
      sql += ' AND status = ?';
      args.add(status);
    }

    if (dealType != null && dealType != 'All') {
      sql += ' AND deal_type = ?';
      args.add(dealType);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ''' AND (
        LOWER(make) LIKE ? OR
        LOWER(model) LIKE ? OR
        LOWER(variant) LIKE ? OR
        LOWER(registration_number) LIKE ? OR
        LOWER(color) LIKE ? OR
        LOWER(seller_name) LIKE ? OR
        LOWER(buyer_name) LIKE ?
      )''';
      args.addAll([q, q, q, q, q, q, q]);
    }

    sql += ' ORDER BY created_at DESC';

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => ShowroomCarModel.fromMap(r)).toList();
  }

  /// KPI Summary for Showroom & Car Deals
  Future<Map<String, dynamic>> getShowroomKPIs() async {
    final db = await _db;

    // Available cars on floor
    final availRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(purchase_price + extra_expenses), 0.0) as total_cost,
        COALESCE(SUM(demand_price), 0.0) as total_demand
      FROM showroom_cars
      WHERE is_deleted = 0 AND status = 'Available'
    ''');
    final availCount = (availRes.first['count'] as num?)?.toInt() ?? 0;
    final totalInventoryCost = (availRes.first['total_cost'] as num?)?.toDouble() ?? 0.0;
    final totalDemandValue = (availRes.first['total_demand'] as num?)?.toDouble() ?? 0.0;

    // Sold cars and realized profit
    final soldRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(sold_price), 0.0) as total_sold_volume,
        COALESCE(SUM(profit_amount), 0.0) as total_profit,
        COALESCE(SUM(commission_amount), 0.0) as total_commission
      FROM showroom_cars
      WHERE is_deleted = 0 AND status = 'Sold'
    ''');
    final soldCount = (soldRes.first['count'] as num?)?.toInt() ?? 0;
    final totalSoldVolume = (soldRes.first['total_sold_volume'] as num?)?.toDouble() ?? 0.0;
    final totalProfitEarned = (soldRes.first['total_profit'] as num?)?.toDouble() ?? 0.0;
    final totalCommissionEarned = (soldRes.first['total_commission'] as num?)?.toDouble() ?? 0.0;

    // Booked / Token cars
    final bookedRes = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(token_amount), 0.0) as tokens
      FROM showroom_cars
      WHERE is_deleted = 0 AND status = 'Booked'
    ''');
    final bookedCount = (bookedRes.first['count'] as num?)?.toInt() ?? 0;
    final totalTokens = (bookedRes.first['tokens'] as num?)?.toDouble() ?? 0.0;

    return {
      'available_count': availCount,
      'total_inventory_cost': totalInventoryCost,
      'total_demand_value': totalDemandValue,
      'sold_count': soldCount,
      'total_sold_volume': totalSoldVolume,
      'total_profit_earned': totalProfitEarned,
      'total_commission_earned': totalCommissionEarned,
      'total_car_trading_income': totalProfitEarned,
      'booked_count': bookedCount,
      'total_tokens': totalTokens,
    };
  }

  /// Save new or updated car
  Future<String> saveCar(ShowroomCarModel car) async {
    final db = await _db;
    final id = car.id.isEmpty ? 'car_${const Uuid().v4().substring(0, 8)}' : car.id;
    final updatedCar = car.copyWith(id: id, updatedAt: DateTime.now());

    await db.insert(
      'showroom_cars',
      updatedCar.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Mark car as Sold and record buyer & seller commissions as income
  Future<bool> markAsSold({
    required String id,
    required double soldPrice,
    required String buyerName,
    required String buyerPhone,
    String? buyerCnic,
    required DateTime saleDate,
    double buyerCommission = 0.0,
    double sellerCommission = 0.0,
    double? commissionAmount,
    String paymentMethod = 'Cash',
    String? notes,
  }) async {
    final db = await _db;
    final existing = await getCarById(id);
    if (existing == null) return false;

    final totalComm = (buyerCommission > 0 || sellerCommission > 0)
        ? (buyerCommission + sellerCommission)
        : (commissionAmount ?? 0.0);

    final count = await db.update(
      'showroom_cars',
      {
        'status': 'Sold',
        'sold_price': soldPrice,
        'sale_date': saleDate.toIso8601String(),
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_cnic': buyerCnic,
        'buyer_commission': buyerCommission,
        'seller_commission': sellerCommission,
        'commission_amount': totalComm,
        'profit_amount': totalComm, // Strictly commission is the dealership profit/income
        'payment_method': paymentMethod,
        'notes': notes ?? existing.notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Mark car as Booked (Token advance received)
  Future<bool> markAsBooked({
    required String id,
    required double tokenAmount,
    required String buyerName,
    required String buyerPhone,
    String? notes,
  }) async {
    final db = await _db;
    final count = await db.update(
      'showroom_cars',
      {
        'status': 'Booked',
        'token_amount': tokenAmount,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Delete / Soft-delete car
  Future<bool> deleteCar(String id) async {
    final db = await _db;
    final count = await db.update(
      'showroom_cars',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Get single car by ID
  Future<ShowroomCarModel?> getCarById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'showroom_cars',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShowroomCarModel.fromMap(rows.first);
  }
}

