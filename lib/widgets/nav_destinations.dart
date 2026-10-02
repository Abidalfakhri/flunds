import 'package:flutter/material.dart';

class FlundsDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const FlundsDestination({required this.label, required this.icon, required this.activeIcon});
}

// 5 destinations, each reachable directly from the bottom bar (or the
// navigation rail on wide screens) — including Profil, which used to be
// hidden behind the dashboard avatar and is now an explicit tab so it's
// easier to find for first-time / non-technical owners.
const List<FlundsDestination> flundsDestinations = [
  FlundsDestination(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home_filled),
  FlundsDestination(label: 'Transaksi', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
  FlundsDestination(label: 'Utang', icon: Icons.handshake_outlined, activeIcon: Icons.handshake),
  FlundsDestination(label: 'Analisis', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
  FlundsDestination(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person),
];
