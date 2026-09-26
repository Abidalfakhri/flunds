import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScenarioCard extends StatelessWidget {
  final String label;
  final int runwayBefore;
  final int runwayAfter;

  const ScenarioCard({super.key, required this.label, required this.runwayBefore, required this.runwayAfter});

  @override
  Widget build(BuildContext context) {
    final delta = runwayAfter - runwayBefore;
    final deltaColor = delta < 0 ? FlundsColors.expense : FlundsColors.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sebelum', style: Theme.of(context).textTheme.bodySmall),
                    Text('$runwayBefore hari', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: FlundsColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sesudah', style: Theme.of(context).textTheme.bodySmall),
                    Text('$runwayAfter hari', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Text(
                '${delta > 0 ? '+' : ''}$delta hari',
                style: TextStyle(color: deltaColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
