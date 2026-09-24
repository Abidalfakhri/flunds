import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OwnerWithdrawScreen extends StatefulWidget {
  const OwnerWithdrawScreen({super.key});

  @override
  State<OwnerWithdrawScreen> createState() => _OwnerWithdrawScreenState();
}

class _OwnerWithdrawScreenState extends State<OwnerWithdrawScreen> {
  final _controller = TextEditingController();
  final int _batasAman = 1200000;
  bool _melebihi = false;

  void _cek(String value) {
    final nominal = int.tryParse(value) ?? 0;
    setState(() => _melebihi = nominal > _batasAman);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarik Owner's Cut")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: FlundsColors.ownerCutBg, borderRadius: BorderRadius.circular(12)),
              child: Text('Batas aman penarikan bulan ini: Rp$_batasAman', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              onChanged: _cek,
              decoration: const InputDecoration(labelText: 'Nominal penarikan', prefixText: 'Rp ', border: OutlineInputBorder()),
            ),
            if (_melebihi) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFBE9E7), borderRadius: BorderRadius.circular(10)),
                child: const Text('Penarikan melebihi batas aman yang direkomendasikan', style: TextStyle(color: FlundsColors.expense)),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _melebihi ? FlundsColors.expense : FlundsColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_melebihi ? 'Tarik Meski Melebihi Batas' : 'Konfirmasi Penarikan'),
            ),
          ],
        ),
      ),
    );
  }
}
