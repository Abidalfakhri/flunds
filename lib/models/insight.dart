import 'package:flutter/material.dart';

enum InsightLevel { info, warning, critical }

/// Where tapping an [Insight] should take the owner. Kept as a plain enum
/// (instead of a stored callback) so [Insight] lists can be computed fresh
/// from AppData without needing a BuildContext.
enum InsightAction { none, openDebts, openGoals, openAnalysis, openCategories }

/// A short, plain-language heads-up computed from the owner's data — e.g. a
/// low cash runway, an overdue debt, or a category close to its budget.
/// Nothing here is stored; it's derived fresh from AppData every time it's
/// read, so it always reflects the current state.
class Insight {
  final String title;
  final String message;
  final IconData icon;
  final InsightLevel level;
  final InsightAction action;

  const Insight({
    required this.title,
    required this.message,
    required this.icon,
    required this.level,
    this.action = InsightAction.none,
  });
}
