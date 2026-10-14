import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class BarcodeProductInfo {
  final String barcode;
  final String name;
  final String brand;
  final String model;
  final String category;
  final ProductType type;
  final double purchasePrice;
  final double salePrice;
  final String description;
  final String source;
  final bool isFound;

  const BarcodeProductInfo({
    required this.barcode,
    required this.name,
    this.brand = '',
    this.model = '',
    this.category = 'Chargers',
    this.type = ProductType.accessory,
    this.purchasePrice = 0.0,
    this.salePrice = 0.0,
    this.description = '',
    this.source = 'Unknown',
    this.isFound = false,
  });

  BarcodeProductInfo copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? model,
    String? category,
    ProductType? type,
    double? purchasePrice,
    double? salePrice,
    String? description,
    String? source,
    bool? isFound,
  }) {
    return BarcodeProductInfo(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      type: type ?? this.type,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      description: description ?? this.description,
      source: source ?? this.source,
      isFound: isFound ?? this.isFound,
    );
  }
}

class BarcodeLookupService {
  // Pre-configured rich catalog of genuine mobile accessories, handsets, and repair parts
  static final Map<String, BarcodeProductInfo> _presetCatalog = {
    // Samsung Products
    '8806090558610': const BarcodeProductInfo(
      barcode: '8806090558610',
      name: 'Samsung 25W USB-C Fast Charger (EP-TA800)',
      brand: 'Samsung',
      model: 'EP-TA800',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 1800,
      salePrice: 2600,
      description: 'Super Fast Charging 25W USB Type-C PD 3.0 Adapter',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806090973352': const BarcodeProductInfo(
      barcode: '8806090973352',
      name: 'Samsung 45W Super Fast Charger 2.0 (EP-TA845)',
      brand: 'Samsung',
      model: 'EP-TA845',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 3200,
      salePrice: 4500,
      description: 'Original 45W Fast Charging Power Adapter for Galaxy S24/S23 Ultra',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806091843074': const BarcodeProductInfo(
      barcode: '8806091843074',
      name: 'Samsung Type-C to Type-C 5A Cable (1m)',
      brand: 'Samsung',
      model: 'EP-DN975',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 650,
      salePrice: 1100,
      description: 'Fast Charging 5A 100W Compatible Type-C Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806094892420': const BarcodeProductInfo(
      barcode: '8806094892420',
      name: 'Samsung Galaxy A54 5G (8GB / 256GB)',
      brand: 'Samsung',
      model: 'SM-A546B',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 89000,
      salePrice: 98000,
      description: '6.4" Super AMOLED 120Hz, Exynos 1380, 50MP OIS Camera',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806095308692': const BarcodeProductInfo(
      barcode: '8806095308692',
      name: 'Samsung Galaxy S24 Ultra (12GB / 256GB)',
      brand: 'Samsung',
      model: 'SM-S928B',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 298000,
      salePrice: 325000,
      description: 'Snapdragon 8 Gen 3, Titanium Frame, 200MP Quad Camera, S-Pen',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806095368290': const BarcodeProductInfo(
      barcode: '8806095368290',
      name: 'Samsung Galaxy A15 (6GB / 128GB)',
      brand: 'Samsung',
      model: 'SM-A155F',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 41000,
      salePrice: 46500,
      description: '6.5" 90Hz Super AMOLED, Helio G99, 5000mAh Battery',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8806091234567': const BarcodeProductInfo(
      barcode: '8806091234567',
      name: 'Samsung Galaxy Buds 2 Pro',
      brand: 'Samsung',
      model: 'SM-R510',
      category: 'Earphones',
      type: ProductType.accessory,
      purchasePrice: 28000,
      salePrice: 34500,
      description: 'Active Noise Cancelling 24-bit Hi-Fi Sound True Wireless',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Apple Products
    '194252157015': const BarcodeProductInfo(
      barcode: '194252157015',
      name: 'Apple 20W USB-C Power Adapter',
      brand: 'Apple',
      model: 'MHJE3AM/A',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 3600,
      salePrice: 5200,
      description: 'Original Apple 20W Fast Charging Wall Adapter USB Type-C',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '190198858348': const BarcodeProductInfo(
      barcode: '190198858348',
      name: 'Apple Lightning to USB-C Cable (1m)',
      brand: 'Apple',
      model: 'MM0A3ZM/A',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 2200,
      salePrice: 3400,
      description: 'Official Apple USB-C to Lightning Fast Sync & Charge Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '194253397472': const BarcodeProductInfo(
      barcode: '194253397472',
      name: 'Apple AirPods Pro (2nd Gen) USB-C',
      brand: 'Apple',
      model: 'MTJV3AM/A',
      category: 'Earphones',
      type: ProductType.accessory,
      purchasePrice: 54000,
      salePrice: 63500,
      description: 'H2 Chip, Active Noise Cancellation, Transparency Mode, MagSafe',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '195949038234': const BarcodeProductInfo(
      barcode: '195949038234',
      name: 'Apple iPhone 15 (128GB)',
      brand: 'Apple',
      model: 'A3090',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 218000,
      salePrice: 236000,
      description: 'Dynamic Island, 48MP Main Camera, A16 Bionic, USB-C',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '194253408253': const BarcodeProductInfo(
      barcode: '194253408253',
      name: 'Apple iPhone 14 (128GB)',
      brand: 'Apple',
      model: 'A2882',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 178000,
      salePrice: 196000,
      description: 'Super Retina XDR, A15 Bionic, Cinematic Mode 4K',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '194252697276': const BarcodeProductInfo(
      barcode: '194252697276',
      name: 'Apple iPhone 13 (128GB)',
      brand: 'Apple',
      model: 'A2633',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 148000,
      salePrice: 166000,
      description: 'Super Retina XDR, A15 Bionic, Dual 12MP Camera',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '194253000010': const BarcodeProductInfo(
      barcode: '194253000010',
      name: 'Apple 60W USB-C Woven Charge Cable (1m)',
      brand: 'Apple',
      model: 'MQKJ3AM/A',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 3200,
      salePrice: 4600,
      description: 'Braided Design Type-C Fast Charging Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Xiaomi & Redmi Products
    '6934177749827': const BarcodeProductInfo(
      barcode: '6934177749827',
      name: 'Xiaomi 67W SonicCharge Fast Charger',
      brand: 'Xiaomi',
      model: 'MDY-12-EH',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 2200,
      salePrice: 3200,
      description: 'Turbo Charge 67W Adapter with 6A Type-C Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6934177724213': const BarcodeProductInfo(
      barcode: '6934177724213',
      name: 'Xiaomi 33W Fast Charger Wall Adapter',
      brand: 'Xiaomi',
      model: 'MDY-11-EZ',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 1400,
      salePrice: 2200,
      description: 'QC 3.0 & Turbo Charge 33W Dual Voltage Charger',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6941812757239': const BarcodeProductInfo(
      barcode: '6941812757239',
      name: 'Xiaomi Redmi Note 13 Pro (8GB / 256GB)',
      brand: 'Xiaomi',
      model: '23117RA68G',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 62000,
      salePrice: 69999,
      description: '200MP OIS Camera, 120Hz AMOLED, 67W Turbo Charge',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6941812745678': const BarcodeProductInfo(
      barcode: '6941812745678',
      name: 'Xiaomi Redmi 13C (6GB / 128GB)',
      brand: 'Xiaomi',
      model: '23100RN82L',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 29500,
      salePrice: 33999,
      description: '6.74" 90Hz Display, 50MP AI Camera, 5000mAh Battery',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6934177755555': const BarcodeProductInfo(
      barcode: '6934177755555',
      name: 'Xiaomi Mi 20000mAh Power Bank 3 Pro',
      brand: 'Xiaomi',
      model: 'PB200LZM',
      category: 'Power Banks',
      type: ProductType.accessory,
      purchasePrice: 4800,
      salePrice: 6500,
      description: 'Dual USB Output, 18W Fast Two-Way Charging',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Infinix & Tecno
    '4895180798214': const BarcodeProductInfo(
      barcode: '4895180798214',
      name: 'Infinix Hot 40 Pro (8GB / 256GB)',
      brand: 'Infinix',
      model: 'X6837',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 39500,
      salePrice: 44999,
      description: 'Helio G99, 108MP Camera, 33W Fast Charge, 120Hz FHD+',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '4895180796326': const BarcodeProductInfo(
      barcode: '4895180796326',
      name: 'Tecno Spark 20 Pro (8GB / 256GB)',
      brand: 'Tecno',
      model: 'KJ6',
      category: 'Smartphones',
      type: ProductType.phone,
      purchasePrice: 38500,
      salePrice: 43999,
      description: '108MP Ultra Sensing, Helio G99, Stereo Dual Speakers',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '4895180777123': const BarcodeProductInfo(
      barcode: '4895180777123',
      name: 'Infinix 33W Fast Charger Adapter',
      brand: 'Infinix',
      model: 'U330XEA',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 1300,
      salePrice: 1950,
      description: 'Super Charge 33W Original Infinix Wall Charger',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '4895180766234': const BarcodeProductInfo(
      barcode: '4895180766234',
      name: 'Tecno 18W Flash Charger',
      brand: 'Tecno',
      model: 'U180TEA',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 950,
      salePrice: 1500,
      description: 'Original 18W Safe Fast Charger with Micro/Type-C',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Anker & Baseus
    '194644023775': const BarcodeProductInfo(
      barcode: '194644023775',
      name: 'Anker 511 Charger (Nano Pro 20W)',
      brand: 'Anker',
      model: 'A2149',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 2700,
      salePrice: 3800,
      description: 'Ultra Compact PIQ 3.0 Fast Charger for iPhone & Android',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '194644018740': const BarcodeProductInfo(
      barcode: '194644018740',
      name: 'Anker PowerLine III USB-C to USB-C 60W',
      brand: 'Anker',
      model: 'A8852',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 1600,
      salePrice: 2400,
      description: 'Ultra Durable Braided 60W Fast Charging Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6932169315891': const BarcodeProductInfo(
      barcode: '6932169315891',
      name: 'Baseus GaN5 Pro 65W Fast Charger',
      brand: 'Baseus',
      model: 'CCGAN65E5',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 4200,
      salePrice: 5900,
      description: '3-Port GaN Fast Charger 2x Type-C + 1x USB-A QC4+',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '6953156214224': const BarcodeProductInfo(
      barcode: '6953156214224',
      name: 'Baseus Cafule Type-C to Type-C 100W (2m)',
      brand: 'Baseus',
      model: 'CATKLF-ALG1',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 1200,
      salePrice: 1850,
      description: 'High Density Braided 100W 5A E-Marker Flash Charge',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Local Brands (Ronin, Audionic, Faster, Dany)
    '8964002448601': const BarcodeProductInfo(
      barcode: '8964002448601',
      name: 'Ronin R-860 PD 20W Fast Charger',
      brand: 'Ronin',
      model: 'R-860',
      category: 'Chargers',
      type: ProductType.accessory,
      purchasePrice: 1150,
      salePrice: 1750,
      description: 'Dual Port QC 3.0 + PD 20W Fast Wall Adapter',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8964002447703': const BarcodeProductInfo(
      barcode: '8964002447703',
      name: 'Ronin R-770 VOOC / SuperDart 65W Cable',
      brand: 'Ronin',
      model: 'R-770',
      category: 'Cables',
      type: ProductType.accessory,
      purchasePrice: 480,
      salePrice: 800,
      description: 'Super Fast Flash Charging Heavy Duty Zinc Alloy Cable',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8964002445502': const BarcodeProductInfo(
      barcode: '8964002445502',
      name: 'Ronin R-9 Handsfree Deep Bass',
      brand: 'Ronin',
      model: 'R-9',
      category: 'Earphones',
      type: ProductType.accessory,
      purchasePrice: 380,
      salePrice: 650,
      description: '3.5mm Jack In-Ear Earphones with Crystal Clear Mic',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8964001550018': const BarcodeProductInfo(
      barcode: '8964001550018',
      name: 'Audionic Airbud 550 Wireless Earbuds',
      brand: 'Audionic',
      model: 'Airbud 550',
      category: 'Earphones',
      type: ProductType.accessory,
      purchasePrice: 3400,
      salePrice: 4900,
      description: 'Quad Mic ENC, Low Latency Gaming Mode, 26h Playtime',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8964003300014': const BarcodeProductInfo(
      barcode: '8964003300014',
      name: 'Faster TG-300 Gaming Wireless Earbuds',
      brand: 'Faster',
      model: 'TG-300',
      category: 'Earphones',
      type: ProductType.accessory,
      purchasePrice: 2400,
      salePrice: 3500,
      description: 'RGB Gaming TWS, 40ms Ultra Low Latency, Touch Control',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '8964000100016': const BarcodeProductInfo(
      barcode: '8964000100016',
      name: 'Dany Alpha Pro 10000mAh Power Bank',
      brand: 'Dany',
      model: 'Alpha Pro',
      category: 'Power Banks',
      type: ProductType.accessory,
      purchasePrice: 2600,
      salePrice: 3800,
      description: '22.5W Fast Charging with Built-in Cables & Digital Display',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),

    // Screen Protectors, Covers, Batteries & Repair Parts
    '9901000000018': const BarcodeProductInfo(
      barcode: '9901000000018',
      name: '9D Full Curved Tempered Glass Screen Protector',
      brand: 'Universal',
      model: '9D Curved',
      category: 'Screen Protectors',
      type: ProductType.accessory,
      purchasePrice: 120,
      salePrice: 350,
      description: '9H Hardness Edge-to-Edge Full Glue Tempered Glass',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '9901000000025': const BarcodeProductInfo(
      barcode: '9901000000025',
      name: 'Matte Silicone Shockproof Armor Back Cover',
      brand: 'Universal',
      model: 'Matte Armor',
      category: 'Back Covers',
      type: ProductType.accessory,
      purchasePrice: 160,
      salePrice: 450,
      description: 'Anti-Fingerprint Shock Absorption Protective Case',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '9902000000011': const BarcodeProductInfo(
      barcode: '9902000000011',
      name: 'Original iPhone 11 LCD Screen Replacement',
      brand: 'Apple OEM',
      model: 'iPhone 11 Display',
      category: 'LCD / OLED Screens',
      type: ProductType.part,
      purchasePrice: 5800,
      salePrice: 8500,
      description: 'Original Quality TrueTone Supported Replacement Display',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
    '9903000000325': const BarcodeProductInfo(
      barcode: '9903000000325',
      name: 'Original Samsung A32 Battery (EB-BA315ABY)',
      brand: 'Samsung OEM',
      model: 'EB-BA315ABY',
      category: 'Batteries',
      type: ProductType.part,
      purchasePrice: 1700,
      salePrice: 2700,
      description: '5000mAh Li-ion Original Grade Replacement Battery',
      source: 'Global Mobile Catalog',
      isFound: true,
    ),
  };

  /// List of sample barcodes for UI quick-testing
  static List<BarcodeProductInfo> get sampleBarcodes => _presetCatalog.values.toList();

  /// Primary multi-tiered lookup method
  static Future<BarcodeProductInfo> lookupBarcode({
    required String barcode,
    InventoryProvider? inventoryProvider,
  }) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return const BarcodeProductInfo(
        barcode: '',
        name: '',
        isFound: false,
      );
    }

    // Tier 1: Check existing store inventory
    if (inventoryProvider != null) {
      final existingProduct = inventoryProvider.products.where((p) {
        return (p.barcode.isNotEmpty && p.barcode.trim().toLowerCase() == cleanBarcode.toLowerCase()) ||
               (p.sku.isNotEmpty && p.sku.trim().toLowerCase() == cleanBarcode.toLowerCase());
      }).firstOrNull;

      if (existingProduct != null) {
        return BarcodeProductInfo(
          barcode: existingProduct.barcode.isNotEmpty ? existingProduct.barcode : cleanBarcode,
          name: existingProduct.name,
          brand: existingProduct.brand,
          model: existingProduct.model,
          category: existingProduct.category,
          type: existingProduct.type,
          purchasePrice: existingProduct.purchasePrice,
          salePrice: existingProduct.salePrice,
          description: existingProduct.description,
          source: 'Store Inventory (Existing)',
          isFound: true,
        );
      }
    }

    // Tier 2: Check offline pre-configured catalog
    if (_presetCatalog.containsKey(cleanBarcode)) {
      return _presetCatalog[cleanBarcode]!;
    }

    // Also check case-insensitive match in preset catalog
    for (final entry in _presetCatalog.entries) {
      if (entry.key.toLowerCase() == cleanBarcode.toLowerCase()) {
        return entry.value;
      }
    }

    // Tier 3: Check if it's a 15-digit Handset IMEI (TAC check)
    if (RegExp(r'^\d{14,16}$').hasMatch(cleanBarcode)) {
      final imeiInfo = _resolveImei(cleanBarcode);
      if (imeiInfo != null) {
        return imeiInfo;
      }
    }

    // Tier 4: Online Barcode API Lookup
    try {
      final onlineInfo = await _queryOnlineBarcode(cleanBarcode);
      if (onlineInfo != null) {
        return onlineInfo;
      }
    } catch (e) {
      debugPrint('Online barcode lookup failed: $e');
    }

    // Tier 5: Smart heuristic fallback
    return _smartFallback(cleanBarcode);
  }

  /// Online query using native Dart HttpClient (works cross-platform without third-party plugins)
  static Future<BarcodeProductInfo?> _queryOnlineBarcode(String barcode) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    try {
      // 1. Try Open Products Facts API
      final uri = Uri.parse('https://world.openproductsfacts.org/api/v0/product/$barcode.json');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MobileShopLabPOS/1.0 (pos@mobileshop.com)');
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        if (data['status'] == 1 && data['product'] != null) {
          final prod = data['product'] as Map<String, dynamic>;
          final name = (prod['product_name'] ?? prod['product_name_en'] ?? '').toString().trim();
          final brand = (prod['brands'] ?? '').toString().trim();
          final categoryRaw = (prod['categories'] ?? '').toString().toLowerCase();

          if (name.isNotEmpty) {
            final category = _inferCategory(name, categoryRaw);
            final type = _inferType(category);

            return BarcodeProductInfo(
              barcode: barcode,
              name: name,
              brand: brand.isNotEmpty ? brand : _inferBrand(name),
              category: category,
              type: type,
              description: (prod['generic_name'] ?? prod['description'] ?? '').toString(),
              source: 'Open Product Database',
              isFound: true,
            );
          }
        }
      }

      // 2. Try Open Food / Retail Facts API fallback
      final foodUri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final foodRequest = await client.getUrl(foodUri);
      foodRequest.headers.set('User-Agent', 'MobileShopLabPOS/1.0 (pos@mobileshop.com)');
      final foodResponse = await foodRequest.close().timeout(const Duration(seconds: 4));

      if (foodResponse.statusCode == 200) {
        final foodBody = await foodResponse.transform(utf8.decoder).join();
        final foodData = jsonDecode(foodBody) as Map<String, dynamic>;

        if (foodData['status'] == 1 && foodData['product'] != null) {
          final prod = foodData['product'] as Map<String, dynamic>;
          final name = (prod['product_name'] ?? prod['product_name_en'] ?? '').toString().trim();
          final brand = (prod['brands'] ?? '').toString().trim();

          if (name.isNotEmpty) {
            return BarcodeProductInfo(
              barcode: barcode,
              name: name,
              brand: brand,
              category: 'Other',
              type: ProductType.accessory,
              description: (prod['generic_name'] ?? '').toString(),
              source: 'Global Retail Database',
              isFound: true,
            );
          }
        }
      }
    } catch (_) {
      // Fallback gracefully on timeout or network offline
    } finally {
      client.close();
    }
    return null;
  }

  /// Recognize Handset IMEI patterns
  static BarcodeProductInfo? _resolveImei(String imei) {
    final prefix = imei.substring(0, 2);
    String brand = 'General';
    String model = 'Mobile Handset';

    if (prefix == '35') {
      final tac = imei.substring(0, 4);
      if (tac == '3520' || tac == '3530' || tac == '3540' || tac == '3550') {
        brand = 'Apple';
        model = 'iPhone';
      } else {
        brand = 'Samsung';
        model = 'Galaxy Device';
      }
    } else if (prefix == '86') {
      brand = 'Xiaomi / Vivo / Oppo';
      model = 'Android Smartphone';
    } else if (prefix == '01') {
      brand = 'Apple';
      model = 'iPhone';
    }

    return BarcodeProductInfo(
      barcode: imei,
      name: '$brand $model (IMEI: $imei)',
      brand: brand,
      model: model,
      category: 'Smartphones',
      type: ProductType.phone,
      description: 'Handset scanned via 15-digit IMEI Barcode: $imei',
      source: 'IMEI Device Barcode',
      isFound: true,
    );
  }

  static String _inferCategory(String name, String rawCategories) {
    final text = '$name $rawCategories'.toLowerCase();
    if (text.contains('charger') || text.contains('adapter') || text.contains('power supply')) return 'Chargers';
    if (text.contains('cable') || text.contains('usb-c') || text.contains('lightning') || text.contains('cord')) return 'Cables';
    if (text.contains('earphone') || text.contains('headphone') || text.contains('earbud') || text.contains('airpod') || text.contains('audio')) return 'Earphones';
    if (text.contains('power bank') || text.contains('battery pack') || text.contains('portable charger')) return 'Power Banks';
    if (text.contains('glass') || text.contains('screen protector') || text.contains('tempered')) return 'Screen Protectors';
    if (text.contains('case') || text.contains('cover') || text.contains('silicone') || text.contains('armor')) return 'Back Covers';
    if (text.contains('display') || text.contains('lcd') || text.contains('oled') || text.contains('touch screen')) return 'LCD / OLED Screens';
    if (text.contains('battery')) return 'Batteries';
    if (text.contains('phone') || text.contains('smartphone') || text.contains('mobile')) return 'Smartphones';
    return 'Other';
  }

  static ProductType _inferType(String category) {
    if (category == 'Smartphones') return ProductType.phone;
    if (category == 'LCD / OLED Screens' || category == 'Batteries' || category == 'Charging Ports & Flex' || category == 'Repair Tools') {
      return ProductType.part;
    }
    return ProductType.accessory;
  }

  static String _inferBrand(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('samsung')) return 'Samsung';
    if (lower.contains('apple') || lower.contains('iphone')) return 'Apple';
    if (lower.contains('xiaomi') || lower.contains('redmi') || lower.contains('poco')) return 'Xiaomi';
    if (lower.contains('infinix')) return 'Infinix';
    if (lower.contains('tecno')) return 'Tecno';
    if (lower.contains('oppo')) return 'Oppo';
    if (lower.contains('vivo')) return 'Vivo';
    if (lower.contains('anker')) return 'Anker';
    if (lower.contains('baseus')) return 'Baseus';
    if (lower.contains('ronin')) return 'Ronin';
    if (lower.contains('audionic')) return 'Audionic';
    if (lower.contains('faster')) return 'Faster';
    if (lower.contains('dany')) return 'Dany';
    return 'General';
  }

  static BarcodeProductInfo _smartFallback(String barcode) {
    final brand = _inferBrand(barcode);
    return BarcodeProductInfo(
      barcode: barcode,
      name: '',
      brand: brand != 'General' ? brand : '',
      category: 'Chargers',
      type: ProductType.accessory,
      source: 'Uncataloged Barcode',
      isFound: false,
    );
  }
}
