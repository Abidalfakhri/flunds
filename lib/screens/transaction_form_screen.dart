import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'category_form_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionItem? existing;

  /// When set (and only used for a brand-new transaction), preselects the
  /// income/expense type and filters the category picker to match — used by
  /// the quick-add sheet so "Pemasukan" and "Pengeluaran" actually open a
  /// form that's already pointed the right way.
  final CategoryType? initialType;

  const TransactionFormScreen({super.key, this.existing, this.initialType});

  bool get isEditing => existing != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late CategoryType _type;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _isPersonal = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = groupThousands(existing.amount);
      _noteController.text = existing.note;
      _categoryId = existing.categoryId;
      _date = existing.date;
      _isPersonal = existing.isPersonal;
      _type = appData.categoryById(existing.categoryId).type;
    } else {
      _type = widget.initialType ?? CategoryType.expense;
      final ofType = appData.categoriesByType(_type);
      _categoryId = ofType.isNotEmpty
          ? ofType.first.id
          : (appData.categories.isNotEmpty ? appData.categories.first.id : null);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _changeType(CategoryType type) {
    setState(() {
      _type = type;
      final ofType = appData.categoriesByType(type);
      _categoryId = ofType.isNotEmpty ? ofType.first.id : null;
    });
  }

  Future<void> _createCategoryInline() async {
    final created = await Navigator.push<Category>(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(initialType: _type)),
    );
    if (created != null) {
      setState(() {
        _type = created.type;
        _categoryId = created.id;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau buat kategori terlebih dahulu')),
      );
      return;
    }

    final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (widget.isEditing) {
      final updated = appData.updateTransaction(
        widget.existing!.copyWith(
          title: _titleController.text,
          amount: amount,
          categoryId: _categoryId,
          date: _date,
          isPersonal: _isPersonal,
          note: _noteController.text,
        ),
      );
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi tidak bisa diperbarui. Data mungkin sudah berubah.')),
        );
        return;
      }
    } else {
      appData.addTransaction(
        title: _titleController.text,
        amount: amount,
        categoryId: _categoryId!,
        date: _date,
        isPersonal: _isPersonal,
        note: _noteController.text,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEditing ? 'Transaksi diperbarui' : 'Transaksi disimpan')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Ubah Transaksi'
        : (_type == CategoryType.income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final categories = appData.categoriesByType(_type);
          final selectedCategoryId = categories.any((c) => c.id == _categoryId)
              ? _categoryId
              : (categories.isNotEmpty ? categories.first.id : null);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Jenis transaksi', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    SegmentedButton<CategoryType>(
                      segments: const [
                        ButtonSegment(value: CategoryType.income, label: Text('Masuk'), icon: Icon(Icons.south_west_rounded, size: 16)),
                        ButtonSegment(value: CategoryType.expense, label: Text('Keluar'), icon: Icon(Icons.north_east_rounded, size: 16)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => _changeType(s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Judul transaksi'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
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
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text('${_date.day}/${_date.month}/${_date.year}'),
                    ),
                    const SizedBox(height: 14),
                    Text('Kategori', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in categories)
                          ChoiceChip(
                            avatar: Icon(c.icon, size: 16, color: c.id == _categoryId ? FlundsColors.primary : FlundsColors.textMuted),
                            label: Text(c.name),
                            selected: c.id == selectedCategoryId,
                            selectedColor: FlundsColors.primarySoft,
                            onSelected: (_) => setState(() => _categoryId = c.id),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Kategori baru'),
                          onPressed: _createCategoryInline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isPersonal,
                      onChanged: (v) => setState(() => _isPersonal = v),
                      title: const Text('Dana pribadi (bukan operasional bisnis)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi'),
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
