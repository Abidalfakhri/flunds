import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_card.dart';
import 'goal_form_screen.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  Future<void> _contribute(BuildContext context, String goalId, String goalName) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Tambah tabungan untuk "$goalName"'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [AmountInputFormatter()],
          decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
              Navigator.pop(dialogContext, n);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      final applied = appData.contributeToGoal(goalId, amount);
      if (!context.mounted) return;
      final message = applied == amount
          ? 'Tabungan ditambahkan ${formatRupiah(applied)}'
          : applied > 0
              ? 'Target hampir/ sudah penuh. Yang ditambahkan ${formatRupiah(applied)}.'
              : 'Target sudah mencapai nominal maksimal.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Target Menabung')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          final goals = appData.goals;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: goals.isEmpty
                  ? const EmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Belum ada target',
                      message: 'Buat target menabung untuk kebutuhan usaha, misalnya alat baru atau dana darurat.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.gridColumns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: goals.length,
                      itemBuilder: (context, i) {
                        final goal = goals[i];
                        return GoalCard(
                          goal: goal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalFormScreen(existing: goal))),
                          onContribute: () => _contribute(context, goal.id, goal.name),
                        );
                      },
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-goals',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalFormScreen())),
        backgroundColor: FlundsColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Target', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
