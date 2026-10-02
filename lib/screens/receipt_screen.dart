import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/app_data.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// A simple, shareable receipt/"nota" built from an income transaction —
/// useful for a UMKM owner who wants to send proof of payment to a customer
/// without needing a real invoicing system.
class ReceiptScreen extends StatelessWidget {
  final TransactionItem transaction;
  const ReceiptScreen({super.key, required this.transaction});

  String get _receiptText {
    final buffer = StringBuffer();
    buffer.writeln('NOTA — ${appData.businessName}');
    buffer.writeln('-------------------------------');
    buffer.writeln(transaction.title);
    buffer.writeln('Tanggal : ${formatDateFull(transaction.date)}');
    buffer.writeln('Jumlah  : ${formatRupiah(transaction.amount)}');
    if (transaction.note.trim().isNotEmpty) {
      buffer.writeln('Catatan : ${transaction.note.trim()}');
    }
    buffer.writeln('-------------------------------');
    buffer.writeln('Terima kasih telah bertransaksi dengan ${appData.businessName}.');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota Transaksi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FlundsColors.surfaceLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appData.businessName, style: Theme.of(context).textTheme.titleLarge),
                    Text(appData.businessType, style: Theme.of(context).textTheme.bodySmall),
                    const Divider(height: 28),
                    Text(transaction.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(formatDateFull(transaction.date), style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 14),
                    Text(
                      formatRupiah(transaction.amount),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: FlundsColors.income),
                    ),
                    if (transaction.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('Catatan', style: Theme.of(context).textTheme.bodySmall),
                      Text(transaction.note, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const Divider(height: 28),
                    Text(
                      'Terima kasih telah bertransaksi dengan ${appData.businessName}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _receiptText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota disalin — tinggal tempel ke chat pembeli')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Salin Nota sebagai Teks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
