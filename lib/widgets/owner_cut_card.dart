import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OwnerCutCard extends StatelessWidget {
  final String safeAmount;
  final VoidCallback? onWithdrawPressed;

  const OwnerCutCard({super.key, required this.safeAmount, this.onWithdrawPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlundsColors.ownerCutBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.savings_outlined, color: FlundsColors.ownerCutText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Smart Owner's Cut", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FlundsColors.ownerCutText, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('Aman ditarik $safeAmount', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onWithdrawPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Tarik'),
          ),
        ],
      ),
    );
  }
}
