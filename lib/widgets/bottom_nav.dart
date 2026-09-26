import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'nav_destinations.dart';

class FlundsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FlundsBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final leftCount = (flundsDestinations.length / 2).ceil();

    return BottomAppBar(
      color: FlundsColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < leftCount; i++)
            _NavIcon(destination: flundsDestinations[i], active: currentIndex == i, onTap: () => onTap(i)),
          const SizedBox(width: 44),
          for (int i = leftCount; i < flundsDestinations.length; i++)
            _NavIcon(destination: flundsDestinations[i], active: currentIndex == i, onTap: () => onTap(i)),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? destination.activeIcon : destination.icon, color: color, size: 21),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, height: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
