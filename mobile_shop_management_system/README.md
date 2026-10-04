# Mobile Shop & Mobile Repairing Lab Management System

A commercial-grade, offline-first desktop application developed in Flutter for Pakistani mobile phone shop owners, wholesalers, and hardware repair lab technicians.

---

## 🌟 Overview & Key Capabilities

This system integrates both **Retail Mobile Shop POS** and **Advanced Chip-Level Repair Lab Management** into a unified, high-performance desktop platform:

1. **Point of Sale (POS)**: Rapid barcode and IMEI-based checkout, hold/resume sales, line discounts, and multi-payment splitting (Cash, JazzCash, Easypaisa, Bank Transfer, Customer Due).
2. **Mobile Phones & IMEI Tracking**: Dual-IMEI tracking (`IMEI 1` & `IMEI 2`), PTA status (`PTA Approved`, `Non-PTA`, `CPID Approved`, `JV`), handset condition (`New`, `Used`, `Refurbished`), and complete traceability lifecycle:
   $$\text{Supplier} \longrightarrow \text{In Stock} \longrightarrow \text{Customer Sale} \longrightarrow \text{Warranty} \longrightarrow \text{Repair Lab History}$$
3. **Dedicated Repair Lab Module**:
   - **Kanban Workflow Board** + Tabular List View
   - **12 Workflow Statuses**: `Received`, `Inspection`, `Waiting for Approval`, `Approved`, `In Progress`, `Waiting for Parts`, `Waiting for Customer`, `Completed`, `Ready for Delivery`, `Delivered`, `Cancelled`, `Unrepairable`.
   - **Privacy Protection**: Confidential lock pattern/PIN masked (`••••••`) by default with reveal toggle.
   - **Automated Cost Calculation**:
     $$\text{Final Repair Cost} = (\text{Labor Charges} + \text{Replacement Parts Sold} + \text{Other Charges}) - \text{Discount}$$
   - **Inventory Consumption**: Automatically deducts replaced screens, batteries, and charging ports from stock upon attachment.
4. **Customer & Supplier Ledgers (Dues Management)**:
   - Real-time customer outstanding balances.
   - One-click "Receive Payment" modal with instant printed Payment Vouchers.
   - Supplier payables ledger with purchase consignment history.
5. **Accurate Profit & Loss Accounting**:
   - Distinguishes **Product Profit** ($\text{Sale Price} - \text{Purchase Price}$), **Repair Profit** ($\text{Labor} + (\text{Parts Charged} - \text{Parts Cost})$), and **Net Profit** ($\text{Gross Profit} - \text{Operating Expenses}$).
6. **Print Engine**:
   - **A4 Professional Tax Invoices**
   - **Thermal POS Receipts** (80mm & 58mm)
   - **Repair Job Cards** with terms, disclaimer, and claim signatures
   - **Payment Receipts**
7. **Zero-Data-Loss Backup & Restore**:
   - Automated pre-restore safety snapshots.
   - 1-click JSON database exports and instant restorations.
   - Full audit trail logging sensitive price changes, discounts, and deletions.

---

## 🧭 Navigation Modules

| # | Module | Description |
|---|---|---|
| 1 | **Dashboard** | Today's sales, cash received, estimated net profit, stock warnings, and live repair overview. |
| 2 | **POS / New Sale** | Fast register with barcode scan, IMEI picker, split payment calculator, and receipt printing. |
| 3 | **Sales History** | Searchable sales ledger with itemized breakdown, PDF invoice printing, and returns. |
| 4 | **Purchases** | Supplier billing, wholesale consignments, and automatic stock / IMEI ingestion. |
| 5 | **Inventory & Stock** | Product catalog, low-stock alerts, manual stock adjustments with reason logging. |
| 6 | **Mobile Phones (IMEI)** | Dual-IMEI tracking, PTA status verification, condition grading, and traceability. |
| 7 | **Accessories & Parts** | Catalog for chargers, cables, glass protectors, power banks, screens, and battery spares. |
| 8 | **Repair Lab** | Kanban workflow board, technician assignments, parts consumption, and job cards. |
| 9 | **Customers** | Customer profiles, contact books, purchase history, and credit balance ledger. |
| 10 | **Suppliers** | Wholesale vendor profiles, purchase history, and payable balances. |
| 11 | **Payments & Dues** | Dedicated customer due collection and supplier payment settlement center. |
| 12 | **Expenses** | Shop operational expenses (Rent, LESCO bills, salaries, tea/refreshments, lab tools). |
| 13 | **Staff & Roles** | Role-based access control matrix (Owner, Admin, Manager, Sales, Technician, Cashier). |
| 14 | **Warranty Center** | Active, expiring (15-day alert), and expired warranties with claim processing. |
| 15 | **Reports & Profit** | Comprehensive financial statements, gross/net margins, inventory valuation, and CSV exports. |
| 16 | **Backup & Restore** | Database snapshots, safety backups, automated restore, and audit logs. |
| 17 | **Settings** | Shop branding, invoice/job prefixes, receipt templates, and dark/light mode. |

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **F1** | Open POS / New Sale Register |
| **F2** or **Ctrl + F** | Universal Global Search (IMEI, Product, Customer, Repair Job) |
| **F3** | Quick Add New Customer Modal |
| **F4** | New Mobile Repair Job Intake Modal |
| **F5** | Refresh & Reload Database |
| **F6** | Receive Customer Due Payment Modal |
| **F7** | Switch to Inventory View |
| **F8** | Switch to Reports & Analytics View |
| **Esc** | Dismiss any active dialog or modal |
| **Enter** | Confirm / Print active sale in POS |

---

## 🏗️ Architecture & Tech Stack

- **Framework**: Flutter 3.47+ (Dart 3.13+) targeting Windows Desktop x64.
- **Database**: Local embedded SQLite via `sqflite_common_ffi` with ACID transactions and indexed queries.
- **State Management**: `provider` (MultiProvider with separated domain controllers: `AppProvider`, `PosProvider`, `InventoryProvider`, `RepairProvider`, `LedgerProvider`).
- **Reporting & Printing**: `pdf` & `printing` for native Windows print driver integration and PDF export.
- **Formatting**: `intl` tailored for Pakistani currency (`Rs. 245,000`) and phone formatting (`0300-1234567`).

---

## 🚀 Running the Application

### Prerequisites
- Flutter SDK (3.24+ recommended)
- Visual Studio 2022 with "Desktop development with C++" workload installed.

### Commands
```powershell
# Get dependencies
flutter pub get

# Run unit and smoke tests
flutter test

# Run Windows Desktop App
flutter run -d windows

# Build Production Executable
flutter build windows --release
```
The compiled Windows binary will be located in:
`build\windows\x64\runner\Release\mobile_shop_management_system.exe`
