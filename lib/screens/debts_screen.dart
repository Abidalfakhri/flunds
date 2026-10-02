import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/debt_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/debt_tile.dart';
import '../widgets/empty_state.dart';
import 'debt_form_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DebtItem> _filterFor(int tabIndex, List<DebtItem> all) {
    if (tabIndex == 1) return all.where((d) => d.isReceivable).toList();
    if (tabIndex == 2) return all.where((d) => !d.isReceivable).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utang & Piutang'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Piutang'),
            Tab(text: 'Utang'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final all = appData.debts;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: ContentBounds(
                  maxWidth: 820,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TotalCard(
                          label: 'Total piutang',
                          hint: 'Uang yang masih harus diterima',
                          value: formatRupiahCompact(appData.totalReceivable),
                          color: FlundsColors.income,
                          icon: Icons.call_received_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TotalCard(
                          label: 'Total utang',
                          hint: 'Uang yang masih harus dibayar',
                          value: formatRupiahCompact(appData.totalPayable),
                          color: FlundsColors.expense,
                          icon: Icons.call_made_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(3, (i) {
                    final items = _filterFor(i, all);
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.handshake_outlined,
                        title: 'Belum ada catatan',
                        message: 'Tekan tombol + untuk mencatat utang atau piutang pertamamu.',
                      );
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final debt = items[index];
                            return DebtTile(
                              debt: debt,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DebtFormScreen(existing: debt)),
                              ),
                              onTogglePaid: () => appData.toggleDebtPaid(debt.id),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
      // No floatingActionButton here: this screen is one of AppShell's bottom
      // tabs, and AppShell already renders its own global "+" FAB (quick-add
      // sheet, which includes "Piutang Baru" / "Utang Baru"). Adding a second
      // FAB here used to stack directly on top of it in the same corner.
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final Color color;
  final IconData icon;

  const _TotalCard({
    required this.label,
    required this.hint,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(hint, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
        ],
      ),
    );
  }
}
