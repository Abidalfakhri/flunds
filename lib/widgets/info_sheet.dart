import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a short bottom sheet explaining a term in plain language, so
/// first-time or non-technical owners aren't left guessing what a label
/// like "Kas Bisa Bertahan" or "Owner's Cut" actually means.
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
  IconData icon = Icons.info_outline,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FlundsColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: FlundsColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(sheetContext).textTheme.bodyMedium),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Mengerti'),
            ),
          ),
        ],
      ),
    ),
  );
}
