import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/scenario_card.dart';

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
  final _nominalController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  final int _runwaySaatIni = 45;
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
    final nominal = int.tryParse(_nominalController.text) ?? 0;
    final estimasiHariBerkurang = (nominal / 100000).round();
    final runwaySesudah = (_runwaySaatIni - estimasiHariBerkurang).clamp(0, 999);
    setState(() {
      _skenario.insert(0, _ScenarioData('Rencana Rp$nominal pada ${_tanggal.day}/${_tanggal.month}', _runwaySaatIni, runwaySesudah));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi What If')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal rencana pengeluaran', prefixText: 'Rp ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pilihTanggal,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('${_tanggal.day}/${_tanggal.month}/${_tanggal.year}'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _jalankanSimulasi,
              style: ElevatedButton.styleFrom(backgroundColor: FlundsColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
              child: const Text('Jalankan Simulasi'),
            ),
            const SizedBox(height: 20),
            const Text('Perbandingan Skenario', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: _skenario.isEmpty
                  ? const Center(child: Text('Belum ada skenario', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: _skenario.map((s) => ScenarioCard(label: s.label, runwayBefore: s.runwayBefore, runwayAfter: s.runwayAfter)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
