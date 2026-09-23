import 'package:flutter/material.dart';
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
      children: const [
        Expanded(child: StatCard(label: 'Saldo', value: '-')),
        SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Masuk', value: '-')),
        SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Keluar', value: '-')),
      ],
    );
  }
}