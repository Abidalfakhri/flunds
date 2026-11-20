import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItem {
  final String id;
  final String title;
  final int amount;
  final String categoryId;
  final DateTime date;
  final bool isPersonal;
  final String note;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.isPersonal = false,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'categoryId': categoryId,
        'date': Timestamp.fromDate(date),
        'isPersonal': isPersonal,
        'note': note,
      };

  factory TransactionItem.fromMap(String id, Map<String, dynamic> m) {
    return TransactionItem(
      id: id,
      title: (m['title'] as String?) ?? '',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      categoryId: (m['categoryId'] as String?) ?? '',
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPersonal: (m['isPersonal'] as bool?) ?? false,
      note: (m['note'] as String?) ?? '',
    );
  }

  TransactionItem copyWith({
    String? title,
    int? amount,
    String? categoryId,
    DateTime? date,
    bool? isPersonal,
    String? note,
  }) {
    return TransactionItem(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isPersonal: isPersonal ?? this.isPersonal,
      note: note ?? this.note,
    );
  }
}
