import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'nav_destinations.dart';

class FlundsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FlundsBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FlundsColors.surface,
        border: Border(top: BorderSide(color: FlundsColors.surfaceLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < flundsDestinations.length; i++)
                Expanded(
                  child: _NavIcon(
                    destination: flundsDestinations[i],
                    active: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? destination.activeIcon : destination.icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, height: 1.0),
          ),
        ],
      ),
    );
  }
}
