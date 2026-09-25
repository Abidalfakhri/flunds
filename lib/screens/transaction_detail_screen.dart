import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_dialog.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final item = appData.transactionById(transactionId);
          if (item == null) {
            return const Center(child: Text('Transaksi ini sudah dihapus.'));
          }
          final category = appData.categoryById(item.categoryId);
          final isIncome = category.isIncome;
          final amountColor = isIncome ? FlundsColors.income : FlundsColors.expense;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isIncome ? FlundsColors.incomeSoft : FlundsColors.expenseSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Icon(category.icon, color: category.color, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${isIncome ? '+' : '-'}${formatRupiah(item.amount)}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: amountColor),
                        ),
                        const SizedBox(height: 6),
                        Text(item.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Kategori', value: category.name),
                  _DetailRow(label: 'Tanggal', value: formatDateFull(item.date)),
                  _DetailRow(label: 'Jenis dana', value: item.isPersonal ? 'Pribadi (owner)' : 'Bisnis'),
                  if (item.note.trim().isNotEmpty) _DetailRow(label: 'Catatan', value: item.note),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TransactionFormScreen(existing: item)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Ubah'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'Hapus transaksi?',
                              message: 'Transaksi "${item.title}" akan dihapus permanen dan mempengaruhi saldo & runway.',
                            );
                            if (confirmed) {
                              appData.deleteTransaction(item.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: FlundsColors.expense),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
