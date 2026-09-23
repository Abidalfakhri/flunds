import 'package:flutter/material.dart';

class FlundsBottomNav extends StatelessWidget {
  const FlundsBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Center(
        child: Text('FlundsBottomNav (Anggota C)',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}