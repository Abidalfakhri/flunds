import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;
  const GreetingHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderBox(label: 'GreetingHeader (Anggota C)');
  }
}

class _PlaceholderBox extends StatelessWidget {
  final String label;
  const _PlaceholderBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}