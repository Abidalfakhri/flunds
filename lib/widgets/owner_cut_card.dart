import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OwnerCutCard extends StatelessWidget {
  final String safeAmount;
  const OwnerCutCard({super.key, required this.safeAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FlundsColors.ownerCutBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Smart owner's cut",
                    style: TextStyle(
                        fontSize: 12, color: FlundsColors.ownerCutText)),
                const SizedBox(height: 4),
                Text('Aman tarik $safeAmount',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: FlundsColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tarik dana'),
          ),
        ],
      ),
    );
  }
}