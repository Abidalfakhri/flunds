import 'package:flutter/material.dart';

/// A savings target the owner is working toward (e.g. new equipment, an
/// emergency fund), tracked separately from the main cash balance so saving
/// up for something doesn't get mixed up with the day-to-day cashflow.
class SavingsGoal {
  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime targetDate;
  final IconData icon;
  final Color color;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.icon,
    required this.color,
  });

  double get progress =>
      targetAmount <= 0 ? 0.0 : (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();

  bool get isComplete => currentAmount >= targetAmount;

  int get remaining => (targetAmount - currentAmount).clamp(0, targetAmount).toInt();

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  SavingsGoal copyWith({
    String? name,
    int? targetAmount,
    int? currentAmount,
    DateTime? targetDate,
    IconData? icon,
    Color? color,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
