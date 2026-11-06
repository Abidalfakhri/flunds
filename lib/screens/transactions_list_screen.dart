import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

/// Rentang waktu yang bisa dipilih untuk menyaring daftar transaksi.
enum _Period { all, last7, thisMonth, last30 }

const _periodLabels = {
  _Period.all: 'Semua waktu',
  _Period.last7: '7 hari terakhir',
  _Period.thisMonth: 'Bulan ini',
  _Period.last30: '30 hari terakhir',
};

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String _categoryFilter = 'Semua';
  String _scope = 'Semua';
  String _query = '';
  _Period _period = _Period.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True jika [date] masuk ke rentang waktu yang sedang dipilih.
  /// Rentang bergulir (7/30 hari) dibatasi sampai hari ini, jadi transaksi
  /// yang tanggalnya di masa depan tidak ikut terhitung.
  bool _inPeriod(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return switch (_period) {
      _Period.all => true,
      _Period.thisMonth => date.year == now.year && date.month == now.month,
      _Period.last7 => !day.isAfter(today) && !day.isBefore(DateTime(today.year, today.month, today.day - 6)),
      _Period.last30 => !day.isAfter(today) && !day.isBefore(DateTime(today.year, today.month, today.day - 29)),
    };
  }

  List<TransactionItem> _apply(List<TransactionItem> items, String categoryFilter) {
    var result = items;
    if (categoryFilter != 'Semua') {
      result = result.where((t) => appData.categoryById(t.categoryId).name == categoryFilter).toList();
    }
    if (_scope == 'Bisnis') {
      result = result.where((t) => !t.isPersonal).toList();
    } else if (_scope == 'Pribadi') {
      result = result.where((t) => t.isPersonal).toList();
    }
    if (_period != _Period.all) {
      result = result.where((t) => _inPeriod(t.date)).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((t) {
        final categoryName = appData.categoryById(t.categoryId).name.toLowerCase();
        return t.title.toLowerCase().contains(q) || t.note.toLowerCase().contains(q) || categoryName.contains(q);
      }).toList();
    }
    return result;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _categoryFilter = 'Semua';
      _scope = 'Semua';
      _period = _Period.all;
    });
  }

  Widget _buildSummary(BuildContext context, List<TransactionItem> filtered, bool hasActiveFilter) {
    var income = 0;
    var expense = 0;
    for (final t in filtered) {
      if (appData.categoryById(t.categoryId).isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ContentBounds(
        maxWidth: 820,
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(text: '${filtered.length} transaksi'),
                    if (_period != _Period.all) TextSpan(text: ' · ${_periodLabels[_period]}'),
                    const TextSpan(text: ' · '),
                    TextSpan(
                      text: '+${formatRupiahCompact(income)}',
                      style: const TextStyle(color: FlundsColors.income, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: '-${formatRupiahCompact(expense)}',
                      style: const TextStyle(color: FlundsColors.expense, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasActiveFilter)
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Atur ulang'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final categories = ['Semua', ...appData.categories.map((c) => c.name)];
          // Jika kategori yang dipilih sudah dihapus/diganti namanya, anggap
          // filter "Semua" supaya daftar tidak kosong tanpa alasan.
          final activeCategory = categories.contains(_categoryFilter) ? _categoryFilter : 'Semua';
          final filtered = _apply(appData.transactions, activeCategory);
          final hasActiveFilter =
              activeCategory != 'Semua' || _scope != 'Semua' || _period != _Period.all || _query.trim().isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ContentBounds(
                  maxWidth: 820,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Cari judul, catatan, atau kategori...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: 'Bersihkan pencarian',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<_Period>(
                        tooltip: 'Filter periode',
                        initialValue: _period,
                        onSelected: (p) => setState(() => _period = p),
                        icon: Icon(
                          Icons.date_range_outlined,
                          color: _period == _Period.all ? FlundsColors.textMuted : FlundsColors.primary,
                        ),
                        itemBuilder: (context) => [
                          for (final entry in _periodLabels.entries)
                            PopupMenuItem<_Period>(value: entry.key, child: Text(entry.value)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ContentBounds(
                  maxWidth: 820,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Semua', label: Text('Semua dana')),
                        ButtonSegment(value: 'Bisnis', label: Text('Bisnis')),
                        ButtonSegment(value: 'Pribadi', label: Text('Pribadi')),
                      ],
                      selected: {_scope},
                      onSelectionChanged: (s) => setState(() => _scope = s.first),
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
                        final selected = c == activeCategory;
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
              _buildSummary(context, filtered, hasActiveFilter),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'Tidak ditemukan',
                        message: 'Coba ubah kata kunci, periode, atau filter kategori.',
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
