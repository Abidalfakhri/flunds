import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const FlundsApp());
}

class FlundsApp extends StatelessWidget {
  const FlundsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flunds',
      debugShowCheckedModeBanner: false,
      theme: FlundsTheme.light,
      home: const DashboardScreen(),
    );
  }
}