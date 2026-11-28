import 'package:flutter/material.dart';

import '../ai/ai_context.dart';
import '../ai/ai_service.dart';
import '../ai/local_advisor.dart';
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
  // Hasil AI online disimpan sebentar supaya berpindah tab tidak memanggil
  // AI lagi (hemat kuota dan waktu).
  static String? _cachedText;
  static String? _cachedSig;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 30);

  String? _result;
  String? _note; // alasan memakai mode offline
  bool _loading = false;
  int _runId = 0;

  String get _signature =>
      '${appData.currentBalance}|${appData.monthIncome}|${appData.monthExpense}'
      '|${appData.transactions.length}';

  @override
  void initState() {
    super.initState();
    final at = _cachedAt;
    if (_cachedText != null &&
        _cachedSig == _signature &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      _result = _cachedText;
    }
  }

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
      _note = null;
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

      var last = '';
      await for (final partial in stream) {
        if (!mounted || myRun != _runId) return;
        last = AiService.tidy(partial);
        setState(() => _result = last);
      }
      _cachedText = last;
      _cachedSig = _signature;
      _cachedAt = DateTime.now();
    } on AiException catch (e) {
      _useOffline(myRun, e.message);
    } catch (_) {
      _useOffline(
        myRun,
        'Terjadi kendala saat menghubungi AI. Silakan coba lagi.',
      );
    } finally {
      if (mounted && myRun == _runId) setState(() => _loading = false);
    }
  }

  /// AI online gagal: tampilkan analisis offline dari data perangkat.
  void _useOffline(int myRun, String reason) {
    if (!mounted || myRun != _runId) return;
    setState(() {
      _result = LocalAdvisor.insight(appData);
      _note = reason;
    });
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
                  tooltip: _note != null ? 'Coba AI lagi' : 'Perbarui analisis',
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
                  _StatusText('Sedang menganalisis kasmu…'),
                ],
              ),
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
          if (_note != null && !_loading) ...[
            const SizedBox(height: 8),
            Text(
              '${LocalAdvisor.offlineLabel}: AI online belum bisa dipakai '
              '($_note) Ini ringkasan dari datamu sendiri.',
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: FlundsColors.textMuted,
              ),
            ),
          ],
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
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Buat analisis'),
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


/// Teks yang mengikuti status AiService (mis. "Mencoba Gemini 3.8 Flash…").
class _StatusText extends StatelessWidget {
  final String fallback;

  const _StatusText(this.fallback);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AiService.instance.status,
      builder: (_, value, _) => Text(value ?? fallback),
    );
  }
}
