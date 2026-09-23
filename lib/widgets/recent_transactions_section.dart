import 'package:flutter/material.dart';
import '../models/transaction_item.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('RecentTransactionsSection (Anggota C)',
          style: TextStyle(color: Colors.grey)),
    );
  }
}