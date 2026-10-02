import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

const _iconChoices = [
  Icons.storefront_outlined,
  Icons.ramen_dining_outlined,
  Icons.shopping_basket_outlined,
  Icons.build_outlined,
  Icons.home_work_outlined,
  Icons.account_balance_wallet_outlined,
  Icons.category_outlined,
  Icons.local_shipping_outlined,
  Icons.payments_outlined,
  Icons.school_outlined,
];

const _colorChoices = [
  Color(0xFF2F7A4D),
  Color(0xFF1B5E4F),
  Color(0xFFC1533A),
  Color(0xFFD97757),
  Color(0xFF185FA5),
  Color(0xFF8C4A2F),
  Color(0xFF6B6558),
];

class CategoryFormScreen extends StatefulWidget {
  final Category? existing;

  /// Preselects income/expense when creating a brand-new category (e.g.
  /// from inside the transaction form) so the owner doesn't have to
  /// re-select something they already told the app.
  final CategoryType? initialType;

  const CategoryFormScreen({super.key, this.existing, this.initialType});

  bool get isEditing => existing != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  CategoryType _type = CategoryType.expense;
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _icon = existing?.icon ?? _iconChoices.first;
    _color = existing?.color ?? _colorChoices.first;
    if (existing != null) {
      _nameController.text = existing.name;
      _type = existing.type;
      if (existing.hasBudget) _budgetController.text = groupThousands(existing.monthlyBudget!);
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final budgetDigits = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final budget = (_type == CategoryType.expense && budgetDigits.isNotEmpty) ? int.parse(budgetDigits) : null;

    if (widget.isEditing) {
      final result = appData.updateCategory(
        widget.existing!.copyWith(
          name: _nameController.text,
          type: _type,
          icon: _icon,
          color: _color,
          monthlyBudget: budget,
          clearBudget: budget == null,
        ),
      );
      if (result == UpdateCategoryResult.typeInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jenis kategori tidak bisa diubah karena sudah dipakai transaksi. Buat kategori baru jika ingin mengganti pemasukan/pengeluaran.'),
          ),
        );
        return;
      }
      if (result != UpdateCategoryResult.success) return;
      Navigator.pop(context);
    } else {
      final created = appData.addCategory(
        name: _nameController.text,
        type: _type,
        icon: _icon,
        color: _color,
      );
      if (budget != null) {
        appData.setCategoryBudget(created.id, budget);
      }
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Ubah Kategori' : 'Kategori Baru')),
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
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                    if (appData.categoryNameExists(v, excludingId: widget.existing?.id)) {
                      return 'Nama kategori sudah dipakai';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Jenis', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                SegmentedButton<CategoryType>(
                  segments: const [
                    ButtonSegment(value: CategoryType.income, label: Text('Masuk'), icon: Icon(Icons.south_west_rounded, size: 16)),
                    ButtonSegment(value: CategoryType.expense, label: Text('Keluar'), icon: Icon(Icons.north_east_rounded, size: 16)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                if (_type == CategoryType.expense) ...[
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Anggaran bulanan (opsional)',
                      prefixText: 'Rp ',
                      helperText: 'Isi supaya Flunds bisa mengingatkan kalau pengeluaran kategori ini mendekati batas.',
                      helperMaxLines: 2,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Ikon', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconChoices.map((icon) {
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
                  children: _colorChoices.map((color) {
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
                  child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Kategori'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
