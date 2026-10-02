import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'info_sheet.dart';

class OwnerCutCard extends StatelessWidget {
  final String safeAmount;
  final VoidCallback? onWithdrawPressed;

  const OwnerCutCard({super.key, required this.safeAmount, this.onWithdrawPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlundsColors.ownerCutBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;

          final details = Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined, color: FlundsColors.ownerCutText, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => showInfoSheet(
                        context,
                        icon: Icons.savings_outlined,
                        title: "Apa itu Owner's Cut?",
                        body:
                            "Owner's Cut adalah jumlah uang yang aman kamu ambil dari kas usaha sebagai \"gaji\" pemilik, tanpa mengganggu uang operasional dan tanpa membuat kas usaha cepat habis. Flunds menghitungnya otomatis dari saldo kas dan kebiasaan pengeluaranmu.",
                      ),
                      child: Text(
                        "Gaji Pemilik (Owner's Cut)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: FlundsColors.ownerCutText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Aman ditarik $safeAmount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onWithdrawPressed,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
                  child: const Text('Tarik'),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onWithdrawPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Tarik'),
              ),
            ],
          );
        },
      ),
    );
  }
}

