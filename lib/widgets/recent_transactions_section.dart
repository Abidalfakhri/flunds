import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction_item.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  static final List<TransactionItem> _dummyItems = [
    TransactionItem(title: 'Belanja bahan baku', amount: '-Rp450rb', isIncome: false, category: 'Operasional', date: DateTime(2026, 9, 20), isPersonal: false),
    TransactionItem(title: 'Penjualan online', amount: '+Rp620rb', isIncome: true, category: 'Penjualan', date: DateTime(2026, 9, 19), isPersonal: false),
    TransactionItem(title: "Owner's cut", amount: '-Rp300rb', isIncome: false, category: "Owner's Cut", date: DateTime(2026, 9, 18), isPersonal: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Transaksi terbaru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Lihat semua', style: TextStyle(fontSize: 12, color: FlundsColors.ownerCutText)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              for (int i = 0; i < _dummyItems.length; i++)
                _TransactionRow(item: _dummyItems[i], showDivider: i < _dummyItems.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionItem item;
  final bool showDivider;

  const _TransactionRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: Color(0xFFEDEDED))) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 13)),
          Text(
            item.amount,
            style: TextStyle(fontSize: 13, color: item.isIncome ? FlundsColors.income : FlundsColors.expense),
          ),
        ],
      ),
    );
  }
}
