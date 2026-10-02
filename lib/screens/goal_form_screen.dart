import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';

const _goalIconChoices = [
  Icons.flag_outlined,
  Icons.kitchen_outlined,
  Icons.shield_outlined,
  Icons.home_repair_service_outlined,
  Icons.local_shipping_outlined,
  Icons.storefront_outlined,
  Icons.school_outlined,
  Icons.celebration_outlined,
];

const _goalColorChoices = [
  Color(0xFF185FA5),
  Color(0xFF2F7A4D),
  Color(0xFFD97757),
  Color(0xFF1B5E4F),
  Color(0xFFC1533A),
  Color(0xFF6B6558),
];

class GoalFormScreen extends StatefulWidget {
  final SavingsGoal? existing;
  const GoalFormScreen({super.key, this.existing});

  bool get isEditing => existing != null;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 60));
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _icon = existing?.icon ?? _goalIconChoices.first;
    _color = existing?.color ?? _goalColorChoices.first;
    if (existing != null) {
      _nameController.text = existing.name;
      _targetController.text = groupThousands(existing.targetAmount);
      _currentController.text = groupThousands(existing.currentAmount);
      _targetDate = existing.targetDate;
    } else {
      _currentController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final target = int.parse(_targetController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final current = int.tryParse(_currentController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final clampedCurrent = current.clamp(0, target).toInt();

    if (widget.isEditing) {
      appData.updateGoal(
        widget.existing!.copyWith(
          name: _nameController.text,
          targetAmount: target,
          currentAmount: clampedCurrent,
          targetDate: _targetDate,
          icon: _icon,
          color: _color,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target diperbarui')));
    } else {
      appData.addGoal(
        name: _nameController.text,
        targetAmount: target,
        currentAmount: clampedCurrent,
        targetDate: _targetDate,
        icon: _icon,
        color: _color,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target menabung dibuat')));
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus target?',
      message: 'Target "${widget.existing!.name}" akan dihapus permanen.',
    );
    if (!confirmed) return;
    final removed = appData.deleteGoal(widget.existing!.id);
    if (!mounted) return;
    if (removed) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target ini sudah tidak tersedia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Ubah Target' : 'Target Menabung Baru'),
        actions: [
          if (widget.isEditing)
            IconButton(icon: const Icon(Icons.delete_outline, color: FlundsColors.expense), onPressed: _delete),
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama target (mis. Beli mesin baru)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AmountInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Jumlah target', prefixText: 'Rp '),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                    if (n == null || n <= 0) return 'Masukkan jumlah target yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _currentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AmountInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Uang yang sudah terkumpul', prefixText: 'Rp '),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text('Target tercapai sebelum: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}'),
                ),
                const SizedBox(height: 18),
                Text('Ikon', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goalIconChoices.map((icon) {
                    final selected = icon == _icon;
                    return InkWell(
                      onTap: () => setState(() => _icon = icon),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? _color.withValues(alpha: 0.15) : FlundsColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? _color : FlundsColors.surfaceLine, width: selected ? 1.6 : 1),
                        ),
                        child: Icon(icon, size: 19, color: selected ? _color : FlundsColors.textMuted),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text('Warna', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _goalColorChoices.map((color) {
                    final selected = color == _color;
                    return InkWell(
                      onTap: () => setState(() => _color = color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: FlundsColors.textPrimary, width: 2) : null,
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Target'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
