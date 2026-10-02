import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/debt_item.dart';
import '../models/insight.dart';
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';
import '../utils/formatters.dart';

enum DeleteCategoryResult { success, inUse, isLastOfType }

enum UpdateCategoryResult { success, notFound, typeInUse }

class AppData extends ChangeNotifier {
  AppData() {
    _seedCategories();
    _seedTransactions();
    _seedDebts();
    _seedGoals();
  }

  int _idCounter = 0;

  /// ID unik: waktu + penghitung, mencegah ID ganda saat data ditambah cepat.
  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  String ownerName = 'Budi';
  String businessName = 'Warung Berkah';
  String businessType = 'Toko Kelontong';
  int runwayThresholdDays = 14;
  double ownerCutPercentage = 0.10;
  int startingBalance = 3500000;
  bool taxEstimateEnabled = true;

  void updateProfile({
    String? ownerName,
    String? businessName,
    String? businessType,
    int? runwayThresholdDays,
    double? ownerCutPercentage,
    int? startingBalance,
    bool? taxEstimateEnabled,
  }) {
    this.ownerName = ownerName ?? this.ownerName;
    this.businessName = businessName ?? this.businessName;
    this.businessType = businessType ?? this.businessType;
    this.runwayThresholdDays =
        runwayThresholdDays ?? this.runwayThresholdDays;
    this.ownerCutPercentage =
        ownerCutPercentage ?? this.ownerCutPercentage;
    this.startingBalance = startingBalance ?? this.startingBalance;
    this.taxEstimateEnabled =
        taxEstimateEnabled ?? this.taxEstimateEnabled;

    notifyListeners();
  }

  /// Mengembalikan seluruh data ke data demo toko kelontong.
  void resetAllData() {
    ownerName = 'Budi';
    businessName = 'Warung Berkah';
    businessType = 'Toko Kelontong';
    runwayThresholdDays = 14;
    ownerCutPercentage = 0.10;
    startingBalance = 3500000;
    taxEstimateEnabled = true;

    _categories.clear();
    _transactions.clear();
    _debts.clear();
    _goals.clear();

    _seedCategories();
    _seedTransactions();
    _seedDebts();
    _seedGoals();

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

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
      (c) =>
          c.id != excludingId &&
          c.name.trim().toLowerCase() == normalized,
    );
  }

  String _newCategoryId() =>
      _newId('cat');

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

  UpdateCategoryResult updateCategory(Category updated) {
    final index =
        _categories.indexWhere((c) => c.id == updated.id);

    if (index == -1) {
      return UpdateCategoryResult.notFound;
    }

    final current = _categories[index];

    final inUse =
        _transactions.any((t) => t.categoryId == updated.id);

    if (inUse && current.type != updated.type) {
      return UpdateCategoryResult.typeInUse;
    }

    _categories[index] = updated;
    notifyListeners();

    return UpdateCategoryResult.success;
  }

  void setCategoryBudget(String categoryId, int? amount) {
    final index =
        _categories.indexWhere((c) => c.id == categoryId);

    if (index == -1) return;

    _categories[index] = _categories[index].copyWith(
      monthlyBudget: amount,
      clearBudget: amount == null,
    );

    notifyListeners();
  }

  DeleteCategoryResult deleteCategory(String id) {
    final inUse =
        _transactions.any((t) => t.categoryId == id);

    if (inUse) {
      return DeleteCategoryResult.inUse;
    }

    final category = categoryById(id);

    final sameType =
        categoriesByType(category.type);

    if (sameType.length <= 1) {
      return DeleteCategoryResult.isLastOfType;
    }

    _categories.removeWhere((c) => c.id == id);

    notifyListeners();

    return DeleteCategoryResult.success;
  }

  /// Mengecek apakah ada data yang memiliki referensi tidak valid.
  List<String> get dataIntegrityIssues {
    final issues = <String>[];

    final categoryIds =
        _categories.map((c) => c.id).toSet();

    for (final t in _transactions) {
      if (!categoryIds.contains(t.categoryId)) {
        issues.add(
          'Transaksi ${t.id} memakai kategori yang tidak ada.',
        );
      }
    }

    for (final g in _goals) {
      if (g.targetAmount <= 0) {
        issues.add(
          'Target ${g.id} memiliki nominal target tidak valid.',
        );
      }

      if (g.currentAmount < 0 ||
          g.currentAmount > g.targetAmount) {
        issues.add(
          'Target ${g.id} memiliki nominal terkumpul di luar batas.',
        );
      }
    }

    for (final d in _debts) {
      if (d.amount <= 0) {
        issues.add(
          'Catatan ${d.id} memiliki nominal tidak valid.',
        );
      }
    }

    return List.unmodifiable(issues);
  }

  // ---------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------

  final List<TransactionItem> _transactions = [];

  List<TransactionItem> get transactions {
    final sorted = [..._transactions];

    sorted.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return List.unmodifiable(sorted);
  }

  TransactionItem? transactionById(String id) {
    try {
      return _transactions.firstWhere(
        (t) => t.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  List<TransactionItem> get recentTransactions =>
      transactions.take(5).toList();

  String _newTransactionId() =>
      _newId('trx');

  TransactionItem addTransaction({
    required String title,
    required int amount,
    required String categoryId,
    required DateTime date,
    bool isPersonal = false,
    String note = '',
  }) {
    final category =
        _categories.where((c) => c.id == categoryId);

    if (category.isEmpty) {
      throw ArgumentError(
        'Kategori transaksi tidak ditemukan: $categoryId',
      );
    }

    if (title.trim().isEmpty || amount <= 0) {
      throw ArgumentError(
        'Transaksi harus memiliki judul dan nominal positif.',
      );
    }

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

  bool updateTransaction(TransactionItem updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return false;
    if (!_categories.any((c) => c.id == updated.categoryId)) return false;
    if (updated.title.trim().isEmpty || updated.amount <= 0) return false;

    _transactions[index] = updated.copyWith(
      title: updated.title.trim(),
      note: updated.note.trim(),
    );
    notifyListeners();
    return true;
  }

  bool deleteTransaction(String id) {
    final before = _transactions.length;
    _transactions.removeWhere((t) => t.id == id);
    final removed = _transactions.length != before;
    if (removed) notifyListeners();
    return removed;
  }

  int _signedAmount(TransactionItem t) {
    final isIncome =
        categoryById(t.categoryId).isIncome;

    return isIncome ? t.amount : -t.amount;
  }

  int get currentBalance {
    final delta = _transactions.fold<int>(
      0,
      (sum, t) => sum + _signedAmount(t),
    );

    return startingBalance + delta;
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month;
  }

  int get monthIncome => _transactions
      .where(
        (t) =>
            _isThisMonth(t.date) &&
            categoryById(t.categoryId).isIncome,
      )
      .fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );

  int get monthExpense => _transactions
      .where(
        (t) =>
            _isThisMonth(t.date) &&
            !categoryById(t.categoryId).isIncome,
      )
      .fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );

  bool _isThisYear(DateTime date) =>
      date.year == DateTime.now().year;

  int get yearIncome => _transactions
      .where(
        (t) =>
            _isThisYear(t.date) &&
            categoryById(t.categoryId).isIncome,
      )
      .fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );

  static const double pphFinalUmkmRate = 0.005;

  static const int pphFinalUmkmExemptThreshold =
      500000000;

  int get estimatedMonthlyTax {
    final incomeBeforeThisMonth =
        yearIncome - monthIncome;

    final remainingExempt =
        (pphFinalUmkmExemptThreshold -
                incomeBeforeThisMonth)
            .clamp(
              0,
              pphFinalUmkmExemptThreshold,
            );

    final taxableThisMonth =
        (monthIncome - remainingExempt)
            .clamp(0, monthIncome);

    return (taxableThisMonth * pphFinalUmkmRate)
        .round();
  }

  int categorySpentThisMonth(String categoryId) =>
      _transactions
          .where(
            (t) =>
                t.categoryId == categoryId &&
                _isThisMonth(t.date),
          )
          .fold<int>(
            0,
            (sum, t) => sum + t.amount,
          );

  double? budgetUsage(String categoryId) {
    final cat = categoryById(categoryId);

    if (!cat.hasBudget) return null;

    return categorySpentThisMonth(categoryId) /
        cat.monthlyBudget!;
  }

  double get averageDailyBurn => _averageDailyBurn;

  double get _averageDailyBurn {
    final expenseTx = _transactions
        .where(
          (t) =>
              !categoryById(t.categoryId).isIncome,
        )
        .toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    if (expenseTx.isEmpty) return 50000;

    final sample =
        expenseTx.take(30).toList();

    final totalDays = DateTime.now()
        .difference(
          sample
              .map((t) => t.date)
              .reduce(
                (a, b) =>
                    a.isBefore(b) ? a : b,
              ),
        )
        .inDays
        .clamp(1, 60);

    final totalAmount = sample.fold<int>(
      0,
      (sum, t) => sum + t.amount,
    );

    final avg =
        totalAmount / totalDays;

    return avg < 50000 ? 50000 : avg;
  }

  int get runwayDays =>
      (currentBalance / _averageDailyBurn)
          .clamp(0, 999)
          .round();

  double get runwayProgress =>
      (runwayDays / (runwayThresholdDays * 2))
          .clamp(0.0, 1.0)
          .toDouble();

  String get runwayStatusLabel {
    if (runwayDays >= runwayThresholdDays * 1.5) {
      return 'Sehat';
    }

    if (runwayDays >= runwayThresholdDays) {
      return 'Aman';
    }

    return 'Perlu perhatian';
  }

  int get ownerCutSafeAmount {
    final buffer =
        _averageDailyBurn * runwayThresholdDays;

    final surplus =
        currentBalance - buffer;

    if (surplus <= 0) return 0;

    return (surplus * ownerCutPercentage)
        .round();
  }

  List<MapEntry<Category, int>> categoryBreakdown(
    CategoryType type, {
    bool thisMonthOnly = false,
  }) {
    final totals = <String, int>{};

    for (final t in _transactions) {
      final cat = categoryById(t.categoryId);

      if (cat.type != type) continue;

      if (thisMonthOnly &&
          !_isThisMonth(t.date)) {
        continue;
      }

      totals[cat.id] =
          (totals[cat.id] ?? 0) + t.amount;
    }

    final entries = totals.entries
        .map(
          (e) => MapEntry(
            categoryById(e.key),
            e.value,
          ),
        )
        .toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return entries;
  }

  Map<DateTime, int> netCashflowByDay(int days) {
    final now = DateTime.now();

    final result = <DateTime, int>{};

    for (int i = days - 1; i >= 0; i--) {
      result[
        DateTime(
          now.year,
          now.month,
          now.day - i,
        )
      ] = 0;
    }

    for (final t in _transactions) {
      final day = DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
      );

      if (result.containsKey(day)) {
        result[day] =
            result[day]! + _signedAmount(t);
      }
    }

    return result;
  }

  int get personalOutflow => _transactions
      .where(
        (t) =>
            t.isPersonal &&
            !categoryById(t.categoryId).isIncome,
      )
      .fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );

  int get businessOutflow => _transactions
      .where(
        (t) =>
            !t.isPersonal &&
            !categoryById(t.categoryId).isIncome,
      )
      .fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );

  // ---------------------------------------------------------------------
  // Utang & Piutang
  // ---------------------------------------------------------------------

  final List<DebtItem> _debts = [];

  List<DebtItem> get debts {
    final sorted = [..._debts];

    sorted.sort((a, b) {
      if (a.isPaid != b.isPaid) {
        return a.isPaid ? 1 : -1;
      }

      return a.dueDate.compareTo(b.dueDate);
    });

    return List.unmodifiable(sorted);
  }

  List<DebtItem> debtsByType(DebtType type) =>
      debts.where((d) => d.type == type).toList();

  List<DebtItem> get overdueDebts =>
      _debts.where((d) => d.isOverdue).toList();

  int get totalReceivable => _debts
      .where(
        (d) =>
            d.isReceivable &&
            !d.isPaid,
      )
      .fold<int>(
        0,
        (sum, d) => sum + d.amount,
      );

  int get totalPayable => _debts
      .where(
        (d) =>
            !d.isReceivable &&
            !d.isPaid,
      )
      .fold<int>(
        0,
        (sum, d) => sum + d.amount,
      );

  String _newDebtId() =>
      _newId('debt');

  DebtItem addDebt({
    required DebtType type,
    required String partyName,
    required int amount,
    required DateTime dueDate,
    String note = '',
  }) {
    if (partyName.trim().isEmpty || amount <= 0) {
      throw ArgumentError('Nama pihak dan nominal harus valid.');
    }

    final item = DebtItem(
      id: _newDebtId(),
      type: type,
      partyName: partyName.trim(),
      amount: amount,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      note: note.trim(),
    );

    _debts.add(item);
    notifyListeners();

    return item;
  }

  bool updateDebt(DebtItem updated) {
    final index = _debts.indexWhere((d) => d.id == updated.id);
    if (index == -1) return false;
    if (updated.partyName.trim().isEmpty || updated.amount <= 0) return false;

    _debts[index] = updated.copyWith(
      partyName: updated.partyName.trim(),
      note: updated.note.trim(),
    );
    notifyListeners();
    return true;
  }

  void toggleDebtPaid(String id) {
    final index =
        _debts.indexWhere(
          (d) => d.id == id,
        );

    if (index == -1) return;

    _debts[index] =
        _debts[index].copyWith(
          isPaid: !_debts[index].isPaid,
        );

    notifyListeners();
  }

  bool deleteDebt(String id) {
    final before = _debts.length;

    _debts.removeWhere(
      (d) => d.id == id,
    );

    final removed =
        _debts.length != before;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  // ---------------------------------------------------------------------
  // Target Menabung
  // ---------------------------------------------------------------------

  final List<SavingsGoal> _goals = [];

  List<SavingsGoal> get goals =>
      List.unmodifiable(_goals);

  String _newGoalId() =>
      _newId('goal');

  SavingsGoal addGoal({
    required String name,
    required int targetAmount,
    required DateTime targetDate,
    required IconData icon,
    required Color color,
    int currentAmount = 0,
  }) {
    if (name.trim().isEmpty || targetAmount <= 0) {
      throw ArgumentError('Nama target dan nominal target harus valid.');
    }

    final goal = SavingsGoal(
      id: _newGoalId(),
      name: name.trim(),
      targetAmount: targetAmount,
      currentAmount: currentAmount.clamp(0, targetAmount).toInt(),
      targetDate: targetDate,
      icon: icon,
      color: color,
    );

    _goals.add(goal);
    notifyListeners();

    return goal;
  }

  void updateGoal(SavingsGoal updated) {
    final index =
        _goals.indexWhere(
          (g) => g.id == updated.id,
        );

    if (index == -1) return;

    if (updated.name.trim().isEmpty ||
        updated.targetAmount <= 0) {
      return;
    }

    final current = updated.currentAmount
        .clamp(0, updated.targetAmount)
        .toInt();

    _goals[index] =
        updated.copyWith(
          currentAmount: current,
        );

    notifyListeners();
  }

  int contributeToGoal(
    String id,
    int amount,
  ) {
    final index =
        _goals.indexWhere(
          (g) => g.id == id,
        );

    if (index == -1 || amount <= 0) {
      return 0;
    }

    final goal = _goals[index];

    final remaining = goal.remaining;

    final applied = amount.clamp(0, remaining).toInt();

    if (applied == 0) return 0;

    _goals[index] =
        goal.copyWith(
          currentAmount:
              goal.currentAmount + applied,
        );

    notifyListeners();

    return applied;
  }

  bool deleteGoal(String id) {
    final before = _goals.length;

    _goals.removeWhere(
      (g) => g.id == id,
    );

    final removed =
        _goals.length != before;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  // ---------------------------------------------------------------------
  // Insights
  // ---------------------------------------------------------------------

  List<Insight> get insights {
    final list = <Insight>[];

    if (runwayDays < runwayThresholdDays) {
      list.add(
        Insight(
          title: 'Kas menipis',
          message:
              'Uang kas diperkirakan hanya cukup untuk '
              '$runwayDays hari lagi, di bawah batas aman '
              '$runwayThresholdDays hari. Coba kurangi '
              'pengeluaran atau tambah pemasukan.',
          icon: Icons.water_drop_outlined,
          level: InsightLevel.critical,
          action: InsightAction.openAnalysis,
        ),
      );
    }

    final overdue = overdueDebts;

    if (overdue.isNotEmpty) {
      final totalOverdue =
          overdue.fold<int>(
        0,
        (sum, d) => sum + d.amount,
      );

      list.add(
        Insight(
          title:
              '${overdue.length} utang/piutang jatuh tempo',
          message:
              'Ada ${overdue.length} catatan yang lewat '
              'tanggal jatuh tempo senilai '
              '${formatRupiahCompact(totalOverdue)}. '
              'Segera tagih atau lunasi supaya arus kas '
              'tetap sehat.',
          icon: Icons.event_busy_outlined,
          level: InsightLevel.warning,
          action: InsightAction.openDebts,
        ),
      );
    }

    for (final cat
        in categoriesByType(CategoryType.expense)) {
      if (!cat.hasBudget) continue;

      final usage =
          budgetUsage(cat.id) ?? 0;

      if (usage >= 1.0) {
        list.add(
          Insight(
            title:
                'Anggaran ${cat.name} kebobolan',
            message:
                'Pengeluaran kategori ini sudah '
                '${(usage * 100).round()}% dari anggaran '
                'bulanan. Coba tinjau lagi pengeluaran '
                'di kategori ini.',
            icon:
                Icons.report_gmailerrorred_outlined,
            level: InsightLevel.critical,
            action:
                InsightAction.openCategories,
          ),
        );
      } else if (usage >= 0.9) {
        list.add(
          Insight(
            title:
                'Anggaran ${cat.name} hampir habis',
            message:
                'Sudah terpakai '
                '${(usage * 100).round()}% dari anggaran '
                'bulanan untuk kategori ini.',
            icon: Icons.speed_outlined,
            level: InsightLevel.warning,
            action:
                InsightAction.openCategories,
          ),
        );
      }
    }

    for (final g in _goals) {
      if (g.isComplete) continue;

      final daysLeft = g.daysLeft;

      if (daysLeft <= 14 &&
          daysLeft >= 0 &&
          g.progress < 0.9) {
        list.add(
          Insight(
            title:
                'Target "${g.name}" mendekati tenggat',
            message:
                'Tinggal $daysLeft hari lagi, baru '
                'terkumpul '
                '${(g.progress * 100).round()}% dari target.',
            icon: Icons.flag_outlined,
            level: InsightLevel.warning,
            action: InsightAction.openGoals,
          ),
        );
      }
    }

    if (list.isEmpty) {
      list.add(
        const Insight(
          title: 'Semua terlihat sehat',
          message:
              'Tidak ada peringatan saat ini. Terus catat '
              'transaksi supaya pantauan tetap akurat.',
          icon: Icons.check_circle_outline,
          level: InsightLevel.info,
        ),
      );
    }

    return list;
  }

  // ---------------------------------------------------------------------
  // Seed / dummy data
  // ---------------------------------------------------------------------

  void _seedCategories() {
    _categories.addAll(
      const [
        Category(
          id: 'cat-penjualan',
          name: 'Penjualan Toko',
          type: CategoryType.income,
          icon: Icons.storefront_outlined,
          color: Color(0xFF2F7A4D),
        ),
        Category(
          id: 'cat-penjualan-hutang',
          name: 'Penjualan Piutang',
          type: CategoryType.income,
          icon: Icons.receipt_long_outlined,
          color: Color(0xFF3D8E5F),
        ),
        Category(
          id: 'cat-stok',
          name: 'Belanja Stok Barang',
          type: CategoryType.expense,
          icon: Icons.shopping_cart_outlined,
          color: Color(0xFFC1533A),
          monthlyBudget: 18000000,
        ),
        Category(
          id: 'cat-operasional',
          name: 'Operasional',
          type: CategoryType.expense,
          icon: Icons.build_outlined,
          color: Color(0xFFB0552F),
          monthlyBudget: 1500000,
        ),
        Category(
          id: 'cat-listrik',
          name: 'Listrik & Air',
          type: CategoryType.expense,
          icon: Icons.bolt_outlined,
          color: Color(0xFF8C4A2F),
          monthlyBudget: 700000,
        ),
        Category(
          id: 'cat-owner-cut',
          name: 'Ambil Pribadi',
          type: CategoryType.expense,
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF185FA5),
        ),
        Category(
          id: 'cat-lainnya',
          name: 'Lainnya',
          type: CategoryType.expense,
          icon: Icons.category_outlined,
          color: Color(0xFF6B6558),
        ),
      ],
    );
  }

  /// Tanggal hari ini (tanpa jam) sebagai acuan data demo, agar data contoh
  /// selalu terlihat "baru" kapan pun aplikasi dibuka.
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _seedTransactions() {
    // Hari ke-30 = hari ini, hari ke-1 = 29 hari lalu.
    DateTime d(int day) => _today.subtract(Duration(days: 30 - day));

    _transactions.addAll(
      [
        TransactionItem(
          id: 'trx-1',
          title: 'Penjualan harian',
          amount: 875000,
          categoryId: 'cat-penjualan',
          date: d(1),
          note:
              'Sembako, minuman, rokok, kebutuhan rumah',
        ),

        TransactionItem(
          id: 'trx-2',
          title: 'Belanja stok grosir',
          amount: 2350000,
          categoryId: 'cat-stok',
          date: d(2),
          note:
              'Beras, minyak, gula, mie instan',
        ),

        TransactionItem(
          id: 'trx-3',
          title: 'Penjualan harian',
          amount: 920000,
          categoryId: 'cat-penjualan',
          date: d(2),
        ),

        TransactionItem(
          id: 'trx-4',
          title: 'Penjualan harian',
          amount: 810000,
          categoryId: 'cat-penjualan',
          date: d(3),
        ),

        TransactionItem(
          id: 'trx-5',
          title: 'Belanja stok minuman',
          amount: 1250000,
          categoryId: 'cat-stok',
          date: d(4),
          note:
              'Air mineral, teh botol, kopi, minuman dingin',
        ),

        TransactionItem(
          id: 'trx-6',
          title: 'Penjualan harian',
          amount: 965000,
          categoryId: 'cat-penjualan',
          date: d(4),
        ),

        TransactionItem(
          id: 'trx-7',
          title: 'Penjualan harian',
          amount: 1080000,
          categoryId: 'cat-penjualan',
          date: d(5),
        ),

        TransactionItem(
          id: 'trx-8',
          title: 'Belanja stok rokok',
          amount: 3200000,
          categoryId: 'cat-stok',
          date: d(6),
          note:
              'Stok rokok berbagai merek',
        ),

        TransactionItem(
          id: 'trx-9',
          title: 'Penjualan harian',
          amount: 1240000,
          categoryId: 'cat-penjualan',
          date: d(6),
        ),

        TransactionItem(
          id: 'trx-10',
          title: 'Penjualan harian',
          amount: 1185000,
          categoryId: 'cat-penjualan',
          date: d(7),
        ),

        TransactionItem(
          id: 'trx-11',
          title: 'Belanja sembako',
          amount: 1850000,
          categoryId: 'cat-stok',
          date: d(8),
          note:
              'Telur, mie, tepung, gula, minyak',
        ),

        TransactionItem(
          id: 'trx-12',
          title: 'Penjualan harian',
          amount: 1320000,
          categoryId: 'cat-penjualan',
          date: d(8),
        ),

        TransactionItem(
          id: 'trx-13',
          title: 'Penjualan harian',
          amount: 990000,
          categoryId: 'cat-penjualan',
          date: d(9),
        ),

        TransactionItem(
          id: 'trx-14',
          title: 'Bayar listrik toko',
          amount: 385000,
          categoryId: 'cat-listrik',
          date: d(10),
          note:
              'Tagihan listrik bulan September',
        ),

        TransactionItem(
          id: 'trx-15',
          title: 'Penjualan harian',
          amount: 1450000,
          categoryId: 'cat-penjualan',
          date: d(10),
        ),

        TransactionItem(
          id: 'trx-16',
          title: 'Belanja stok grosir',
          amount: 2750000,
          categoryId: 'cat-stok',
          date: d(11),
          note:
              'Stok kebutuhan harian',
        ),

        TransactionItem(
          id: 'trx-17',
          title: 'Penjualan harian',
          amount: 1275000,
          categoryId: 'cat-penjualan',
          date: d(11),
        ),

        TransactionItem(
          id: 'trx-18',
          title: 'Penjualan harian',
          amount: 1360000,
          categoryId: 'cat-penjualan',
          date: d(12),
        ),

        TransactionItem(
          id: 'trx-19',
          title: 'Belanja stok telur & mie',
          amount: 1450000,
          categoryId: 'cat-stok',
          date: d(13),
        ),

        TransactionItem(
          id: 'trx-20',
          title: 'Penjualan harian',
          amount: 1520000,
          categoryId: 'cat-penjualan',
          date: d(13),
        ),

        TransactionItem(
          id: 'trx-21',
          title: 'Ambil uang untuk kebutuhan pribadi',
          amount: 500000,
          categoryId: 'cat-owner-cut',
          date: d(14),
          isPersonal: true,
        ),

        TransactionItem(
          id: 'trx-22',
          title: 'Penjualan harian',
          amount: 1390000,
          categoryId: 'cat-penjualan',
          date: d(14),
        ),

        TransactionItem(
          id: 'trx-23',
          title: 'Belanja stok rokok & korek',
          amount: 2850000,
          categoryId: 'cat-stok',
          date: d(15),
        ),

        TransactionItem(
          id: 'trx-24',
          title: 'Penjualan harian',
          amount: 1610000,
          categoryId: 'cat-penjualan',
          date: d(15),
        ),

        TransactionItem(
          id: 'trx-25',
          title: 'Penjualan harian',
          amount: 1475000,
          categoryId: 'cat-penjualan',
          date: d(16),
        ),

        TransactionItem(
          id: 'trx-26',
          title: 'Belanja stok minuman',
          amount: 1650000,
          categoryId: 'cat-stok',
          date: d(17),
          note:
              'Minuman kemasan dan air mineral',
        ),

        TransactionItem(
          id: 'trx-27',
          title: 'Penjualan harian',
          amount: 1580000,
          categoryId: 'cat-penjualan',
          date: d(17),
        ),

        TransactionItem(
          id: 'trx-28',
          title: 'Bayar air & kebersihan toko',
          amount: 180000,
          categoryId: 'cat-listrik',
          date: d(18),
        ),

        TransactionItem(
          id: 'trx-29',
          title: 'Penjualan harian',
          amount: 1695000,
          categoryId: 'cat-penjualan',
          date: d(18),
        ),

        TransactionItem(
          id: 'trx-30',
          title: 'Belanja stok sembako',
          amount: 2250000,
          categoryId: 'cat-stok',
          date: d(19),
          note:
              'Beras, minyak goreng, gula dan tepung',
        ),

        TransactionItem(
          id: 'trx-31',
          title: 'Penjualan harian',
          amount: 1740000,
          categoryId: 'cat-penjualan',
          date: d(19),
        ),

        TransactionItem(
          id: 'trx-32',
          title: 'Penjualan harian',
          amount: 1530000,
          categoryId: 'cat-penjualan',
          date: d(20),
        ),

        TransactionItem(
          id: 'trx-33',
          title: 'Belanja stok grosir',
          amount: 3100000,
          categoryId: 'cat-stok',
          date: d(21),
          note:
              'Restock barang yang cepat habis',
        ),

        TransactionItem(
          id: 'trx-34',
          title: 'Penjualan harian',
          amount: 1825000,
          categoryId: 'cat-penjualan',
          date: d(21),
        ),

        TransactionItem(
          id: 'trx-35',
          title: 'Penjualan harian',
          amount: 1760000,
          categoryId: 'cat-penjualan',
          date: d(22),
        ),

        TransactionItem(
          id: 'trx-36',
          title: 'Belanja stok mie & makanan ringan',
          amount: 1350000,
          categoryId: 'cat-stok',
          date: d(23),
        ),

        TransactionItem(
          id: 'trx-37',
          title: 'Penjualan harian',
          amount: 1680000,
          categoryId: 'cat-penjualan',
          date: d(23),
        ),

        TransactionItem(
          id: 'trx-38',
          title: 'Penjualan harian',
          amount: 1910000,
          categoryId: 'cat-penjualan',
          date: d(24),
        ),

        TransactionItem(
          id: 'trx-39',
          title: 'Biaya transport ambil barang',
          amount: 125000,
          categoryId: 'cat-operasional',
          date: d(25),
          note:
              'Bensin dan ongkos ambil barang grosir',
        ),

        TransactionItem(
          id: 'trx-40',
          title: 'Penjualan harian',
          amount: 1850000,
          categoryId: 'cat-penjualan',
          date: d(25),
        ),

        TransactionItem(
          id: 'trx-41',
          title: 'Belanja stok minuman & es',
          amount: 1750000,
          categoryId: 'cat-stok',
          date: d(26),
        ),

        TransactionItem(
          id: 'trx-42',
          title: 'Penjualan harian',
          amount: 2025000,
          categoryId: 'cat-penjualan',
          date: d(26),
        ),

        TransactionItem(
          id: 'trx-43',
          title: 'Penjualan harian',
          amount: 1940000,
          categoryId: 'cat-penjualan',
          date: d(27),
        ),

        TransactionItem(
          id: 'trx-44',
          title: 'Belanja stok akhir minggu',
          amount: 2450000,
          categoryId: 'cat-stok',
          date: d(28),
          note:
              'Persiapan stok akhir bulan',
        ),

        TransactionItem(
          id: 'trx-45',
          title: 'Penjualan harian',
          amount: 2150000,
          categoryId: 'cat-penjualan',
          date: d(28),
        ),

        TransactionItem(
          id: 'trx-46',
          title: 'Penjualan harian',
          amount: 2075000,
          categoryId: 'cat-penjualan',
          date: d(29),
        ),

        TransactionItem(
          id: 'trx-47',
          title: 'Ambil uang untuk kebutuhan pribadi',
          amount: 350000,
          categoryId: 'cat-owner-cut',
          date: d(29),
          isPersonal: true,
        ),

        TransactionItem(
          id: 'trx-48',
          title: 'Penjualan harian',
          amount: 2280000,
          categoryId: 'cat-penjualan',
          date: d(30),
        ),
      ],
    );
  }

  void _seedDebts() {
    // Hari ke-26 = hari ini; jatuh tempo sebagian besar di depan.
    DateTime d(int day) => _today.add(Duration(days: day - 26));

    _debts.addAll(
      [
        DebtItem(
          id: 'debt-1',
          type: DebtType.payable,
          partyName: 'PT Grosir Makmur',
          amount: 2850000,
          dueDate: d(30),
          createdAt: d(25),
          note:
              'Pembelian stok sembako dan minuman',
        ),

        DebtItem(
          id: 'debt-2',
          type: DebtType.payable,
          partyName: 'Agen Rokok Sejahtera',
          amount: 1750000,
          dueDate: d(29),
          createdAt: d(22),
          note:
              'Stok rokok minggu ini',
        ),

        DebtItem(
          id: 'debt-3',
          type: DebtType.receivable,
          partyName: 'Warung Bu Sari',
          amount: 450000,
          dueDate: d(28),
          createdAt: d(20),
          note:
              'Pembelian barang secara tempo',
        ),

        DebtItem(
          id: 'debt-4',
          type: DebtType.receivable,
          partyName: 'Pak Andi',
          amount: 275000,
          dueDate: d(27),
          createdAt: d(18),
          note:
              'Belanja kebutuhan rumah',
        ),

        DebtItem(
          id: 'debt-5',
          type: DebtType.payable,
          partyName: 'Supplier Minuman Segar',
          amount: 1200000,
          dueDate: d(30),
          createdAt: d(26),
          note:
              'Stok minuman dan air mineral',
        ),

        DebtItem(
          id: 'debt-6',
          type: DebtType.receivable,
          partyName: 'Tetangga Kompleks',
          amount: 180000,
          dueDate: d(24),
          createdAt: d(15),
          isPaid: true,
          note:
              'Belanja kebutuhan rumah',
        ),
      ],
    );
  }

  void _seedGoals() {
    _goals.addAll(
      [
        SavingsGoal(
          id: 'goal-1',
          name: 'Tambah Modal Stok',
          targetAmount: 10000000,
          currentAmount: 6500000,
          targetDate:
              _today.add(const Duration(days: 90)),
          icon: Icons.inventory_2_outlined,
          color: Color(0xFF185FA5),
        ),

        SavingsGoal(
          id: 'goal-2',
          name: 'Dana Darurat Toko',
          targetAmount: 8000000,
          currentAmount: 3500000,
          targetDate:
              _today.add(const Duration(days: 180)),
          icon: Icons.shield_outlined,
          color: Color(0xFF2F7A4D),
        ),

        SavingsGoal(
          id: 'goal-3',
          name: 'Tambah Freezer',
          targetAmount: 6000000,
          currentAmount: 2800000,
          targetDate:
              _today.add(const Duration(days: 120)),
          icon: Icons.kitchen_outlined,
          color: Color(0xFFD97757),
        ),
      ],
    );
  }
}

final AppData appData = AppData();