import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/debt_item.dart';
import '../models/transaction_item.dart';

/// Akses Firestore untuk data milik satu user:
///   users/{uid}/categories/{id}
///   users/{uid}/transactions/{id}
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

  // ---------- Kategori ----------

  Future<List<Category>> loadCategories() async {
    final snap = await _categories.get();
    final list =
        snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList();
    // Pemasukan dulu, lalu urut nama.
    list.sort((a, b) {
      if (a.type != b.type) return a.isIncome ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> saveCategory(Category c) => _categories.doc(c.id).set(c.toMap());

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  Future<void> saveCategories(List<Category> items) async {
    final batch = _db.batch();
    for (final c in items) {
      batch.set(_categories.doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  // ---------- Transaksi ----------

  Future<List<TransactionItem>> loadTransactions() async {
    final snap = await _transactions.get();
    return snap.docs
        .map((d) => TransactionItem.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> saveTransaction(TransactionItem t) =>
      _transactions.doc(t.id).set(t.toMap());

  Future<void> deleteTransaction(String id) =>
      _transactions.doc(id).delete();

  /// Batch Firestore maksimal 500 operasi, jadi dipecah per 400.
  Future<void> saveTransactions(List<TransactionItem> items) async {
    for (var i = 0; i < items.length; i += 400) {
      final batch = _db.batch();
      for (final t in items.skip(i).take(400)) {
        batch.set(_transactions.doc(t.id), t.toMap());
      }
      await batch.commit();
    }
  }

  // ---------- Utang / Piutang ----------

  CollectionReference<Map<String, dynamic>> get _debts =>
      _userDoc.collection('debts');

  Future<List<DebtItem>> loadDebts() async {
    final snap = await _debts.get();
    return snap.docs.map((d) => DebtItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> saveDebt(DebtItem d) => _debts.doc(d.id).set(d.toMap());

  Future<void> deleteDebt(String id) => _debts.doc(id).delete();

  Future<void> saveDebts(List<DebtItem> items) async {
    for (var i = 0; i < items.length; i += 400) {
      final batch = _db.batch();
      for (final d in items.skip(i).take(400)) {
        batch.set(_debts.doc(d.id), d.toMap());
      }
      await batch.commit();
    }
  }

  // ---------- Reset ----------

  Future<void> clearAll() async {
    for (final col in [_categories, _transactions, _debts]) {
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
}
