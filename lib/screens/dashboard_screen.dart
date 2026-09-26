import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/greeting_header.dart';
import '../widgets/runway_card.dart';
import '../widgets/cash_summary_row.dart';
import '../widgets/owner_cut_card.dart';
import '../widgets/section_header.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import 'owner_withdraw_screen.dart';
import 'transactions_list_screen.dart';
import 'transaction_detail_screen.dart';
import 'profile_settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appData,
          builder: (context, _) {
            final recent = appData.recentTransactions;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isExpanded ? 32 : 18,
                vertical: 14,
              ),
              child: ContentBounds(
                maxWidth: context.isExpanded ? 980 : 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingHeader(
                      userName: appData.ownerName.split(' ').first,
                      businessName: appData.businessName,
                      onAvatarTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ResponsiveTopSection(),
                    const SizedBox(height: 16),
                    CashSummaryRow(
                      balance: formatRupiahCompact(appData.currentBalance),
                      inflow: '+${formatRupiahCompact(appData.monthIncome)}',
                      outflow: '-${formatRupiahCompact(appData.monthExpense)}',
                    ),
                    const SizedBox(height: 16),
                    OwnerCutCard(
                      safeAmount: formatRupiahCompact(appData.ownerCutSafeAmount),
                      onWithdrawPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerWithdrawScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Transaksi terbaru',
                      actionLabel: 'Lihat semua',
                      onActionTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionsListScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: _cardDecoration(),
                      child: recent.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Belum ada transaksi',
                              message: 'Tekan tombol + untuk mencatat transaksi pertamamu.',
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < recent.length; i++)
                                  TransactionTile(
                                    item: recent[i],
                                    showDivider: i < recent.length - 1,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDetailScreen(transactionId: recent[i].id),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE7DB)),
      );
}

class _ResponsiveTopSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final runwayCard = RunwayCard(
      runwayDays: appData.runwayDays,
      thresholdDays: appData.runwayThresholdDays,
      progress: appData.runwayProgress,
      statusLabel: appData.runwayStatusLabel,
    );

    if (!context.isExpanded) return runwayCard;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: runwayCard),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEDE7DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Jenis usaha', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(appData.businessType, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  Text('Total kategori aktif', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('${appData.categories.length} kategori', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
