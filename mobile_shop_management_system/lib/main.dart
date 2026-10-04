import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_provider.dart';
import 'core/providers/pos_provider.dart';
import 'core/providers/inventory_provider.dart';
import 'core/providers/repair_provider.dart';
import 'core/providers/ledger_provider.dart';
import 'core/theme/app_theme.dart';

import 'ui/widgets/app_sidebar.dart';
import 'ui/widgets/app_top_bar.dart';
import 'ui/widgets/global_search_dialog.dart';
import 'ui/widgets/custom_dialogs.dart';

import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/pos_screen.dart';
import 'ui/screens/sales_screen.dart';
import 'ui/screens/purchases_screen.dart';
import 'ui/screens/inventory_screen.dart';
import 'ui/screens/mobile_phones_screen.dart';
import 'ui/screens/accessories_screen.dart';
import 'ui/screens/repair_lab_screen.dart';
import 'ui/screens/customers_screen.dart';
import 'ui/screens/suppliers_screen.dart';
import 'ui/screens/payments_dues_screen.dart';
import 'ui/screens/expenses_screen.dart';
import 'ui/screens/employees_screen.dart';
import 'ui/screens/warranty_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/backup_restore_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MobileShopLabApp());
}

class MobileShopLabApp extends StatelessWidget {
  const MobileShopLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => RepairProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) {
          return MaterialApp(
            title: app.settings.shopName.isNotEmpty
                ? '${app.settings.shopName} - Management System'
                : 'Mobile Shop & Repairing Lab Management System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: app.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final FocusNode _focusNode = FocusNode();

  final List<Widget> _screens = const [
    DashboardScreen(), // 0
    PosScreen(), // 1
    SalesScreen(), // 2
    PurchasesScreen(), // 3
    InventoryScreen(), // 4
    MobilePhonesScreen(), // 5
    AccessoriesScreen(), // 6
    RepairLabScreen(), // 7
    CustomersScreen(), // 8
    SuppliersScreen(), // 9
    PaymentsDuesScreen(), // 10
    ExpensesScreen(), // 11
    EmployeesScreen(), // 12
    WarrantyScreen(), // 13
    ReportsScreen(), // 14
    BackupRestoreScreen(), // 15
    SettingsScreen(), // 16
  ];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final app = context.read<AppProvider>();

    if (event.logicalKey == LogicalKeyboardKey.f1) {
      app.setNavIndex(1); // F1 = POS
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f2) {
      showDialog(context: context, builder: (_) => const GlobalSearchDialog());
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f3) {
      AppDialogs.showNewCustomerDialog(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f4) {
      AppDialogs.showNewRepairDialog(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f5) {
      app.reloadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data refreshed!'), duration: Duration(seconds: 1)),
      );
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f6) {
      AppDialogs.showReceivePaymentDialog(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f7) {
      app.setNavIndex(4); // F7 = Inventory
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f8) {
      app.setNavIndex(14); // F8 = Reports
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (app.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing Mobile Shop & Repair Lab Database...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final currentIndex = app.currentNavIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(),

          // Main Area (Top Bar + Active Screen)
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
