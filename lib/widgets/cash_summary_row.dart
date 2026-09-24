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
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Saldo kas', value: balance)),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'Masuk bln ini',
            value: inflow,
            valueColor: FlundsColors.income,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'Keluar bln ini',
            value: outflow,
            valueColor: FlundsColors.expense,
          ),
        ),
      ],
    );
  }
}