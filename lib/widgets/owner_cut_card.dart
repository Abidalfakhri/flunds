import 'package:flutter/material.dart';

class OwnerCutCard extends StatelessWidget {
  final String safeAmount;
  const OwnerCutCard({super.key, required this.safeAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text("OwnerCutCard (Anggota B)",
          style: TextStyle(color: Colors.grey)),
    );
  }
}