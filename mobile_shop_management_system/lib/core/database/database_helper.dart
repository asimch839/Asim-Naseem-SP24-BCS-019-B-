import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/phone_item.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/repair_job.dart';
import '../models/payment_record.dart';
import '../models/expense.dart';
import '../models/stock_movement.dart';
import '../models/warranty.dart';
import '../models/audit_log.dart';
import '../models/business_settings.dart';
import 'sample_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mobile_shop_lab_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(join(docDir.path, 'MobileShopLab'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      dbPath = join(appDir.path, filePath);
    } catch (_) {
      // Fallback for test environments or permission limits
      final currentDir = Directory.current.path;
      dbPath = join(currentDir, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        phone TEXT,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        alternate_phone TEXT,
        address TEXT,
        email TEXT,
        notes TEXT,
        total_purchases REAL NOT NULL DEFAULT 0.0,
        total_repairs INTEGER NOT NULL DEFAULT 0,
        total_paid REAL NOT NULL DEFAULT 0.0,
        total_due REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');

    // Suppliers
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        notes TEXT,
        total_purchases REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        due_amount REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        min_stock_alert INTEGER NOT NULL DEFAULT 3,
        warranty_months INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    // Phone Items (IMEI Inventory)
    await db.execute('''
      CREATE TABLE phone_items (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        variant TEXT,
        ram TEXT,
        storage TEXT,
        color TEXT,
        pta_status TEXT NOT NULL,
        imei1 TEXT NOT NULL UNIQUE,
        imei2 TEXT,
        serial_number TEXT,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        customer_id TEXT,
        customer_name TEXT,
        purchase_date TEXT NOT NULL,
        sold_date TEXT,
        sale_invoice_number TEXT,
        warranty_period TEXT,
        condition TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_phones_imei1 ON phone_items(imei1)');
    await db.execute('CREATE INDEX idx_phones_status ON phone_items(status)');

    // Sales
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        sale_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        tax REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        paid_amount REAL NOT NULL,
        due_amount REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT NOT NULL,
        payment_breakdown TEXT,
        cashier_id TEXT,
        cashier_name TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        items_json TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_invoice ON sales(invoice_number)');

    // Purchases
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL,
        due_amount REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        items_json TEXT NOT NULL
      )
    ''');

    // Repair Jobs
    await db.execute('''
      CREATE TABLE repair_jobs (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL UNIQUE,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        customer_alt_phone TEXT,
        customer_address TEXT,
        device_brand TEXT NOT NULL,
        device_model TEXT NOT NULL,
        imei TEXT,
        serial_number TEXT,
        color TEXT,
        device_condition TEXT,
        reported_problem TEXT NOT NULL,
        technician_notes TEXT,
        accessories_received TEXT,
        lock_pin_or_password TEXT,
        estimated_cost REAL NOT NULL DEFAULT 0.0,
        advance_paid REAL NOT NULL DEFAULT 0.0,
        labor_charges REAL NOT NULL DEFAULT 0.0,
        other_charges REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        final_total REAL NOT NULL DEFAULT 0.0,
        remaining_due REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        technician_id TEXT,
        technician_name TEXT,
        expected_delivery_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        delivered_at TEXT,
        parts_used_json TEXT,
        history_json TEXT
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_repairs_job_id ON repair_jobs(job_id)');
    await db.execute('CREATE INDEX idx_repairs_status ON repair_jobs(status)');

    // Payment Records
    await db.execute('''
      CREATE TABLE payment_records (
        id TEXT PRIMARY KEY,
        receipt_number TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        reference_id TEXT,
        entity_id TEXT NOT NULL,
        entity_name TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        collected_by TEXT
      )
    ''');

    // Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        recorded_by TEXT
      )
    ''');

    // Stock Movements
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        imei TEXT,
        movement_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_stock INTEGER NOT NULL,
        new_stock INTEGER NOT NULL,
        reference_id TEXT,
        date TEXT NOT NULL,
        reason TEXT,
        performed_by TEXT
      )
    ''');

    // Warranties
    await db.execute('''
      CREATE TABLE warranties (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        item_name TEXT NOT NULL,
        imei TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        warranty_terms TEXT,
        status TEXT NOT NULL,
        claims_json TEXT
      )
    ''');

    // Audit Logs
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        action TEXT NOT NULL,
        module TEXT NOT NULL,
        record_id TEXT,
        details TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Business Settings
    await db.execute('''
      CREATE TABLE business_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        shop_name TEXT NOT NULL,
        tagline TEXT,
        address TEXT,
        phone TEXT,
        alt_phone TEXT,
        email TEXT,
        ntn TEXT,
        currency TEXT NOT NULL DEFAULT 'Rs.',
        invoice_prefix TEXT NOT NULL DEFAULT 'INV-',
        repair_prefix TEXT NOT NULL DEFAULT 'REP-',
        purchase_prefix TEXT NOT NULL DEFAULT 'PUR-',
        receipt_prefix TEXT NOT NULL DEFAULT 'REC-',
        invoice_footer TEXT,
        terms_and_conditions TEXT,
        receipt_format TEXT NOT NULL DEFAULT 'a4',
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        auto_backup_enabled INTEGER NOT NULL DEFAULT 1,
        default_warranty_days INTEGER NOT NULL DEFAULT 365
      )
    ''');

    // Seed Sample Data
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    final batch = db.batch();

    // Business Settings
    batch.insert('business_settings', {'id': 1, ...SampleData.settings.toMap()});

    // Default Admin User
    for (var u in SampleData.users) {
      batch.insert('users', u.toMap());
    }

    await batch.commit(noResult: true);
  }

  // -------------------------------------------------------------
  // Data Queries and Operations
  // -------------------------------------------------------------

  // Settings
  Future<BusinessSettings> getSettings() async {
    final db = await database;
    final res = await db.query('business_settings', limit: 1);
    if (res.isNotEmpty) {
      return BusinessSettings.fromMap(res.first);
    }
    return BusinessSettings();
  }

  Future<void> updateSettings(BusinessSettings settings) async {
    final db = await database;
    await db.update(
      'business_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Users
  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'name ASC');
    return res.map((m) => AppUser.fromMap(m)).toList();
  }

  Future<void> insertUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final res = await db.query('customers', orderBy: 'name ASC');
    return res.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final res = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Customer.fromMap(res.first);
    return null;
  }

  Future<Customer?> findCustomerByPhone(String phone) async {
    final db = await database;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final res = await db.query('customers');
    for (var row in res) {
      final custPhone = (row['phone'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (custPhone.isNotEmpty && (custPhone == clean || custPhone.contains(clean))) {
        return Customer.fromMap(row);
      }
    }
    return null;
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Suppliers
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final res = await db.query('suppliers', orderBy: 'name ASC');
    return res.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<void> insertSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert('suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await database;
    await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // Products
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final res = await db.query('products', orderBy: 'name ASC');
    return res.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustProductStock(
    String productId,
    int delta,
    String reason,
    String performedBy,
  ) async {
    final db = await database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (res.isNotEmpty) {
      final p = Product.fromMap(res.first);
      final newQty = (p.stockQuantity + delta).clamp(0, 999999);
      await db.update('products', {'stock_quantity': newQty}, where: 'id = ?', whereArgs: [productId]);

      final movement = StockMovement(
        id: 'SM-${DateTime.now().millisecondsSinceEpoch}',
        productId: p.id,
        productName: p.name,
        movementType: delta >= 0 ? 'adjustment_add' : (reason.toLowerCase().contains('damaged') ? 'damaged' : 'adjustment_remove'),
        quantity: delta.abs(),
        previousStock: p.stockQuantity,
        newStock: newQty,
        reason: reason,
        performedBy: performedBy,
      );
      await db.insert('stock_movements', movement.toMap());
    }
  }

  // Phone Items (IMEIs)
  Future<List<PhoneItem>> getAllPhoneItems() async {
    final db = await database;
    final res = await db.query('phone_items', orderBy: 'purchase_date DESC');
    return res.map((m) => PhoneItem.fromMap(m)).toList();
  }

  Future<PhoneItem?> findPhoneByImei(String imei) async {
    final db = await database;
    final clean = imei.trim();
    final res = await db.query(
      'phone_items',
      where: 'imei1 = ? OR imei2 = ?',
      whereArgs: [clean, clean],
    );
    if (res.isNotEmpty) return PhoneItem.fromMap(res.first);
    return null;
  }

  Future<void> insertPhoneItem(PhoneItem phone) async {
    final db = await database;
    await db.insert('phone_items', phone.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePhoneItem(PhoneItem phone) async {
    final db = await database;
    await db.update('phone_items', phone.toMap(), where: 'id = ?', whereArgs: [phone.id]);
  }

  // Sales
  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final res = await db.query('sales', orderBy: 'sale_date DESC');
    return res.map((m) => Sale.fromMap(m)).toList();
  }

  Future<void> insertSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('sales', sale.toMap());

      // Deduct inventory & record movement for each item
      for (var item in sale.items) {
        if (item.productType == 'phone' && item.imei.isNotEmpty) {
          // Mark phone as Sold
          await txn.update(
            'phone_items',
            {
              'status': 'Sold',
              'sold_date': sale.saleDate.toIso8601String(),
              'sale_invoice_number': sale.invoiceNumber,
              'customer_id': sale.customerId,
              'customer_name': sale.customerName,
            },
            where: 'imei1 = ? OR imei2 = ?',
            whereArgs: [item.imei, item.imei],
          );
        }

        // Deduct general product stock
        final prodRes = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
        if (prodRes.isNotEmpty) {
          final prod = Product.fromMap(prodRes.first);
          final newQty = (prod.stockQuantity - item.quantity).clamp(0, 999999);
          await txn.update('products', {'stock_quantity': newQty}, where: 'id = ?', whereArgs: [item.productId]);

          final move = StockMovement(
            id: 'SM-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
            productId: item.productId,
            productName: item.productName,
            imei: item.imei,
            movementType: 'sale',
            quantity: item.quantity,
            previousStock: prod.stockQuantity,
            newStock: newQty,
            referenceId: sale.invoiceNumber,
            reason: 'Sale #${sale.invoiceNumber}',
            performedBy: sale.cashierName,
          );
          await txn.insert('stock_movements', move.toMap());
        }

        // Add warranty if applicable
        if (item.warrantyMonths > 0) {
          final war = WarrantyRecord(
            id: 'WAR-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
            type: item.productType,
            referenceId: sale.invoiceNumber,
            customerId: sale.customerId,
            customerName: sale.customerName,
            customerPhone: sale.customerPhone,
            itemName: item.productName,
            imei: item.imei,
            startDate: sale.saleDate,
            endDate: sale.saleDate.add(Duration(days: item.warrantyMonths * 30)),
            warrantyTerms: '${item.warrantyMonths} Months Official Warranty',
            status: 'Active',
          );
          await txn.insert('warranties', war.toMap());
        }
      }

      // Update customer ledger
      if (sale.customerId.isNotEmpty) {
        final custRes = await txn.query('customers', where: 'id = ?', whereArgs: [sale.customerId]);
        if (custRes.isNotEmpty) {
          final cust = Customer.fromMap(custRes.first);
          await txn.update(
            'customers',
            {
              'total_purchases': cust.totalPurchases + sale.grandTotal,
              'total_paid': cust.totalPaid + sale.paidAmount,
              'total_due': cust.totalDue + sale.dueAmount,
            },
            where: 'id = ?',
            whereArgs: [cust.id],
          );
        }
      }

      // Record Audit Log
      final log = AuditLog(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        userId: sale.cashierId,
        userName: sale.cashierName,
        action: 'Sale Created',
        module: 'POS / Sales',
        recordId: sale.invoiceNumber,
        details: 'Invoice #${sale.invoiceNumber} created. Grand Total: Rs. ${sale.grandTotal}, Paid: Rs. ${sale.paidAmount}, Due: Rs. ${sale.dueAmount}',
      );
      await txn.insert('audit_logs', log.toMap());
    });
  }

  // Purchases
  Future<List<Purchase>> getAllPurchases() async {
    final db = await database;
    final res = await db.query('purchases', orderBy: 'purchase_date DESC');
    return res.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<void> insertPurchase(Purchase purchase) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('purchases', purchase.toMap());

      // Update inventory and add phone items
      for (var item in purchase.items) {
        final prodRes = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
        int prevStock = 0;
        if (prodRes.isNotEmpty) {
          final p = Product.fromMap(prodRes.first);
          prevStock = p.stockQuantity;
          final newQty = p.stockQuantity + item.quantity;
          await txn.update(
            'products',
            {
              'stock_quantity': newQty,
              'purchase_price': item.purchasePrice,
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }

        // Add IMEIs to phone_items if phones
        if (item.productType == 'phone' && item.imeiList.isNotEmpty) {
          for (var imei in item.imeiList) {
            final ph = PhoneItem(
              id: 'PHN-${DateTime.now().millisecondsSinceEpoch}-${imei.hashCode.abs()}',
              productId: item.productId,
              brand: prodRes.isNotEmpty ? prodRes.first['brand'] as String? ?? 'General' : 'General',
              model: item.productName,
              imei1: imei,
              purchasePrice: item.purchasePrice,
              salePrice: prodRes.isNotEmpty ? (prodRes.first['sale_price'] as num?)?.toDouble() ?? (item.purchasePrice * 1.1) : (item.purchasePrice * 1.1),
              supplierId: purchase.supplierId,
              supplierName: purchase.supplierName,
              purchaseDate: purchase.purchaseDate,
              condition: 'New',
              status: 'In Stock',
            );
            await txn.insert('phone_items', ph.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final move = StockMovement(
          id: 'SM-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
          productId: item.productId,
          productName: item.productName,
          movementType: 'purchase',
          quantity: item.quantity,
          previousStock: prevStock,
          newStock: prevStock + item.quantity,
          referenceId: purchase.invoiceNumber,
          reason: 'Supplier Purchase #${purchase.invoiceNumber}',
          performedBy: 'Staff',
        );
        await txn.insert('stock_movements', move.toMap());
      }

      // Update supplier ledger
      if (purchase.supplierId.isNotEmpty) {
        final supRes = await txn.query('suppliers', where: 'id = ?', whereArgs: [purchase.supplierId]);
        if (supRes.isNotEmpty) {
          final sup = Supplier.fromMap(supRes.first);
          await txn.update(
            'suppliers',
            {
              'total_purchases': sup.totalPurchases + purchase.totalAmount,
              'paid_amount': sup.paidAmount + purchase.paidAmount,
              'due_amount': sup.dueAmount + purchase.dueAmount,
            },
            where: 'id = ?',
            whereArgs: [sup.id],
          );
        }
      }
    });
  }

  // Repairs
  Future<List<RepairJob>> getAllRepairs() async {
    final db = await database;
    final res = await db.query('repair_jobs', orderBy: 'created_at DESC');
    return res.map((m) => RepairJob.fromMap(m)).toList();
  }

  Future<void> insertRepair(RepairJob job) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('repair_jobs', job.toMap());

      // Update customer totalRepairs count
      if (job.customerId.isNotEmpty) {
        final custRes = await txn.query('customers', where: 'id = ?', whereArgs: [job.customerId]);
        if (custRes.isNotEmpty) {
          final c = Customer.fromMap(custRes.first);
          await txn.update('customers', {'total_repairs': c.totalRepairs + 1}, where: 'id = ?', whereArgs: [c.id]);
        }
      }

      // Deduct parts stock if any parts were attached on creation
      for (var part in job.partsUsed) {
        final pRes = await txn.query('products', where: 'id = ?', whereArgs: [part.productId]);
        if (pRes.isNotEmpty) {
          final p = Product.fromMap(pRes.first);
          final newQty = (p.stockQuantity - part.quantity).clamp(0, 999999);
          await txn.update('products', {'stock_quantity': newQty}, where: 'id = ?', whereArgs: [p.id]);

          final move = StockMovement(
            id: 'SM-${DateTime.now().millisecondsSinceEpoch}-${part.id}',
            productId: p.id,
            productName: p.name,
            movementType: 'repair_use',
            quantity: part.quantity,
            previousStock: p.stockQuantity,
            newStock: newQty,
            referenceId: job.jobId,
            reason: 'Consumed in Job #${job.jobId}',
            performedBy: job.technicianName,
          );
          await txn.insert('stock_movements', move.toMap());
        }
      }

      // Add audit log
      final log = AuditLog(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        userId: job.technicianId,
        userName: job.technicianName,
        action: 'Repair Job Created',
        module: 'Repair Lab',
        recordId: job.jobId,
        details: 'Job #${job.jobId} created for ${job.customerName} (${job.deviceBrand} ${job.deviceModel}). Problem: ${job.reportedProblem}',
      );
      await txn.insert('audit_logs', log.toMap());
    });
  }

  Future<void> updateRepair(RepairJob job) async {
    final db = await database;
    await db.update('repair_jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  // Payments
  Future<List<PaymentRecord>> getAllPayments() async {
    final db = await database;
    final res = await db.query('payment_records', orderBy: 'payment_date DESC');
    return res.map((m) => PaymentRecord.fromMap(m)).toList();
  }

  Future<void> recordPayment(PaymentRecord payment) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('payment_records', payment.toMap());

      if (payment.type == 'customer_due_payment') {
        final custRes = await txn.query('customers', where: 'id = ?', whereArgs: [payment.entityId]);
        if (custRes.isNotEmpty) {
          final c = Customer.fromMap(custRes.first);
          final newDue = (c.totalDue - payment.amount).clamp(0.0, double.infinity);
          final newPaid = c.totalPaid + payment.amount;
          await txn.update('customers', {'total_due': newDue, 'total_paid': newPaid}, where: 'id = ?', whereArgs: [c.id]);
        }
      } else if (payment.type == 'supplier_due_payment') {
        final supRes = await txn.query('suppliers', where: 'id = ?', whereArgs: [payment.entityId]);
        if (supRes.isNotEmpty) {
          final s = Supplier.fromMap(supRes.first);
          final newDue = (s.dueAmount - payment.amount).clamp(0.0, double.infinity);
          final newPaid = s.paidAmount + payment.amount;
          await txn.update('suppliers', {'due_amount': newDue, 'paid_amount': newPaid}, where: 'id = ?', whereArgs: [s.id]);
        }
      }
    });
  }

  // Expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final res = await db.query('expenses', orderBy: 'date DESC');
    return res.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Stock Movements
  Future<List<StockMovement>> getAllStockMovements() async {
    final db = await database;
    final res = await db.query('stock_movements', orderBy: 'date DESC');
    return res.map((m) => StockMovement.fromMap(m)).toList();
  }

  // Warranties
  Future<List<WarrantyRecord>> getAllWarranties() async {
    final db = await database;
    final res = await db.query('warranties', orderBy: 'start_date DESC');
    return res.map((m) => WarrantyRecord.fromMap(m)).toList();
  }

  Future<void> insertWarranty(WarrantyRecord warranty) async {
    final db = await database;
    await db.insert('warranties', warranty.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWarranty(WarrantyRecord warranty) async {
    final db = await database;
    await db.update('warranties', warranty.toMap(), where: 'id = ?', whereArgs: [warranty.id]);
  }

  // Audit Logs
  Future<List<AuditLog>> getAllAuditLogs() async {
    final db = await database;
    final res = await db.query('audit_logs', orderBy: 'timestamp DESC');
    return res.map((m) => AuditLog.fromMap(m)).toList();
  }

  Future<void> addAuditLog(AuditLog log) async {
    final db = await database;
    await db.insert('audit_logs', log.toMap());
  }

  // Complete Database Backup (Export to JSON string)
  Future<String> exportDatabaseToJson() async {
    final db = await database;
    final data = <String, dynamic>{
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'business_settings': await db.query('business_settings'),
      'users': await db.query('users'),
      'customers': await db.query('customers'),
      'suppliers': await db.query('suppliers'),
      'products': await db.query('products'),
      'phone_items': await db.query('phone_items'),
      'sales': await db.query('sales'),
      'purchases': await db.query('purchases'),
      'repair_jobs': await db.query('repair_jobs'),
      'payment_records': await db.query('payment_records'),
      'expenses': await db.query('expenses'),
      'stock_movements': await db.query('stock_movements'),
      'warranties': await db.query('warranties'),
      'audit_logs': await db.query('audit_logs'),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Complete Database Restore from JSON string
  Future<void> restoreDatabaseFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      // Clear current data safely
      final tables = [
        'users',
        'customers',
        'suppliers',
        'products',
        'phone_items',
        'sales',
        'purchases',
        'repair_jobs',
        'payment_records',
        'expenses',
        'stock_movements',
        'warranties',
        'audit_logs',
        'business_settings',
      ];

      for (var table in tables) {
        await txn.delete(table);
        if (data[table] != null && data[table] is List) {
          final rows = data[table] as List;
          for (var row in rows) {
            await txn.insert(table, row as Map<String, dynamic>);
          }
        }
      }
    });
  }
}
