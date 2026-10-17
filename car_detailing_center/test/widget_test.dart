import 'package:flutter_test/flutter_test.dart';
import 'package:car_detailing_center/core/utils/formatters.dart';
import 'package:car_detailing_center/data/models/invoice_model.dart';
import 'package:car_detailing_center/data/models/inventory_item_model.dart';

void main() {
  group('Formatters & Financial Calculation Tests', () {
    test('Currency formatter outputs expected symbol and decimal points', () {
      expect(Formatters.currency(1500, symbol: 'Rs. '), 'Rs. 1,500.00');
      expect(Formatters.currency(0, symbol: 'Rs. '), 'Rs. 0.00');
      expect(Formatters.compactCurrency(1200000, symbol: 'Rs. '), 'Rs. 1.2M');
    });

    test('Inventory Item valuations and low stock calculations', () {
      final item = InventoryItemModel(
        id: 'item-1',
        businessId: 'biz-1',
        name: 'Ceramic Coating 9H',
        brand: 'Ceramic Pro',
        unit: 'Bottle',
        currentQuantity: 10,
        purchasePrice: 2000,
      );

      expect(item.currentPurchaseValuation, 20000.0);
      expect(item.totalPurchaseValuation, 20000.0);
      expect(item.isLowStock(5.0), false);
      expect(item.isLowStock(15.0), true);
      expect(item.isOutOfStock, false);
    });

    test('Invoice model payment status and remaining balance', () {
      final invoice = InvoiceModel(
        id: 'inv-1',
        invoiceNumber: 'INV-1001',
        businessId: 'biz-1',
        customerId: 'cust-1',
        customerName: 'Asim Naseem',
        customerPhone: '+923001234567',
        items: [
          InvoiceItem(name: 'Full Detailing', type: 'service', quantity: 1, unitPrice: 10000, total: 10000),
          InvoiceItem(name: 'Ceramic Coating', type: 'service', quantity: 1, unitPrice: 25000, total: 25000),
        ],
        subtotal: 35000,
        discount: 2000,
        grandTotal: 33000,
        paidAmount: 20000,
        remainingAmount: 13000,
        status: 'Partial',
      );

      expect(invoice.grandTotal, 33000.0);
      expect(invoice.remainingAmount, 13000.0);
      expect(invoice.isFullyPaid, false);

      final fullyPaidInvoice = invoice.copyWith(
        paidAmount: 33000,
        remainingAmount: 0,
        status: 'Paid',
      );
      expect(fullyPaidInvoice.isFullyPaid, true);
    });
  });
}
