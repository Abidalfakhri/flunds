import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlundsBottomNav extends StatelessWidget {
  const FlundsBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavIcon(icon: Icons.home_filled, active: true),
          _NavIcon(icon: Icons.list_alt, active: false),
          SizedBox(width: 40),
          _NavIcon(icon: Icons.bar_chart, active: false),
          _NavIcon(icon: Icons.person_outline, active: false),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  const _NavIcon({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: active ? FlundsColors.primary : Colors.grey,
    );
  }
}