import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/greeting_header.dart';
import '../widgets/runway_card.dart';
import '../widgets/cash_summary_row.dart';
import '../widgets/owner_cut_card.dart';
import '../widgets/recent_transactions_section.dart';
import '../widgets/bottom_nav.dart';

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
            children: const [
              SizedBox(height: 12),
              GreetingHeader(userName: 'Rani'),
              SizedBox(height: 16),
              RunwayCard(
                runwayDays: 45,
                thresholdDays: 30,
                progress: 0.7,
                statusLabel: 'Aman',
              ),
              SizedBox(height: 16),
              CashSummaryRow(
                balance: 'Rp8,4jt',
                inflow: '+Rp5,2jt',
                outflow: '-Rp3,1jt',
              ),
              SizedBox(height: 16),
              OwnerCutCard(safeAmount: 'Rp1,2jt'),
              SizedBox(height: 16),
              RecentTransactionsSection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        backgroundColor: FlundsColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const FlundsBottomNav(),
    );
  }
}