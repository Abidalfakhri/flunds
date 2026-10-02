enum DebtType { payable, receivable }

/// A simple utang/piutang (debt/receivable) record so a UMKM owner can track
/// money they owe suppliers (payable) or money customers owe them
/// (receivable), separate from the day-to-day cash transactions.
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
