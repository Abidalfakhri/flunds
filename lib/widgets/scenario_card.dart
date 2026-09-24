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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sebelum', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('$runwayBefore hari', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sesudah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('$runwayAfter hari', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Text('${delta > 0 ? '+' : ''}$delta hari', style: TextStyle(color: deltaColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
