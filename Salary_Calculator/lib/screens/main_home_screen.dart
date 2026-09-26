import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/salary_model.dart';
import '../models/salary_record.dart';
import '../services/salary_storage_service.dart';
import '../widgets/modern_bottom_nav_bar.dart';
import 'circle_analytics_screen.dart';
import 'salary_calculator_screen.dart';
import 'saved_records_screen.dart';

class MainHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  SalaryResult? _latestResult;
  SalaryRecord? _recordToLoad;

  void _onCalculationUpdated(
    SalaryResult result,
    TaxCalculationMode mode,
    double flatRate,
  ) {
    setState(() {
      _latestResult = result;
    });
  }

  void _restoreRecordIntoCalculator(SalaryRecord record) {
    setState(() {
      _recordToLoad = record;
      _latestResult = record.toSalaryResult();
      _currentIndex = 0; // Switch to Calculator tab
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Loaded "${record.title}" into calculator.',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      SalaryCalculatorScreen(
        onCalculated: _onCalculationUpdated,
        recordToLoad: _recordToLoad,
        onOpenAnalytics: () => setState(() => _currentIndex = 1),
        onOpenSavedRecords: () => setState(() => _currentIndex = 2),
      ),
      CircleAnalyticsScreen(
        result: _latestResult,
        onGoToCalculator: () => setState(() => _currentIndex = 0),
      ),
      SavedRecordsScreen(
        onRestoreRecord: _restoreRecordIntoCalculator,
        onGoToCalculator: () => setState(() => _currentIndex = 0),
      ),
    ];

    String subtitle;
    switch (_currentIndex) {
      case 0:
        subtitle = 'Salary & Progressive Slabs';
        break;
      case 1:
        subtitle = 'Circle Graph Analytics';
        break;
      case 2:
      default:
        subtitle = 'Local Calculation History';
        break;
    }

    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Salary Pro',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    widget.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey(widget.isDarkMode),
                    size: 20,
                    color: widget.isDarkMode
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF1E3A8A),
                  ),
                ),
                tooltip: widget.isDarkMode
                    ? 'Switch to Light Theme'
                    : 'Switch to Dark Theme',
                onPressed: widget.onToggleTheme,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          // History Shortcut Icon
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: ValueListenableBuilder(
              valueListenable: SalaryStorageService.listenable(),
              builder: (context, Box box, _) {
                final count = box.length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _currentIndex == 2
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.15)
                            : (isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currentIndex == 2
                              ? const Color(0xFF1E3A8A)
                              : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _currentIndex == 2
                              ? Icons.history_rounded
                              : Icons.history_edu_rounded,
                          size: 20,
                          color: _currentIndex == 2
                              ? const Color(0xFF2563EB)
                              : theme.colorScheme.onSurface,
                        ),
                        tooltip: 'View History ($count)',
                        onPressed: () {
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 15,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
      ),
    );
  }
}
