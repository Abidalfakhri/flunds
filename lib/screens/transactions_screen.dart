import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'Semua';

  final List<TransactionItem> _items = [
    TransactionItem(title: 'Belanja bahan baku', amount: '-Rp450rb', isIncome: false, category: 'Operasional', date: DateTime(2026, 9, 20), isPersonal: false),
    TransactionItem(title: 'Penjualan online', amount: '+Rp620rb', isIncome: true, category: 'Penjualan', date: DateTime(2026, 9, 19), isPersonal: false),
    TransactionItem(title: "Owner's cut", amount: '-Rp300rb', isIncome: false, category: "Owner's Cut", date: DateTime(2026, 9, 18), isPersonal: true),
    TransactionItem(title: 'Sewa tempat', amount: '-Rp1,2jt', isIncome: false, category: 'Operasional', date: DateTime(2026, 9, 15), isPersonal: false),
    TransactionItem(title: 'Penjualan offline', amount: '+Rp340rb', isIncome: true, category: 'Penjualan', date: DateTime(2026, 9, 14), isPersonal: false),
  ];

  List<String> get _categories => ['Semua', ..._items.map((e) => e.category).toSet()];

  List<TransactionItem> get _filtered =>
      _filter == 'Semua' ? _items : _items.where((e) => e.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _categories.map((c) {
                final selected = c == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = c),
                    selectedColor: FlundsColors.primary.withOpacity(0.15),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = _filtered[i];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.category} · ${item.date.day}/${item.date.month}/${item.date.year}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.amount,
                        style: TextStyle(color: item.isIncome ? FlundsColors.income : FlundsColors.expense),
                      ),
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: null),
                      IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: null),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
