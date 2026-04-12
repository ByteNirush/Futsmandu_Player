import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import '../discovery/discovery_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../venues/venue_list_screen.dart';

/// Height of the custom bottom nav bar (excluding system bottom inset).
const double kNavBarHeight = 80.0;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _navItems = [
    _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.sports_soccer_outlined,
        activeIcon: Icons.sports_soccer_rounded,
        label: 'Futsal'),
    _NavItem(
        icon: Icons.people_alt_outlined,
        activeIcon: Icons.people_alt_rounded,
        label: 'Friends'),
    _NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Discover'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile'),
  ];

  void _onTap(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          VenueListScreen(),
          FriendsScreen(),
          DiscoveryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(height: kNavBarHeight),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTap,
          height: kNavBarHeight,
          destinations: _navItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item data
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

