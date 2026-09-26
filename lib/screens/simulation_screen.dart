import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/scenario_card.dart';
import '../widgets/empty_state.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _ScenarioData {
  final String label;
  final int runwayBefore;
  final int runwayAfter;
  const _ScenarioData(this.label, this.runwayBefore, this.runwayAfter);
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _nominalController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  final List<_ScenarioData> _skenario = [];

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  void _jalankanSimulasi() {
    if (!_formKey.currentState!.validate()) return;
    final nominal = int.parse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final runwaySaatIni = appData.runwayDays;
    final estimasiSaldoBaru = appData.currentBalance - nominal;
    final estimasiHariBerkurang = (nominal / 100000).round();
    final runwaySesudah = (runwaySaatIni - estimasiHariBerkurang).clamp(0, 999);
    final label = _titleController.text.trim().isEmpty
        ? 'Rencana ${formatRupiahCompact(nominal)} pada ${_tanggal.day}/${_tanggal.month}'
        : '${_titleController.text.trim()} (${formatRupiahCompact(nominal)})';

    setState(() {
      _skenario.insert(0, _ScenarioData(label, runwaySaatIni, runwaySesudah));
      _titleController.clear();
      _nominalController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulasi dijalankan — estimasi saldo jadi ${formatRupiahCompact(estimasiSaldoBaru)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi What-If')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: context.isExpanded
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildForm(context)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildScenarioList(context)),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildForm(context),
                          const SizedBox(height: 20),
                          _buildScenarioList(context),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FlundsColors.primarySoft, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Runway saat ini: ${appData.runwayDays} hari · Saldo: ${formatRupiahCompact(appData.currentBalance)}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: FlundsColors.primaryDark),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Nama rencana (opsional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal rencana pengeluaran', prefixText: 'Rp '),
            validator: (v) {
              final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
              if (n == null || n <= 0) return 'Masukkan nominal yang valid';
              return null;
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text('${_tanggal.day}/${_tanggal.month}/${_tanggal.year}'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _jalankanSimulasi, child: const Text('Jalankan Simulasi')),
        ],
      ),
    );
  }

  Widget _buildScenarioList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perbandingan Skenario', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _skenario.isEmpty
            ? const EmptyState(
                icon: Icons.insights_outlined,
                title: 'Belum ada skenario',
                message: 'Isi form di samping/atas lalu jalankan simulasi untuk melihat dampaknya.',
              )
            : Column(
                children: _skenario
                    .map((s) => ScenarioCard(label: s.label, runwayBefore: s.runwayBefore, runwayAfter: s.runwayAfter))
                    .toList(),
              ),
      ],
    );
  }
}
