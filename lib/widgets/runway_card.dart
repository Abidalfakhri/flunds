import 'package:flutter/material.dart';

class RunwayCard extends StatelessWidget {
  final int runwayDays;
  final int thresholdDays;
  final double progress;
  final String statusLabel;

  const RunwayCard({
    super.key,
    required this.runwayDays,
    required this.thresholdDays,
    required this.progress,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _PlaceholderBox(label: 'RunwayCard (Anggota B)');
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
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}