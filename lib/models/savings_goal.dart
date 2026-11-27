import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/icon_registry.dart';

                                                                        
                                                                            
                                                                       
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

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': Timestamp.fromDate(targetDate),
        'icon': iconToKey(icon),
        'color': color.toARGB32(),
      };

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> m) {
    return SavingsGoal(
      id: id,
      name: (m['name'] as String?) ?? '',
      targetAmount: (m['targetAmount'] as num?)?.toInt() ?? 0,
      currentAmount: (m['currentAmount'] as num?)?.toInt() ?? 0,
      targetDate: (m['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      icon: iconFromKey(m['icon'] as String?, fallback: Icons.flag_outlined),
      color: Color((m['color'] as num?)?.toInt() ?? 0xFF185FA5),
    );
  }

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
