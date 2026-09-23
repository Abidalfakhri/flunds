import 'package:flutter/material.dart';

class FlundsColors {
  static const primary = Color(0xFF0F6E56);
  static const runwayBg = Color(0xFFE1F5EE);
  static const ownerCutBg = Color(0xFFE6F1FB);
  static const ownerCutText = Color(0xFF185FA5);
  static const income = Color(0xFF3B6D11);
  static const expense = Color(0xFF993C1D);
  static const scaffoldBg = Color(0xFFF4F5F2);
}

class FlundsTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: FlundsColors.primary,
      scaffoldBackgroundColor: FlundsColors.scaffoldBg,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: FlundsColors.primary),
    );
  }
}