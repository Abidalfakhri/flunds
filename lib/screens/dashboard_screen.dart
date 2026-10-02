import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/insight.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/greeting_header.dart';
import '../widgets/runway_card.dart';
import '../widgets/cash_summary_row.dart';
import '../widgets/owner_cut_card.dart';
import '../widgets/section_header.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_card.dart';
import 'owner_withdraw_screen.dart';
import 'transactions_list_screen.dart';
import 'transaction_detail_screen.dart';
import 'profile_settings_screen.dart';
import 'notifications_screen.dart';
import 'debts_screen.dart';
import 'savings_goals_screen.dart';

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
            final insights = appData.insights;
            final alertCount = insights.where((i) => i.level != InsightLevel.info).length;
            final topInsight = insights.first;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.isExpanded ? 32 : 18,
                14,
                context.isExpanded ? 32 : 18,
                90,
              ),
              child: ContentBounds(
                maxWidth: context.isExpanded ? 980 : 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingHeader(
                      userName: appData.ownerName.split(' ').first,
                      businessName: appData.businessName,
                      notificationCount: alertCount,
                      onNotificationTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      onAvatarTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (topInsight.level != InsightLevel.info) ...[
                      _InsightBanner(
                        insight: topInsight,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      ),
                      const SizedBox(height: 14),
                    ],
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
                    const SizedBox(height: 16),
                    _DebtSummaryRow(),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Target menabung',
                      actionLabel: 'Kelola',
                      onActionTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GoalsPreviewRow(),
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

class _InsightBanner extends StatelessWidget {
  final Insight insight;
  final VoidCallback onTap;
  const _InsightBanner({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCritical = insight.level == InsightLevel.critical;
    final color = isCritical ? FlundsColors.expense : FlundsColors.warning;
    final bg = isCritical ? FlundsColors.expenseSoft : FlundsColors.warningSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(insight.icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 3),
                  Text(insight.message, style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DebtSummaryRow extends StatelessWidget {
  const _DebtSummaryRow();

  @override
  Widget build(BuildContext context) {
    final receivable = appData.totalReceivable;
    final payable = appData.totalPayable;
    if (receivable == 0 && payable == 0) return const SizedBox.shrink();

    Widget summary({required bool receivableSide}) {
      final color = receivableSide ? FlundsColors.income : FlundsColors.expense;
      final icon = receivableSide ? Icons.call_received_rounded : Icons.call_made_rounded;
      final label = receivableSide ? 'Piutang' : 'Utang';
      final value = receivableSide ? receivable : payable;
      return Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatRupiahCompact(value),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            if (compact) {
              return Column(
                children: [
                  summary(receivableSide: true),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  summary(receivableSide: false),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: summary(receivableSide: true)),
                Container(width: 1, height: 32, color: FlundsColors.surfaceLine),
                const SizedBox(width: 12),
                Expanded(child: summary(receivableSide: false)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: FlundsColors.textMuted),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoalsPreviewRow extends StatelessWidget {
  const _GoalsPreviewRow();

  @override
  Widget build(BuildContext context) {
    final goals = appData.goals;
    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: FlundsColors.surfaceLine)),
        child: const EmptyState(
          icon: Icons.flag_outlined,
          title: 'Belum ada target',
          message: 'Buat target menabung untuk alat baru atau dana darurat usaha.',
        ),
      );
    }
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: goals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => GoalCard(goal: goals[i], width: 220),
      ),
    );
  }
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
