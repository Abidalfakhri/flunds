import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/insight.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';
import 'categories_list_screen.dart';
import 'debts_screen.dart';
import 'savings_goals_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _handleTap(BuildContext context, Insight insight) {
    switch (insight.action) {
      case InsightAction.openDebts:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()));
        break;
      case InsightAction.openGoals:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()));
        break;
      case InsightAction.openAnalysis:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen()));
        break;
      case InsightAction.openCategories:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesListScreen()));
        break;
      case InsightAction.none:
        break;
    }
  }

  Color _levelColor(InsightLevel level) {
    switch (level) {
      case InsightLevel.critical:
        return FlundsColors.expense;
      case InsightLevel.warning:
        return FlundsColors.warning;
      case InsightLevel.info:
        return FlundsColors.primary;
    }
  }

  Color _levelBg(InsightLevel level) {
    switch (level) {
      case InsightLevel.critical:
        return FlundsColors.expenseSoft;
      case InsightLevel.warning:
        return FlundsColors.warningSoft;
      case InsightLevel.info:
        return FlundsColors.primarySoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pemberitahuan')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final insights = appData.insights;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: insights.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final insight = insights[i];
                  return InkWell(
                    onTap: insight.action == InsightAction.none ? null : () => _handleTap(context, insight),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FlundsColors.surfaceLine),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: _levelBg(insight.level), borderRadius: BorderRadius.circular(12)),
                            child: Icon(insight.icon, size: 19, color: _levelColor(insight.level)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insight.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(insight.message, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (insight.action != InsightAction.none)
                            const Padding(
                              padding: EdgeInsets.only(left: 6, top: 8),
                              child: Icon(Icons.chevron_right, size: 18, color: FlundsColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
