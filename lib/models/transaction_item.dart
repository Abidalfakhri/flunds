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
