import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String _categoryFilter = 'Semua';
  String _query = '';

  List<TransactionItem> _apply(List<TransactionItem> items) {
    var result = items;
    if (_categoryFilter != 'Semua') {
      result = result.where((t) => appData.categoryById(t.categoryId).name == _categoryFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final categories = ['Semua', ...appData.categories.map((c) => c.name)];
          final filtered = _apply(appData.transactions);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ContentBounds(
                  maxWidth: 820,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: categories.map((c) {
                        final selected = c == _categoryFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            onSelected: (_) => setState(() => _categoryFilter = c),
                            selectedColor: FlundsColors.primarySoft,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'Tidak ditemukan',
                        message: 'Coba ubah kata kunci atau filter kategori.',
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              return TransactionTile(
                                item: filtered[i],
                                showDivider: i < filtered.length - 1,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(transactionId: filtered[i].id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
