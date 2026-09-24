import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/simulation_screen.dart';
import '../screens/owner_withdraw_screen.dart';
import '../screens/add_transaction_screen.dart';
import 'bottom_nav.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    SimulationScreen(),
    OwnerWithdrawScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        backgroundColor: FlundsColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FlundsBottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
