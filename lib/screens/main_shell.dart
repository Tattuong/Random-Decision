import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';
import 'wheel/choices_screen.dart';
import 'wheel/wheel_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;
  final _shopKey = GlobalKey<ShopScreenState>();

  void openShop({ShopRewardsTab tab = ShopRewardsTab.all}) {
    setState(() => _index = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopKey.currentState?.selectTab(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const WheelScreen(),
      const ChoicesScreen(),
      ShopScreen(key: _shopKey, embedded: true),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _NavItem(icon: Icons.casino_outlined, activeIcon: Icons.casino_rounded, label: AppStrings.t(context, 'navWheel'), active: _index == 0, onTap: () => setState(() => _index = 0)),
                _NavItem(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded, label: AppStrings.t(context, 'navChoices'), active: _index == 1, onTap: () => setState(() => _index = 1)),
                _NavItem(icon: Icons.stars_outlined, activeIcon: Icons.stars_rounded, label: AppStrings.t(context, 'navShop'), active: _index == 2, onTap: () => setState(() => _index = 2)),
                _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: AppStrings.t(context, 'navSettings'), active: _index == 3, onTap: () => setState(() => _index = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? context.brand.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, color: active ? context.brand : AppColors.onSurfaceVariant, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active ? context.brand : AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
