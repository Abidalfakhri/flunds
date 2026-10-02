import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/debt_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';

class DebtFormScreen extends StatefulWidget {
  final DebtItem? existing;
  final bool initialIsReceivable;

  const DebtFormScreen({super.key, this.existing, this.initialIsReceivable = true});

  bool get isEditing => existing != null;

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DebtType _type;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _partyController.text = existing.partyName;
      _amountController.text = groupThousands(existing.amount);
      _noteController.text = existing.note;
      _type = existing.type;
      _dueDate = existing.dueDate;
    } else {
      _type = widget.initialIsReceivable ? DebtType.receivable : DebtType.payable;
    }
  }

  @override
  void dispose() {
    _partyController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (widget.isEditing) {
      final updated = appData.updateDebt(
        widget.existing!.copyWith(
          type: _type,
          partyName: _partyController.text,
          amount: amount,
          dueDate: _dueDate,
          note: _noteController.text,
        ),
      );
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan tidak bisa diperbarui. Data mungkin sudah berubah.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan diperbarui')));
    } else {
      appData.addDebt(
        type: _type,
        partyName: _partyController.text,
        amount: amount,
        dueDate: _dueDate,
        note: _noteController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan disimpan')));
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus catatan?',
      message: 'Catatan ${_type == DebtType.receivable ? 'piutang' : 'utang'} ini akan dihapus permanen.',
    );
    if (!confirmed) return;
    final removed = appData.deleteDebt(widget.existing!.id);
    if (!mounted) return;
    if (removed) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan ini sudah tidak tersedia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceivable = _type == DebtType.receivable;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Ubah Catatan' : 'Utang / Piutang Baru'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: FlundsColors.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Jenis catatan', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(value: DebtType.receivable, label: Text('Piutang'), icon: Icon(Icons.call_received_rounded, size: 16)),
                    ButtonSegment(value: DebtType.payable, label: Text('Utang'), icon: Icon(Icons.call_made_rounded, size: 16)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partyController,
                  decoration: InputDecoration(
                    labelText: isReceivable
                        ? 'Nama pelanggan / pihak yang berutang'
                        : 'Nama supplier / pihak yang dibayar',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AmountInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                    if (n == null || n <= 0) return 'Masukkan nominal yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text('Jatuh tempo: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Catatan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
