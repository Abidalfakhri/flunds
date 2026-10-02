import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onContribute;
  final double? width;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onContribute,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.daysLeft;
    final deadlineLabel = goal.isComplete
        ? 'Target tercapai 🎉'
        : (daysLeft < 0 ? 'Lewat tenggat' : '$daysLeft hari lagi');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width ?? double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: goal.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(goal.icon, color: goal.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: FlundsColors.surfaceLine,
                valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatRupiahCompact(goal.currentAmount)} / ${formatRupiahCompact(goal.targetAmount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(deadlineLabel, style: Theme.of(context).textTheme.bodySmall),
            if (onContribute != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onContribute,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: EdgeInsets.zero),
                  child: const Text('Tambah Tabungan', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
