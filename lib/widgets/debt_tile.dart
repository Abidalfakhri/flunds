import 'package:flutter/material.dart';
import '../models/debt_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DebtTile extends StatelessWidget {
  final DebtItem debt;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePaid;

  const DebtTile({super.key, required this.debt, this.onTap, this.onTogglePaid});

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.isReceivable;
    final accent = isReceivable ? FlundsColors.income : FlundsColors.expense;
    final overdue = debt.isOverdue;
    final statusLabel = debt.isPaid
        ? (isReceivable ? 'Sudah diterima' : 'Sudah dibayar')
        : (overdue ? 'Terlambat' : formatDateRelative(debt.dueDate));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: overdue && !debt.isPaid
                ? FlundsColors.expense.withValues(alpha: 0.4)
                : FlundsColors.surfaceLine,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.partyName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isReceivable ? 'Piutang' : 'Utang'} · $statusLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overdue && !debt.isPaid ? FlundsColors.expense : FlundsColors.textMuted,
                          fontWeight: overdue && !debt.isPaid ? FontWeight.w700 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatRupiahCompact(debt.amount),
                    style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onTogglePaid,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: debt.isPaid ? FlundsColors.incomeSoft : FlundsColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FlundsColors.surfaceLine),
                    ),
                    child: Text(
                      debt.isPaid ? 'Lunas ✓' : 'Tandai lunas',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
