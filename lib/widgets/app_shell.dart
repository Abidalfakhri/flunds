import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transactions_list_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/simulation_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/transaction_form_screen.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'bottom_nav.dart';
import 'nav_destinations.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsListScreen(),
    AnalysisScreen(),
    SimulationScreen(),
  ];

  void _openAddTransaction() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.useRailNavigation;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: FlundsColors.surface,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: FlundsColors.primary, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.eco_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 18),
                    FloatingActionButton(
                      heroTag: 'fab-rail',
                      onPressed: _openAddTransaction,
                      backgroundColor: FlundsColors.accent,
                      elevation: 0,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              destinations: flundsDestinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.activeIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      onPressed: _openProfile,
                      tooltip: 'Profil',
                      icon: const Icon(Icons.person_outline),
                      color: FlundsColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: FlundsColors.surfaceLine),
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-main',
        onPressed: _openAddTransaction,
        backgroundColor: FlundsColors.accent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FlundsBottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
