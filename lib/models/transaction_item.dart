class TransactionItem {
  final String title;
  final String amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  final bool isPersonal;

  const TransactionItem({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    required this.isPersonal,
  });
}
