import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_dialog.dart';
import 'category_form_screen.dart';

class CategoriesListScreen extends StatelessWidget {
  const CategoriesListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus kategori?',
      message: 'Kategori "${category.name}" akan dihapus dari daftar kategori.',
    );
    if (!confirmed) return;

    final result = appData.deleteCategory(category.id);
    if (!context.mounted) return;

    final messages = {
      DeleteCategoryResult.success: 'Kategori "${category.name}" dihapus.',
      DeleteCategoryResult.inUse: 'Tidak bisa dihapus: masih dipakai oleh transaksi yang ada. Ubah transaksi tersebut ke kategori lain dulu.',
      DeleteCategoryResult.isLastOfType: 'Tidak bisa dihapus: ini satu-satunya kategori ${category.isIncome ? 'pemasukan' : 'pengeluaran'} yang tersisa.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messages[result]!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final income = appData.categoriesByType(CategoryType.income);
          final expense = appData.categoriesByType(CategoryType.expense);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Text('Pemasukan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...income.map((c) => _CategoryTile(category: c, onDelete: () => _confirmDelete(context, c))),
                  const SizedBox(height: 20),
                  Text('Pengeluaran', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...expense.map((c) => _CategoryTile(category: c, onDelete: () => _confirmDelete(context, c))),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-categories',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryFormScreen())),
        backgroundColor: FlundsColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Kategori', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;

  const _CategoryTile({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: category.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(category.icon, color: category.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 19),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryFormScreen(existing: category))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 19, color: FlundsColors.expense),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
