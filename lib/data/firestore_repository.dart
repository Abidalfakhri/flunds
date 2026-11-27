import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/debt_item.dart';
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';

/// Akses Firestore untuk data milik satu user:
///   users/{uid}                 -> profil
///   users/{uid}/categories/{id}
///   users/{uid}/transactions/{id}
///   users/{uid}/debts/{id}
///   users/{uid}/goals/{id}
class FirestoreRepository {
  FirestoreRepository(this.uid);

  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _categories =>
      _userDoc.collection('categories');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _userDoc.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _debts =>
      _userDoc.collection('debts');

  CollectionReference<Map<String, dynamic>> get _goals =>
      _userDoc.collection('goals');

  // ---------- Pantau perubahan (real-time) ----------

  Stream<Map<String, dynamic>?> watchProfile() =>
      _userDoc.snapshots().map((s) => s.data());

  Stream<List<Category>> watchCategories() =>
      _categories.snapshots().map((snap) {
        final list =
            snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList();
        // Pemasukan dulu, lalu urut nama.
        list.sort((a, b) {
          if (a.type != b.type) return a.isIncome ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return list;
      });

  Stream<List<TransactionItem>> watchTransactions() =>
      _transactions.snapshots().map((snap) =>
          snap.docs.map((d) => TransactionItem.fromMap(d.id, d.data())).toList());

  Stream<List<DebtItem>> watchDebts() => _debts.snapshots().map(
      (snap) => snap.docs.map((d) => DebtItem.fromMap(d.id, d.data())).toList());

  Stream<List<SavingsGoal>> watchGoals() => _goals.snapshots().map((snap) =>
      snap.docs.map((d) => SavingsGoal.fromMap(d.id, d.data())).toList());

  // ---------- Kategori ----------

  Future<void> saveCategory(Category c) => _categories.doc(c.id).set(c.toMap());

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  Future<void> saveCategories(List<Category> items) async {
    final batch = _db.batch();
    for (final c in items) {
      batch.set(_categories.doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  /// Tandai bahwa kategori default sudah dibuat untuk akun ini.
  Future<void> markCategoriesSeeded() =>
      _userDoc.set({'categoriesSeeded': true}, SetOptions(merge: true));

  // ---------- Transaksi ----------

  Future<void> saveTransaction(TransactionItem t) =>
      _transactions.doc(t.id).set(t.toMap());

  Future<void> deleteTransaction(String id) =>
      _transactions.doc(id).delete();

  // ---------- Utang / Piutang ----------

  Future<void> saveDebt(DebtItem d) => _debts.doc(d.id).set(d.toMap());

  Future<void> deleteDebt(String id) => _debts.doc(id).delete();

  // ---------- Target tabungan ----------

  Future<void> saveGoal(SavingsGoal g) => _goals.doc(g.id).set(g.toMap());

  Future<void> deleteGoal(String id) => _goals.doc(id).delete();

  // ---------- Hapus data ----------

  /// Hapus semua isi 4 koleksi (profil tetap ada).
  /// Batch Firestore maksimal 500 operasi, jadi dipecah per 400.
  Future<void> clearAll() async {
    for (final col in [_categories, _transactions, _debts, _goals]) {
      final snap = await col.get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }

  /// Hapus semua data user termasuk dokumen profilnya.
  Future<void> deleteUserData() async {
    await clearAll();
    await _userDoc.delete();
  }
}
