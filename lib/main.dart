import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pos_provider.dart';
import 'views/pos_screen.dart';
import 'views/inventory_screen.dart';
import 'views/settlement_screen.dart';
import 'views/team_screen.dart';
import 'views/history_screen.dart';
import 'views/reports_screen.dart';
import 'views/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final posProvider = PosProvider();
  await posProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: posProvider),
      ],
      child: const BoothPosApp(),
    ),
  );
}

class BoothPosApp extends StatelessWidget {
  const BoothPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPOS - Booth POS v1.5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF0284C7),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final isOwner = pos.isOwner;
    final isTablet = MediaQuery.of(context).size.width >= 900;

    // Define items dynamically according to role (Requirement 4.7)
    // Member: can sell, view inventory (masked cost), view history, view reports, view team (can toggle role)
    // Owner: also sees Settlement and Settings!
    final List<Widget> screens = [
      const PosScreen(),
      const InventoryScreen(),
      if (isOwner) const SettlementScreen(),
      const TeamScreen(),
      const HistoryScreen(),
      const ReportsScreen(),
      if (isOwner) const SettingsScreen(),
    ];

    // Ensure index does not exceed list bounds when role changes
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text('ขายหน้าร้าน'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('คลังสินค้า'),
      ),
      if (isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: Text('สรุปยอด'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.group_outlined),
        selectedIcon: Icon(Icons.group),
        label: Text('ทีมงาน'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('ประวัติบิล'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('รายงาน'),
      ),
      if (isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('ตั้งค่า'),
        ),
    ];

    final barDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale, color: Color(0xFF2563EB)),
        label: 'ขายของ',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF2563EB)),
        label: 'คลังสินค้า',
      ),
      if (isOwner)
        const NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments, color: Color(0xFF2563EB)),
          label: 'สรุปยอด',
        ),
      const NavigationDestination(
        icon: Icon(Icons.group_outlined),
        selectedIcon: Icon(Icons.group, color: Color(0xFF2563EB)),
        label: 'ทีมงาน',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
        label: 'บิลย้อนหลัง',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics, color: Color(0xFF2563EB)),
        label: 'รายงาน',
      ),
      if (isOwner)
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: Color(0xFF2563EB)),
          label: 'ตั้งค่า',
        ),
    ];

    if (isTablet) {
      // iPad / Tablet Landscape Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Center(
                    child: Text('🐙', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              destinations: railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // Phone & Compact Tablet Navigation Bar
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        destinations: barDestinations,
      ),
    );
  }
}
