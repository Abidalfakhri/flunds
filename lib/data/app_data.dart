import 'dart:async';

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/debt_item.dart';
import '../models/insight.dart';
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';
import '../utils/formatters.dart';
import 'firestore_repository.dart';

enum DeleteCategoryResult { success, inUse, isLastOfType }

enum UpdateCategoryResult { success, notFound, typeInUse }

class AppData extends ChangeNotifier {
  int _idCounter = 0;

                                                                              
  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  // ---------- Sinkronisasi Firestore (sumber data utama) ----------
  // Semua data user disimpan di Firestore. List di bawah ini hanya salinan
  // (cache) yang selalu diperbarui oleh listener real-time.

  FirestoreRepository? _repo;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _categoriesSeeded = false;

  /// Jalankan operasi Firestore tanpa menunggu hasilnya.
  /// UI tetap cepat; kalau offline, SDK Firestore mengantrekan tulisannya.
  void _sync(Future<void> Function(FirestoreRepository repo) op) {
    final repo = _repo;
    if (repo == null) return;
    op(repo).catchError((Object e) {
      debugPrint('Sinkronisasi Firestore gagal: $e');
    });
  }

  /// Mulai memantau data user dari Firestore (real-time).
  /// Selesai setelah data pertama dari semua koleksi diterima.
  Future<void> startSync(String uid) async {
    await stopSync();
    clearCache();

    final repo = FirestoreRepository(uid);
    _repo = repo;

    final firstData = <Future<void>>[];

    Future<void> listen<T>(Stream<T> stream, void Function(T data) onData) {
      final first = Completer<void>();
      _subs.add(
        stream.listen(
          (data) {
            onData(data);
            notifyListeners();
            if (!first.isCompleted) first.complete();
          },
          onError: (Object e) {
            debugPrint('Listener Firestore error: $e');
            if (!first.isCompleted) first.complete();
          },
        ),
      );
      return first.future;
    }

    firstData.add(listen<Map<String, dynamic>?>(repo.watchProfile(), _applyProfile));
    firstData.add(listen<List<Category>>(repo.watchCategories(), (list) {
      _categories
        ..clear()
        ..addAll(list);
    }));
    firstData.add(listen<List<TransactionItem>>(repo.watchTransactions(), (list) {
      _transactions
        ..clear()
        ..addAll(list);
    }));
    firstData.add(listen<List<DebtItem>>(repo.watchDebts(), (list) {
      _debts
        ..clear()
        ..addAll(list);
    }));
    firstData.add(listen<List<SavingsGoal>>(repo.watchGoals(), (list) {
      _goals
        ..clear()
        ..addAll(list);
    }));

    await Future.wait(firstData).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <void>[],
    );

    // Akun lama yang dibuat sebelum kategori default disimpan ke Firestore.
    if (_repo == repo && !_categoriesSeeded && _categories.isEmpty) {
      _sync((r) async {
        await r.saveCategories(defaultCategories());
        await r.markCategoriesSeeded();
      });
    }
  }

  Future<void> stopSync() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _repo = null;
    _categoriesSeeded = false;
  }

  void _applyProfile(Map<String, dynamic>? data) {
    if (data == null) return;
    ownerName = (data['name'] as String?) ?? ownerName;
    businessName = (data['businessName'] as String?) ?? businessName;
    businessType = (data['businessType'] as String?) ?? businessType;
    startingBalance =
        (data['startingBalance'] as num?)?.toInt() ?? startingBalance;
    runwayThresholdDays =
        (data['runwayThresholdDays'] as num?)?.toInt() ?? runwayThresholdDays;
    ownerCutPercentage =
        (data['ownerCutPercentage'] as num?)?.toDouble() ?? ownerCutPercentage;
    taxEstimateEnabled =
        (data['taxEstimateEnabled'] as bool?) ?? taxEstimateEnabled;
    _categoriesSeeded = data['categoriesSeeded'] == true;
  }

  /// Kosongkan salinan lokal (dipakai saat ganti akun / keluar).
  void clearCache() {
    ownerName = '';
    businessName = '';
    businessType = 'UMKM';
    runwayThresholdDays = 14;
    ownerCutPercentage = 0.10;
    startingBalance = 0;
    taxEstimateEnabled = true;

    _categories.clear();
    _transactions.clear();
    _debts.clear();
    _goals.clear();

    notifyListeners();
  }

  /// Hapus semua transaksi, utang, target tabungan, dan kategori di
  /// Firestore, lalu pulihkan kategori default. Cache ikut berubah lewat listener.
  void resetData() {
    _sync((r) async {
      await r.clearAll();
      await r.saveCategories(defaultCategories());
      await r.markCategoriesSeeded();
    });
  }

  String ownerName = '';
  String businessName = '';
  String businessType = 'UMKM';
  int runwayThresholdDays = 14;
  double ownerCutPercentage = 0.10;
  int startingBalance = 0;
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
    _sync((r) => r.saveCategory(category));
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
    _sync((r) => r.saveCategory(updated));
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

    final saved = _categories[index];
    _sync((r) => r.saveCategory(saved));
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
    _sync((r) => r.deleteCategory(id));

    notifyListeners();

    return DeleteCategoryResult.success;
  }

                                                                   
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
    _sync((r) => r.saveTransaction(item));
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
    final saved = _transactions[index];
    _sync((r) => r.saveTransaction(saved));
    notifyListeners();
    return true;
  }

  bool deleteTransaction(String id) {
    final before = _transactions.length;
    _transactions.removeWhere((t) => t.id == id);
    final removed = _transactions.length != before;
    if (removed) {
      _sync((r) => r.deleteTransaction(id));
      notifyListeners();
    }
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
    _sync((r) => r.saveDebt(item));
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
    final saved = _debts[index];
    _sync((r) => r.saveDebt(saved));
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

    final saved = _debts[index];
    _sync((r) => r.saveDebt(saved));
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
      _sync((r) => r.deleteDebt(id));
      notifyListeners();
    }

    return removed;
  }

                                                                          
                    
                                                                          

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
    _sync((r) => r.saveGoal(goal));
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

    final saved = _goals[index];
    _sync((r) => r.saveGoal(saved));
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

    final saved = _goals[index];
    _sync((r) => r.saveGoal(saved));
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
      _sync((r) => r.deleteGoal(id));
      notifyListeners();
    }

    return removed;
  }

                                                                          
             
                                                                          

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

                                                                          
                      
                                                                          

  static const List<Category> _defaultCategoryTemplates = [
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
        ),
        Category(
          id: 'cat-operasional',
          name: 'Operasional',
          type: CategoryType.expense,
          icon: Icons.build_outlined,
          color: Color(0xFFB0552F),
        ),
        Category(
          id: 'cat-listrik',
          name: 'Listrik & Air',
          type: CategoryType.expense,
          icon: Icons.bolt_outlined,
          color: Color(0xFF8C4A2F),
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
  ];

  /// Kategori awal untuk akun baru (tanpa budget).
  static List<Category> defaultCategories() => [
        for (final c in _defaultCategoryTemplates) c.copyWith(clearBudget: true),
      ];
}

final AppData appData = AppData();
