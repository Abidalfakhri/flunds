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

  Color get _statusColor {
    if (statusLabel == 'Sehat') return FlundsColors.income;
    if (statusLabel == 'Aman') return FlundsColors.primary;
    return FlundsColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FlundsColors.primary, FlundsColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RUNWAY KAS SAAT INI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: _statusColor == FlundsColors.expense ? Colors.orangeAccent : Colors.lightGreenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$runwayDays ', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
                const TextSpan(text: 'hari', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ambang batas aman: $thresholdDays hari — bisa diubah di Profil',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
