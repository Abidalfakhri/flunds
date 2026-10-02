import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;
  final bool showDivider;

  const TransactionTile({
    super.key,
    required this.item,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final category = appData.categoryById(item.categoryId);
    final isIncome = category.isIncome;
    final amountColor = isIncome ? FlundsColors.income : FlundsColors.expense;
    final sign = isIncome ? '+' : '-';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: FlundsColors.surfaceLine)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, size: 19, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${category.name} · ${formatDateShort(item.date)}${item.isPersonal ? ' · Pribadi' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${formatRupiahCompact(item.amount)}',
              style: TextStyle(color: amountColor, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}
