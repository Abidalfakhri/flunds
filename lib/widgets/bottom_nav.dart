import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'nav_destinations.dart';

class FlundsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FlundsBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: FlundsColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(destination: flundsDestinations[0], active: currentIndex == 0, onTap: () => onTap(0)),
          _NavIcon(destination: flundsDestinations[1], active: currentIndex == 1, onTap: () => onTap(1)),
          const SizedBox(width: 44),
          _NavIcon(destination: flundsDestinations[2], active: currentIndex == 2, onTap: () => onTap(2)),
          _NavIcon(destination: flundsDestinations[3], active: currentIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final FlundsDestination destination;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({required this.destination, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? FlundsColors.primary : FlundsColors.textMuted;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? destination.activeIcon : destination.icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(destination.label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
