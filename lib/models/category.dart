import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  Category copyWith({
    String? name,
    CategoryType? type,
    IconData? icon,
    Color? color,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  bool get isIncome => type == CategoryType.income;
}
