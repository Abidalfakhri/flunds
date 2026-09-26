import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

enum DeleteCategoryResult { success, inUse, isLastOfType }

class AppData extends ChangeNotifier {
  AppData() {
    _seedCategories();
    _seedTransactions();
  }

  String ownerName = 'Rani Puspita';
  String businessName = 'Dapur Rani Catering';
  String businessType = 'Katering & jajanan rumahan';
  int runwayThresholdDays = 30;
  double ownerCutPercentage = 0.15;
  int startingBalance = 6500000;

  void updateProfile({
    String? ownerName,
    String? businessName,
    String? businessType,
    int? runwayThresholdDays,
    double? ownerCutPercentage,
  }) {
    this.ownerName = ownerName ?? this.ownerName;
    this.businessName = businessName ?? this.businessName;
    this.businessType = businessType ?? this.businessType;
    this.runwayThresholdDays = runwayThresholdDays ?? this.runwayThresholdDays;
    this.ownerCutPercentage = ownerCutPercentage ?? this.ownerCutPercentage;
    notifyListeners();
  }

  final List<Category> _categories = [];

  List<Category> get categories => List.unmodifiable(_categories);

  List<Category> categoriesByType(CategoryType type) =>
      _categories.where((c) => c.type == type).toList();

  Category categoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => const Category(
        id: 'cat-unknown',
        name: 'Tidak diketahui',
        type: CategoryType.expense,
        icon: Icons.help_outline,
        color: Colors.grey,
      ),
    );
  }

  bool categoryNameExists(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (c) => c.id != excludingId && c.name.trim().toLowerCase() == normalized,
    );
  }

  String _newCategoryId() => 'cat-${DateTime.now().microsecondsSinceEpoch}';

  Category addCategory({
    required String name,
    required CategoryType type,
    required IconData icon,
    required Color color,
  }) {
    final category = Category(
      id: _newCategoryId(),
      name: name.trim(),
      type: type,
      icon: icon,
      color: color,
    );
    _categories.add(category);
    notifyListeners();
    return category;
  }

  void updateCategory(Category updated) {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _categories[index] = updated;
    notifyListeners();
  }

  DeleteCategoryResult deleteCategory(String id) {
    final inUse = _transactions.any((t) => t.categoryId == id);
    if (inUse) return DeleteCategoryResult.inUse;

    final category = categoryById(id);
    final sameType = categoriesByType(category.type);
    if (sameType.length <= 1) return DeleteCategoryResult.isLastOfType;

    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    return DeleteCategoryResult.success;
  }

  final List<TransactionItem> _transactions = [];

  List<TransactionItem> get transactions {
    final sorted = [..._transactions];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  TransactionItem? transactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TransactionItem> get recentTransactions => transactions.take(5).toList();

  String _newTransactionId() => 'trx-${DateTime.now().microsecondsSinceEpoch}';

  TransactionItem addTransaction({
    required String title,
    required int amount,
    required String categoryId,
    required DateTime date,
    bool isPersonal = false,
    String note = '',
  }) {
    final item = TransactionItem(
      id: _newTransactionId(),
      title: title.trim(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      isPersonal: isPersonal,
      note: note.trim(),
    );
    _transactions.add(item);
    notifyListeners();
    return item;
  }

  void updateTransaction(TransactionItem updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    _transactions[index] = updated;
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  int _signedAmount(TransactionItem t) {
    final isIncome = categoryById(t.categoryId).isIncome;
    return isIncome ? t.amount : -t.amount;
  }

  int get currentBalance {
    final delta = _transactions.fold<int>(0, (sum, t) => sum + _signedAmount(t));
    return startingBalance + delta;
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  int get monthIncome => _transactions
      .where((t) => _isThisMonth(t.date) && categoryById(t.categoryId).isIncome)
      .fold<int>(0, (sum, t) => sum + t.amount);

  int get monthExpense => _transactions
      .where((t) => _isThisMonth(t.date) && !categoryById(t.categoryId).isIncome)
      .fold<int>(0, (sum, t) => sum + t.amount);

  double get _averageDailyBurn {
    final expenseTx = _transactions.where(
      (t) => !categoryById(t.categoryId).isIncome,
    ).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (expenseTx.isEmpty) return 50000;
    final sample = expenseTx.take(30).toList();
    final totalDays = DateTime.now().difference(
      sample.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b),
    ).inDays.clamp(1, 60);
    final totalAmount = sample.fold<int>(0, (sum, t) => sum + t.amount);
    final avg = totalAmount / totalDays;
    return avg < 50000 ? 50000 : avg;
  }

  int get runwayDays => (currentBalance / _averageDailyBurn).clamp(0, 999).round();

  double get runwayProgress =>
      (runwayDays / (runwayThresholdDays * 2)).clamp(0.0, 1.0);

  String get runwayStatusLabel {
    if (runwayDays >= runwayThresholdDays * 1.5) return 'Sehat';
    if (runwayDays >= runwayThresholdDays) return 'Aman';
    return 'Perlu perhatian';
  }

  int get ownerCutSafeAmount {
    final buffer = _averageDailyBurn * runwayThresholdDays;
    final surplus = currentBalance - buffer;
    if (surplus <= 0) return 0;
    return (surplus * ownerCutPercentage).round();
  }

  List<MapEntry<Category, int>> categoryBreakdown(CategoryType type, {bool thisMonthOnly = false}) {
    final totals = <String, int>{};
    for (final t in _transactions) {
      final cat = categoryById(t.categoryId);
      if (cat.type != type) continue;
      if (thisMonthOnly && !_isThisMonth(t.date)) continue;
      totals[cat.id] = (totals[cat.id] ?? 0) + t.amount;
    }
    final entries = totals.entries.map((e) => MapEntry(categoryById(e.key), e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<DateTime, int> netCashflowByDay(int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (int i = days - 1; i >= 0; i--) {
      result[DateTime(now.year, now.month, now.day - i)] = 0;
    }
    for (final t in _transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (result.containsKey(day)) {
        result[day] = result[day]! + _signedAmount(t);
      }
    }
    return result;
  }

  int get personalOutflow => _transactions
      .where((t) => t.isPersonal && !categoryById(t.categoryId).isIncome)
      .fold<int>(0, (sum, t) => sum + t.amount);

  int get businessOutflow => _transactions
      .where((t) => !t.isPersonal && !categoryById(t.categoryId).isIncome)
      .fold<int>(0, (sum, t) => sum + t.amount);

  void _seedCategories() {
    _categories.addAll(const [
      Category(id: 'cat-penjualan-online', name: 'Penjualan Online', type: CategoryType.income, icon: Icons.storefront_outlined, color: Color(0xFF2F7A4D)),
      Category(id: 'cat-jasa-katering', name: 'Jasa Katering', type: CategoryType.income, icon: Icons.ramen_dining_outlined, color: Color(0xFF3D8E5F)),
      Category(id: 'cat-bahan-baku', name: 'Bahan Baku', type: CategoryType.expense, icon: Icons.shopping_basket_outlined, color: Color(0xFFC1533A)),
      Category(id: 'cat-operasional', name: 'Operasional', type: CategoryType.expense, icon: Icons.build_outlined, color: Color(0xFFB0552F)),
      Category(id: 'cat-sewa-utilitas', name: 'Sewa & Utilitas', type: CategoryType.expense, icon: Icons.home_work_outlined, color: Color(0xFF8C4A2F)),
      Category(id: 'cat-owner-cut', name: "Owner's Cut", type: CategoryType.expense, icon: Icons.account_balance_wallet_outlined, color: Color(0xFF185FA5)),
      Category(id: 'cat-lainnya', name: 'Lainnya', type: CategoryType.expense, icon: Icons.category_outlined, color: Color(0xFF6B6558)),
    ]);
  }

  void _seedTransactions() {
    DateTime d(int day) => DateTime(2026, 9, day);
    _transactions.addAll([
      TransactionItem(id: 'trx-1', title: 'Belanja sayur & daging pasar', amount: 450000, categoryId: 'cat-bahan-baku', date: d(1), note: 'Stok mingguan'),
      TransactionItem(id: 'trx-2', title: 'Pesanan nasi kotak PT Sinar Jaya', amount: 1850000, categoryId: 'cat-jasa-katering', date: d(2)),
      TransactionItem(id: 'trx-3', title: 'Penjualan online - Shopee', amount: 320000, categoryId: 'cat-penjualan-online', date: d(2)),
      TransactionItem(id: 'trx-4', title: 'Isi ulang gas & listrik dapur', amount: 275000, categoryId: 'cat-sewa-utilitas', date: d(3)),
      TransactionItem(id: 'trx-5', title: 'Penjualan online - GoFood', amount: 410000, categoryId: 'cat-penjualan-online', date: d(4)),
      TransactionItem(id: 'trx-6', title: 'Beli kemasan & label', amount: 180000, categoryId: 'cat-operasional', date: d(4)),
      TransactionItem(id: 'trx-7', title: 'Katering ulang tahun keluarga Budi', amount: 1200000, categoryId: 'cat-jasa-katering', date: d(5)),
      TransactionItem(id: 'trx-8', title: 'Owner\'s cut - kebutuhan pribadi', amount: 300000, categoryId: 'cat-owner-cut', date: d(6), isPersonal: true),
      TransactionItem(id: 'trx-9', title: 'Belanja bumbu & rempah', amount: 210000, categoryId: 'cat-bahan-baku', date: d(6)),
      TransactionItem(id: 'trx-10', title: 'Penjualan online - Shopee', amount: 275000, categoryId: 'cat-penjualan-online', date: d(7)),
      TransactionItem(id: 'trx-11', title: 'Bayar sewa dapur bulanan', amount: 1500000, categoryId: 'cat-sewa-utilitas', date: d(8)),
      TransactionItem(id: 'trx-12', title: 'Ongkos kirim & bensin antar', amount: 95000, categoryId: 'cat-operasional', date: d(8)),
      TransactionItem(id: 'trx-13', title: 'Penjualan offline - warung', amount: 340000, categoryId: 'cat-penjualan-online', date: d(9)),
      TransactionItem(id: 'trx-14', title: 'Katering rapat kantor Kelurahan', amount: 950000, categoryId: 'cat-jasa-katering', date: d(10)),
      TransactionItem(id: 'trx-15', title: 'Belanja bahan baku mingguan', amount: 520000, categoryId: 'cat-bahan-baku', date: d(11)),
      TransactionItem(id: 'trx-16', title: 'Servis kompor & alat masak', amount: 150000, categoryId: 'cat-operasional', date: d(12)),
      TransactionItem(id: 'trx-17', title: 'Penjualan online - GoFood', amount: 380000, categoryId: 'cat-penjualan-online', date: d(13)),
      TransactionItem(id: 'trx-18', title: 'Owner\'s cut - bayar sekolah anak', amount: 500000, categoryId: 'cat-owner-cut', date: d(14), isPersonal: true),
      TransactionItem(id: 'trx-19', title: 'Katering arisan ibu-ibu RT 04', amount: 675000, categoryId: 'cat-jasa-katering', date: d(14)),
      TransactionItem(id: 'trx-20', title: 'Penjualan offline', amount: 340000, categoryId: 'cat-penjualan-online', date: d(15)),
      TransactionItem(id: 'trx-21', title: 'Belanja bahan baku', amount: 465000, categoryId: 'cat-bahan-baku', date: d(16)),
      TransactionItem(id: 'trx-22', title: 'Bayar internet & listrik', amount: 220000, categoryId: 'cat-sewa-utilitas', date: d(17)),
      TransactionItem(id: 'trx-23', title: 'Penjualan online - Shopee', amount: 295000, categoryId: 'cat-penjualan-online', date: d(18)),
      TransactionItem(id: 'trx-24', title: 'Beli galon & keperluan dapur', amount: 85000, categoryId: 'cat-lainnya', date: d(18)),
      TransactionItem(id: 'trx-25', title: 'Katering pengajian', amount: 800000, categoryId: 'cat-jasa-katering', date: d(19), isPersonal: false),
      TransactionItem(id: 'trx-26', title: 'Belanja bahan baku', amount: 450000, categoryId: 'cat-bahan-baku', date: d(20)),
      TransactionItem(id: 'trx-27', title: 'Penjualan online', amount: 620000, categoryId: 'cat-penjualan-online', date: d(19)),
      TransactionItem(id: 'trx-28', title: "Owner's cut bulan ini", amount: 300000, categoryId: 'cat-owner-cut', date: d(18), isPersonal: true),
      TransactionItem(id: 'trx-29', title: 'Sewa tempat tambahan acara', amount: 1200000, categoryId: 'cat-sewa-utilitas', date: d(15)),
      TransactionItem(id: 'trx-30', title: 'Penjualan offline pasar malam', amount: 540000, categoryId: 'cat-penjualan-online', date: d(21)),
    ]);
  }
}

final AppData appData = AppData();
