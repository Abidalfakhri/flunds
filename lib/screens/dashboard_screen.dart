import 'package:flutter/material.dart';
import '../widgets/greeting_header.dart';
import '../widgets/runway_card.dart';
import '../widgets/cash_summary_row.dart';
import '../widgets/owner_cut_card.dart';
import '../widgets/recent_transactions_section.dart';
import 'owner_withdraw_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const GreetingHeader(userName: 'Rani'),
              const SizedBox(height: 16),
              const RunwayCard(runwayDays: 45, thresholdDays: 30, progress: 0.7, statusLabel: 'Aman'),
              const SizedBox(height: 16),
              const CashSummaryRow(balance: 'Rp8,4jt', inflow: '+Rp5,2jt', outflow: '-Rp3,1jt'),
              const SizedBox(height: 16),
              OwnerCutCard(
                safeAmount: 'Rp1,2jt',
                onWithdrawPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerWithdrawScreen())),
              ),
              const SizedBox(height: 16),
              const RecentTransactionsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
