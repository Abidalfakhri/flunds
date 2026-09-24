import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlundsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FlundsBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(icon: Icons.home_filled, active: currentIndex == 0, onTap: () => onTap(0)),
          _NavIcon(icon: Icons.list_alt, active: currentIndex == 1, onTap: () => onTap(1)),
          const SizedBox(width: 40),
          _NavIcon(icon: Icons.bar_chart, active: currentIndex == 2, onTap: () => onTap(2)),
          _NavIcon(icon: Icons.account_balance_wallet, active: currentIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavIcon({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, color: active ? FlundsColors.primary : Colors.grey), onPressed: onTap);
  }
}
