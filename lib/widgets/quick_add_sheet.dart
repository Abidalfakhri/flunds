import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../screens/transaction_form_screen.dart';
import '../screens/debt_form_screen.dart';
import '../screens/goal_form_screen.dart';
import '../screens/owner_withdraw_screen.dart';

/// Bottom sheet of one-tap shortcuts to the most common things a UMKM
/// owner records day to day — replacing a single generic "add transaction"
/// button with clearer, purpose-built entry points.
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 500 ? 2 : 3;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah Cepat',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih apa yang mau dicatat',
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 150,
                        children: [
                          _QuickAction(
                            icon: Icons.south_west_rounded,
                            label: 'Pemasukan',
                            color: FlundsColors.income,
                            onTap: () => _openTransactionForm(
                              sheetContext,
                              CategoryType.income,
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.north_east_rounded,
                            label: 'Pengeluaran',
                            color: FlundsColors.expense,
                            onTap: () => _openTransactionForm(
                              sheetContext,
                              CategoryType.expense,
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.savings_outlined,
                            label: "Tarik Owner's Cut",
                            color: FlundsColors.ownerCutText,
                            onTap: () => _openOwnerWithdraw(sheetContext),
                          ),
                          _QuickAction(
                            icon: Icons.call_received_rounded,
                            label: 'Piutang Baru',
                            color: FlundsColors.income,
                            onTap: () => _openDebtForm(
                              sheetContext,
                              isReceivable: true,
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.call_made_rounded,
                            label: 'Utang Baru',
                            color: FlundsColors.expense,
                            onTap: () => _openDebtForm(
                              sheetContext,
                              isReceivable: false,
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.flag_outlined,
                            label: 'Target Menabung',
                            color: FlundsColors.primary,
                            onTap: () => _openGoalForm(sheetContext),
                          ),
                        ],
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
  );
}

void _openTransactionForm(BuildContext context, CategoryType type) {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(initialType: type)));
}

void _openOwnerWithdraw(BuildContext context) {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerWithdrawScreen()));
}

void _openDebtForm(BuildContext context, {required bool isReceivable}) {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(builder: (_) => DebtFormScreen(initialIsReceivable: isReceivable)));
}

void _openGoalForm(BuildContext context) {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalFormScreen()));
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: FlundsColors.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: FlundsColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
