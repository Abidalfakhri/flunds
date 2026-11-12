import 'package:flutter/material.dart';

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

  bool get isIncome => type == CategoryType.income;

  bool get hasBudget => monthlyBudget != null && monthlyBudget! > 0;
}
