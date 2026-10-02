import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'stat_card.dart';

class CashSummaryRow extends StatelessWidget {
  final String balance;
  final String inflow;
  final String outflow;

  const CashSummaryRow({
    super.key,
    required this.balance,
    required this.inflow,
    required this.outflow,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(label: 'Saldo kas', value: balance, icon: Icons.account_balance_wallet_outlined),
      StatCard(label: 'Masuk bln ini', value: inflow, valueColor: FlundsColors.income, icon: Icons.south_west_rounded),
      StatCard(label: 'Keluar bln ini', value: outflow, valueColor: FlundsColors.expense, icon: Icons.north_east_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                SizedBox(width: double.infinity, child: cards[i]),
                if (i < cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}
