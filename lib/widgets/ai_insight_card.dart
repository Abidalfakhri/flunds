import 'package:flutter/material.dart';

import '../ai/ai_context.dart';
import '../ai/ai_service.dart';
import '../data/app_data.dart';
import '../screens/ai_assistant_screen.dart';
import '../theme/app_theme.dart';

/// Kartu di dashboard: analisis singkat kondisi kas oleh AI + pintu masuk
/// ke asisten chat.
class AiInsightCard extends StatefulWidget {
  const AiInsightCard({super.key});

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  String? _result;
  String? _error;
  bool _loading = false;
  int _runId = 0;

  @override
  void dispose() {
    _runId++; // hentikan stream yang masih berjalan
    super.dispose();
  }

  Future<void> _generate() async {
    if (_loading) return;
    final myRun = ++_runId;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final stream = AiService.instance.askStream(
        systemInstruction:
            '$kAssistantSystemPrompt\n\n${buildFinancialContext(appData)}',
        prompt:
            'Buat analisis singkat kondisi kas usaha ini bulan ini. Format: '
            '1 kalimat kesimpulan, lalu tepat 3 saran konkret berawalan "- ". '
            'Maksimal 90 kata.',
      );

      await for (final partial in stream) {
        if (!mounted || myRun != _runId) return;
        setState(() => _result = AiService.tidy(partial));
      }
    } on AiException catch (e) {
      if (!mounted || myRun != _runId) return;
      setState(() {
        _error = e.message;
        _result = null;
      });
    } catch (_) {
      if (!mounted || myRun != _runId) return;
      setState(() {
        _error = 'Terjadi kendala saat menghubungi AI. Silakan coba lagi.';
        _result = null;
      });
    } finally {
      if (mounted && myRun == _runId) setState(() => _loading = false);
    }
  }

  void _openChat([String? question]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(initialQuestion: question),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlundsColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: FlundsColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analisis AI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_result != null && !_loading)
                IconButton(
                  tooltip: 'Perbarui analisis',
                  visualDensity: VisualDensity.compact,
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading && _result == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Sedang menganalisis kasmu…'),
                ],
              ),
            )
          else if (_error != null && !_loading)
            Text(
              _error!,
              style: const TextStyle(color: FlundsColors.expense, fontSize: 13),
            )
          else if (_result != null)
            Text(
              _result!,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            )
          else
            Text(
              'Dapatkan kesimpulan dan saran singkat dari kondisi kas bulan ini.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          // Tema app membuat tombol selebar penuh (Size.fromHeight), jadi
          // lebar minimumnya di-nol-kan agar aman ditaruh berdampingan.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_result == null && !_loading)
                ElevatedButton.icon(
                  onPressed: _generate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  icon: Icon(
                    _error != null ? Icons.refresh : Icons.auto_awesome,
                    size: 16,
                  ),
                  label: Text(_error != null ? 'Coba lagi' : 'Buat analisis'),
                ),
              OutlinedButton.icon(
                onPressed: _openChat,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Tanya asisten'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
