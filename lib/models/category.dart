import 'package:flutter/material.dart';

import '../utils/icon_registry.dart';

enum CategoryType { income, expense }

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;

                                                                           
                                                                         
                                                                        
                                     
  final int? monthlyBudget;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.monthlyBudget,
  });

  Category copyWith({
    String? name,
    CategoryType? type,
    IconData? icon,
    Color? color,
    int? monthlyBudget,
    bool clearBudget = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      monthlyBudget: clearBudget ? null : (monthlyBudget ?? this.monthlyBudget),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.name,
        'icon': iconToKey(icon),
        'color': color.toARGB32(),
        'monthlyBudget': monthlyBudget,
      };

  factory Category.fromMap(String id, Map<String, dynamic> m) {
    return Category(
      id: id,
      name: (m['name'] as String?) ?? '',
      type: (m['type'] as String?) == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      icon: iconFromKey(m['icon'] as String?),
      color: Color((m['color'] as num?)?.toInt() ?? 0xFF6B6558),
      monthlyBudget: (m['monthlyBudget'] as num?)?.toInt(),
    );
  }

  bool get isIncome => type == CategoryType.income;

  bool get hasBudget => monthlyBudget != null && monthlyBudget! > 0;
}
