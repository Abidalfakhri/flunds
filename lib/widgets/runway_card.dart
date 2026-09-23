import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RunwayCard extends StatelessWidget {
  final int runwayDays;
  final int thresholdDays;
  final double progress;
  final String statusLabel;

  const RunwayCard({
    super.key,
    required this.runwayDays,
    required this.thresholdDays,
    required this.progress,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlundsColors.runwayBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Runway saat ini',
              style: TextStyle(fontSize: 12, color: FlundsColors.primary)),
          const SizedBox(height: 4),
          Text('$runwayDays hari',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: FlundsColors.primary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor:
              const AlwaysStoppedAnimation<Color>(FlundsColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('Status: $statusLabel · ambang batas $thresholdDays hari',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}