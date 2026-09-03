import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'tender_list_screen.dart';
import 'my_applications_screen.dart';
import 'document_vault_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

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
    final notifs = await ApiService.fetchNotifications();
    if (mounted) {
      setState(() {
        _unreadNotifCount = notifs.where((n) => !n.read).length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TenderListScreen(),
      const MyApplicationsScreen(),
      const DocumentVaultScreen(),
      NotificationsScreen(onNotificationUpdated: _checkUnreadNotifications),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 3) {
            _checkUnreadNotifications();
          }
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: GemTheme.primaryNavy.withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore, color: GemTheme.primaryNavy),
            label: 'Tenders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: GemTheme.primaryNavy),
            label: 'My Bids',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared, color: GemTheme.primaryNavy),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadNotifCount > 0,
              label: Text('$_unreadNotifCount'),
              backgroundColor: GemTheme.saffron,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadNotifCount > 0,
              label: Text('$_unreadNotifCount'),
              backgroundColor: GemTheme.saffron,
              child: const Icon(Icons.notifications, color: GemTheme.primaryNavy),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: GemTheme.primaryNavy),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
