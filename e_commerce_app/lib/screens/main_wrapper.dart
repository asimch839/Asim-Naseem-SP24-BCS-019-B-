import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../models/cart_manager.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final cartManager = CartManager();

  final List<Widget> _screens = [
    const ProductListScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for Wide Screens (Laptop, Tablet, TV)
          if (isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
              selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(Icons.shopping_bag, size: 40, color: Colors.blueAccent),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: _buildCartIcon(false),
                  selectedIcon: _buildCartIcon(true),
                  label: const Text('Cart'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          
          // Main Screen Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar for Mobile Screens
      bottomNavigationBar: isWide 
          ? null 
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blueAccent,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildCartIcon(false),
                  activeIcon: _buildCartIcon(true),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  Widget _buildCartIcon(bool isActive) {
    return ValueListenableBuilder<int>(
      valueListenable: cartManager.cartCountNotifier,
      builder: (context, count, child) {
        return Stack(
          children: [
            Icon(isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
