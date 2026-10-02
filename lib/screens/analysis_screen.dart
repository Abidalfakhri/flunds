import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/app_data.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../utils/summary_builder.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import 'simulation_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareSummary(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: buildCashflowSummary(appData)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringkasan disalin — tinggal tempel ke WhatsApp atau catatanmu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appData,
          builder: (context, _) {
            final hasTransactions = appData.transactions.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.isExpanded ? 32 : 18,
                    14,
                    context.isExpanded ? 32 : 18,
                    0,
                  ),
                  child: ContentBounds(
                    maxWidth: context.isExpanded ? 980 : 720,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analisis Usaha', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                'Ringkasan performa kas ${appData.businessName} bulan ini',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => _shareSummary(context),
                          tooltip: 'Bagikan ringkasan',
                          icon: const Icon(Icons.ios_share_outlined, size: 19),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: FlundsColors.primary,
                  unselectedLabelColor: FlundsColors.textMuted,
                  indicatorColor: FlundsColors.primary,
                  tabs: const [
                    Tab(text: 'Ringkasan'),
                    Tab(text: 'Simulasi What-If'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          context.isExpanded ? 32 : 18,
                          14,
                          context.isExpanded ? 32 : 18,
                          90,
                        ),
                        child: ContentBounds(
                          maxWidth: context.isExpanded ? 980 : 720,
                          child: !hasTransactions
                              ? const EmptyState(
                                  icon: Icons.bar_chart_outlined,
                                  title: 'Belum ada data',
                                  message: 'Catat transaksi dulu supaya analisis bisa muncul di sini.',
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SummaryGrid(),
                                    if (appData.taxEstimateEnabled) ...[
                                      const SizedBox(height: 22),
                                      const SectionHeader(title: 'Estimasi Pajak UMKM'),
                                      const SizedBox(height: 10),
                                      _TaxEstimateCard(),
                                    ],
                                    const SizedBox(height: 22),
                                    const SectionHeader(title: 'Anggaran kategori bulan ini'),
                                    const SizedBox(height: 10),
                                    _BudgetSection(),
                                    const SizedBox(height: 22),
                                    const SectionHeader(title: 'Arus kas 14 hari terakhir'),
                                    const SizedBox(height: 10),
                                    _CashflowTrendCard(),
                                    const SizedBox(height: 22),
                                    const SectionHeader(title: 'Pengeluaran per kategori (sepanjang waktu)'),
                                    const SizedBox(height: 10),
                                    _CategoryBreakdownCard(type: CategoryType.expense),
                                    const SizedBox(height: 22),
                                    const SectionHeader(title: 'Pemasukan per kategori (sepanjang waktu)'),
                                    const SizedBox(height: 10),
                                    _CategoryBreakdownCard(type: CategoryType.income),
                                    const SizedBox(height: 22),
                                    const SectionHeader(title: 'Bisnis vs. pribadi (sepanjang waktu)'),
                                    const SizedBox(height: 10),
                                    _BusinessVsPersonalCard(),
                                  ],
                                ),
                        ),
                      ),
                      const SimulationTabView(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    final income = appData.monthIncome;
    final expense = appData.monthExpense;
    final net = income - expense;
    final margin = income > 0 ? (net / income * 100) : 0.0;
    final netColor = net >= 0 ? FlundsColors.income : FlundsColors.expense;

    final cards = [
      StatCard(
        label: 'Pemasukan bulan ini',
        value: formatRupiahCompact(income),
        valueColor: FlundsColors.income,
        icon: Icons.south_west_rounded,
      ),
      StatCard(
        label: 'Pengeluaran bulan ini',
        value: formatRupiahCompact(expense),
        valueColor: FlundsColors.expense,
        icon: Icons.north_east_rounded,
      ),
      StatCard(
        label: 'Laba bersih bulan ini',
        value: formatRupiahCompact(net),
        valueColor: netColor,
        icon: Icons.account_balance_wallet_outlined,
      ),
      StatCard(
        label: 'Margin keuntungan',
        value: '${margin.toStringAsFixed(0)}%',
        valueColor: netColor,
        icon: Icons.percent,
      ),
    ];

    return GridView.count(
      crossAxisCount: context.isExpanded ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: cards,
    );
  }
}

/// Rough PPh Final UMKM (0.5%) estimate — a differentiator most generic
/// UMKM bookkeeping apps skip. Nothing here is filed automatically; it's
/// just a heads-up so the owner can set the amount aside before it's spent,
/// based on gross turnover recorded in Flunds.
class _TaxEstimateCard extends StatelessWidget {
  const _TaxEstimateCard();

  @override
  Widget build(BuildContext context) {
    final yearIncome = appData.yearIncome;
    final exemptUsage = (yearIncome / AppData.pphFinalUmkmExemptThreshold).clamp(0.0, 1.0).toDouble();
    final estimatedTax = appData.estimatedMonthlyTax;
    final stillExempt = estimatedTax == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perkiraan pajak bulan ini', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiahCompact(estimatedTax),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: stillExempt ? FlundsColors.income : FlundsColors.warning,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: FlundsColors.ownerCutBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(Icons.account_balance_outlined, color: FlundsColors.ownerCutText, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: exemptUsage,
              minHeight: 6,
              backgroundColor: FlundsColors.surfaceLine,
              valueColor: const AlwaysStoppedAnimation<Color>(FlundsColors.ownerCutText),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Omzet tahun ini: ${formatRupiahCompact(yearIncome)} dari batas bebas pajak '
            '${formatRupiahCompact(AppData.pphFinalUmkmExemptThreshold)}/tahun',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            stillExempt
                ? 'Omzet setahun masih di bawah Rp500 juta, jadi belum kena PPh Final UMKM.'
                : 'Berdasarkan PPh Final UMKM 0,5% dari omzet di atas Rp500 juta/tahun (PP 55/2022). '
                    'Perkiraan kasar, bukan pengganti perhitungan resmi atau konsultasi pajak.',
            style: const TextStyle(fontSize: 11, color: FlundsColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    final budgeted = appData.categoriesByType(CategoryType.expense).where((c) => c.hasBudget).toList();

    if (budgeted.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: FlundsColors.surfaceLine)),
        child: Text(
          'Belum ada kategori dengan anggaran. Atur anggaran bulanan lewat menu Kelola Kategori supaya Flunds bisa mengingatkan kalau pengeluaran mendekati batas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: FlundsColors.surfaceLine)),
      child: Column(
        children: [
          for (int i = 0; i < budgeted.length; i++)
            _BudgetRow(category: budgeted[i], showDivider: i < budgeted.length - 1),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Category category;
  final bool showDivider;
  const _BudgetRow({required this.category, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final spent = appData.categorySpentThisMonth(category.id);
    final budget = category.monthlyBudget!;
    final usage = budget == 0 ? 0.0 : spent / budget;
    final over = usage >= 1.0;
    final barColor = over ? FlundsColors.expense : (usage >= 0.9 ? FlundsColors.warning : category.color);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: FlundsColors.surfaceLine)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: category.color),
              const SizedBox(width: 8),
              Expanded(child: Text(category.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
              Text(
                '${formatRupiahCompact(spent)} / ${formatRupiahCompact(budget)}',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: over ? FlundsColors.expense : FlundsColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usage.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: FlundsColors.surfaceLine,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            over ? 'Melebihi anggaran ${(usage * 100).round()}%' : '${(usage * 100).round()}% terpakai bulan ini',
            style: TextStyle(fontSize: 11, color: over ? FlundsColors.expense : FlundsColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CashflowTrendCard extends StatelessWidget {
  const _CashflowTrendCard();

  static const int _days = 14;
  static const double _maxBarHeight = 90;

  @override
  Widget build(BuildContext context) {
    final data = appData.netCashflowByDay(_days);
    final entries = data.entries.toList();
    final maxAbs = entries.fold<int>(1, (m, e) => e.value.abs() > m ? e.value.abs() : m);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _maxBarHeight + 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: _maxBarHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (e.value.abs() / maxAbs).clamp(0.04, 1.0).toDouble(),
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: e.value >= 0 ? FlundsColors.income : FlundsColors.expense,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${e.key.day}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9.5, color: FlundsColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: const [
              _LegendDot(color: FlundsColors.income, label: 'Kas masuk bersih'),
              _LegendDot(color: FlundsColors.expense, label: 'Kas keluar bersih'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: FlundsColors.textMuted)),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final CategoryType type;
  const _CategoryBreakdownCard({required this.type});

  @override
  Widget build(BuildContext context) {
    final entries = appData.categoryBreakdown(type);
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: Text('Belum ada data untuk kategori ini.', style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++)
            _BreakdownRow(
              category: entries[i].key,
              amount: entries[i].value,
              share: total == 0 ? 0 : entries[i].value / total,
              showDivider: i < entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Category category;
  final int amount;
  final double share;
  final bool showDivider;

  const _BreakdownRow({
    required this.category,
    required this.amount,
    required this.share,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: FlundsColors.surfaceLine)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(category.icon, size: 16, color: category.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRupiahCompact(amount),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    backgroundColor: FlundsColors.surfaceLine,
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(share * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessVsPersonalCard extends StatelessWidget {
  const _BusinessVsPersonalCard();

  @override
  Widget build(BuildContext context) {
    final business = appData.businessOutflow;
    final personal = appData.personalOutflow;
    final total = business + personal;
    final businessShare = total == 0 ? 0.5 : business / total;
    final businessFlex = (businessShare * 1000).round().clamp(1, 999).toInt();
    final personalFlex = (1000 - businessFlex).clamp(1, 999).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porsi seluruh pengeluaran tercatat yang dipakai untuk operasional bisnis dibanding kebutuhan pribadi (termasuk owner\'s cut).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: businessFlex, child: Container(color: FlundsColors.primary)),
                  Expanded(flex: personalFlex, child: Container(color: FlundsColors.accent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LegendStat(color: FlundsColors.primary, label: 'Bisnis', value: formatRupiahCompact(business)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LegendStat(color: FlundsColors.accent, label: 'Pribadi', value: formatRupiahCompact(personal)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendStat extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendStat({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
