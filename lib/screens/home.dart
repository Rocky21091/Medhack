import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medhack/screens/dashboard.dart';
import 'package:medhack/screens/library.dart';
import 'package:medhack/screens/location_services_page.dart';
import 'package:medhack/screens/pharmacy.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const LibraryPage(),
    // const PharmacyPage(),
    const LocationServicesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedHack'),
        // Left Side Profile
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, size: 28),
          onPressed: () => context.push('/profile'),
        ),
        // Right Side Notifications
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 28),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
        // Adds a subtle shadow below the app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1.0),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: AppTheme.pureWhite,
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) =>
                  setState(() => _currentIndex = index),
              selectedIconTheme: const IconThemeData(
                color: AppTheme.primaryGreen,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppTheme.textGrey,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_rounded),
                  label: Text('Library'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_pharmacy_rounded),
                  label: Text('Pharmacy'),
                ),
              ],
            ),
          if (isDesktop)
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppTheme.lightGreen,
            ),

          Expanded(child: _pages[_currentIndex]),
        ],
      ),

      // Floating Action Buttons (Only visible on Home Tab)
      floatingActionButton: _currentIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'scan_btn',
                  backgroundColor: AppTheme.pureWhite,
                  foregroundColor: AppTheme.primaryGreen,
                  elevation: 4,
                  onPressed: () => context.push('/scan'),
                  child: const Icon(Icons.document_scanner_rounded),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'ai_btn',
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.pureWhite,
                  elevation: 4,
                  onPressed: () => context.push('/ai-chat'),
                  child: const Icon(Icons.smart_toy_rounded),
                ),
              ],
            )
          : null,

      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_pharmacy_rounded),
                  label: 'Pharmacy',
                ),
              ],
            ),
    );
  }
}
