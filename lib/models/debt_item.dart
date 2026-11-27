import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtType { payable, receivable }

                                                                             
                                                                  
                                                                 
class DebtItem {
  final String id;
  final DebtType type;
  final String partyName;
  final int amount;
  final DateTime dueDate;
  final DateTime createdAt;
  final bool isPaid;
  final String note;

  const DebtItem({
    required this.id,
    required this.type,
    required this.partyName,
    required this.amount,
    required this.dueDate,
    required this.createdAt,
    this.isPaid = false,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'partyName': partyName,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'isPaid': isPaid,
        'note': note,
      };

  factory DebtItem.fromMap(String id, Map<String, dynamic> m) {
    return DebtItem(
      id: id,
      type: (m['type'] as String?) == 'receivable'
          ? DebtType.receivable
          : DebtType.payable,
      partyName: (m['partyName'] as String?) ?? '',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      dueDate: (m['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: (m['isPaid'] as bool?) ?? false,
      note: (m['note'] as String?) ?? '',
    );
  }

  bool get isReceivable => type == DebtType.receivable;

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.isBefore(today);
  }

  DebtItem copyWith({
    DebtType? type,
    String? partyName,
    int? amount,
    DateTime? dueDate,
    bool? isPaid,
    String? note,
  }) {
    return DebtItem(
      id: id,
      type: type ?? this.type,
      partyName: partyName ?? this.partyName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      isPaid: isPaid ?? this.isPaid,
      note: note ?? this.note,
    );
  }
}
