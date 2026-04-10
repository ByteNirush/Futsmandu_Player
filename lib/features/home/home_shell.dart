import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
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
      backgroundColor: AppColors.bgPrimary,
      // Important: do not use `const` here.
      // The screens rely on `AppColors` (which depends on ThemeProvider).
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
        data: NavigationBarThemeData(
          height: kNavBarHeight,
          indicatorColor: AppColors.primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: AppColors.primary, size: 24);
            }
            return IconThemeData(
              color: AppColors.txtDisabled,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                );
            if (states.contains(WidgetState.selected)) {
              return baseStyle?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return baseStyle?.copyWith(color: AppColors.txtDisabled);
          }),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTap,
          height: kNavBarHeight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────

// NOTE: This legacy implementation is kept for reference.
// ignore: unused_element
class _FutsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _FutsBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderClr, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kNavBarHeight,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: _NavTile(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _NavTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.green : AppColors.txtDisabled;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? AppTextStyles.semiBold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
