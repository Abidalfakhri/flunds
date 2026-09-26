import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class OwnerWithdrawScreen extends StatefulWidget {
  const OwnerWithdrawScreen({super.key});

  @override
  State<OwnerWithdrawScreen> createState() => _OwnerWithdrawScreenState();
}

class _OwnerWithdrawScreenState extends State<OwnerWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _noteController = TextEditingController();
  bool _melebihi = false;

  void _cek(String value) {
    final nominal = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() => _melebihi = nominal > appData.ownerCutSafeAmount);
  }

  void _konfirmasi() {
    if (!_formKey.currentState!.validate()) return;
    final nominal = int.parse(_controller.text.replaceAll(RegExp(r'[^0-9]'), ''));

    appData.addTransaction(
      title: "Owner's cut${_noteController.text.trim().isEmpty ? '' : ' - ${_noteController.text.trim()}'}",
      amount: nominal,
      categoryId: 'cat-owner-cut',
      date: DateTime.now(),
      isPersonal: true,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Penarikan ${formatRupiah(nominal)} berhasil dicatat')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarik Owner's Cut")),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: FlundsColors.ownerCutBg, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Batas aman penarikan saat ini', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FlundsColors.ownerCutText)),
                          const SizedBox(height: 4),
                          Text(formatRupiah(appData.ownerCutSafeAmount), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      onChanged: _cek,
                      decoration: const InputDecoration(labelText: 'Nominal penarikan', prefixText: 'Rp '),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                        if (n == null || n <= 0) return 'Masukkan nominal yang valid';
                        if (n > appData.currentBalance) return 'Melebihi saldo kas yang tersedia';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Keperluan (opsional)'),
                    ),
                    if (_melebihi) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: FlundsColors.expenseSoft, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18, color: FlundsColors.expense),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Penarikan melebihi batas aman yang direkomendasikan. Runway kas bisa turun di bawah ambang batas.',
                                style: TextStyle(color: FlundsColors.expense, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _konfirmasi,
                      style: ElevatedButton.styleFrom(backgroundColor: _melebihi ? FlundsColors.expense : FlundsColors.primary),
                      child: Text(_melebihi ? 'Tarik Meski Melebihi Batas' : 'Konfirmasi Penarikan'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
