import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import 'home_screen.dart';
import 'tender_list_screen.dart';
import 'my_applications_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MainShellScreen — Government Digital Service Persistent Navigation
/// Section 5: HOME, TENDERS, APPLICATIONS, NOTIFICATIONS, PROFILE
/// ─────────────────────────────────────────────────────────────────────────────

class MainShellScreen extends StatefulWidget {
  final int initialIndex;
  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final notifs = await ApiService.fetchNotifications();
      if (mounted) {
        setState(() {
          _unreadNotifCount = notifs.where((n) => !n.read).length;
        });
      }
    } catch (_) {}
  }

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 3) {
      _checkUnreadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onNavigateTab),
      const TenderListScreen(),
      const MyApplicationsScreen(),
      NotificationsScreen(onNotificationUpdated: _checkUnreadNotifications),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigateTab,
          backgroundColor: Colors.white,
          elevation: 0,
          height: 64,
          indicatorColor: AppColors.primaryNavy.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryNavy),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.travel_explore_outlined),
              selectedIcon: Icon(Icons.travel_explore_rounded, color: AppColors.primaryNavy),
              label: 'Tenders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.primaryNavy),
              label: 'Applications',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _unreadNotifCount > 0,
                label: Text('$_unreadNotifCount'),
                backgroundColor: AppColors.saffron,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: _unreadNotifCount > 0,
                label: Text('$_unreadNotifCount'),
                backgroundColor: AppColors.saffron,
                child: const Icon(Icons.notifications_rounded, color: AppColors.primaryNavy),
              ),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryNavy),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
