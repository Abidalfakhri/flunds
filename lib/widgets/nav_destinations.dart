import 'package:flutter/material.dart';

class FlundsDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const FlundsDestination({required this.label, required this.icon, required this.activeIcon});
}

// Exactly 4 destinations by design: with a center-docked FAB, this splits
// evenly into 2 left / 2 right so the notch stays visually symmetric.
// Profil is intentionally not a tab — it's reached via the avatar in
// GreetingHeader (compact) or the rail shortcut (expanded) — see AppShell.
const List<FlundsDestination> flundsDestinations = [
  FlundsDestination(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home_filled),
  FlundsDestination(label: 'Transaksi', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
  FlundsDestination(label: 'Analisis', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
  FlundsDestination(label: 'Simulasi', icon: Icons.insights_outlined, activeIcon: Icons.insights),
];
