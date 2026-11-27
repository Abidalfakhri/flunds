import 'package:flutter/material.dart';

import '../ai/ai_context.dart';
import '../ai/ai_service.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';

/// Chat dengan asisten keuangan AI yang membaca data kas pengguna.
class AiAssistantScreen extends StatefulWidget {
  /// Pertanyaan yang langsung dikirim saat layar dibuka (opsional).
  final String? initialQuestion;

  const AiAssistantScreen({super.key, this.initialQuestion});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  static const _suggestions = [
    'Bagaimana kondisi kas saya bulan ini?',
    'Pengeluaran mana yang paling boros?',
    'Apakah aman menarik Owner\'s Cut sekarang?',
    'Bagaimana cara mempercepat target menabung?',
  ];

  // Hanya sebagian riwayat yang dikirim ke AI agar hemat token.
  static const _maxHistory = 12;

  final _messages = <AiMessage>[];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  // Teks jawaban yang sedang mengalir (streaming).
  String? _streaming;

  // Error tidak disimpan di _messages supaya tidak ikut terkirim ke AI
  // sebagai riwayat percakapan.
  String? _error;

  // Penanda permintaan aktif; hasil permintaan lama diabaikan.
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    }
  }

  @override
  void dispose() {
    _runId++; // hentikan stream yang masih berjalan
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(AiMessage(fromUser: true, text: text));
      _controller.clear();
    });
    _run();
  }

  /// Mengirim ulang pertanyaan terakhir setelah error.
  void _retry() {
    if (_loading || _messages.isEmpty || !_messages.last.fromUser) return;
    _run();
  }

  Future<void> _run() async {
    final myRun = ++_runId;

    setState(() {
      _loading = true;
      _error = null;
      _streaming = null;
    });
    _scrollToEnd();

    try {
      final history = _messages.length > _maxHistory
          ? _messages.sublist(_messages.length - _maxHistory)
          : List<AiMessage>.from(_messages);

      // Data dibaca ulang tiap pesan supaya jawaban selalu pakai angka terbaru.
      final stream = AiService.instance.chatStream(
        history: history,
        systemInstruction:
            '$kAssistantSystemPrompt\n\n${buildFinancialContext(appData)}',
      );

      var reply = '';
      await for (final partial in stream) {
        if (!mounted || myRun != _runId) return; // membatalkan stream
        reply = partial;
        setState(() => _streaming = AiService.tidy(partial));
        _scrollToEnd();
      }

      if (!mounted || myRun != _runId) return;
      setState(() {
        _messages.add(AiMessage(fromUser: false, text: AiService.tidy(reply)));
        _streaming = null;
      });
    } on AiException catch (e) {
      if (!mounted || myRun != _runId) return;
      setState(() {
        _error = e.message;
        _streaming = null;
      });
    } catch (_) {
      if (!mounted || myRun != _runId) return;
      setState(() {
        _error = 'Terjadi kendala saat menghubungi AI. Silakan coba lagi.';
        _streaming = null;
      });
    } finally {
      if (mounted && myRun == _runId) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  bool get _hasTail => _loading || _error != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Mulai percakapan baru',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _runId++; // batalkan permintaan yang sedang berjalan
                setState(() {
                  _messages.clear();
                  _streaming = null;
                  _error = null;
                  _loading = false;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _Welcome(onPick: _send, suggestions: _suggestions)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _messages.length + (_hasTail ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i < _messages.length) {
                          return _Bubble(message: _messages[i]);
                        }
                        if (_streaming != null) {
                          return _Bubble(
                            message:
                                AiMessage(fromUser: false, text: _streaming!),
                          );
                        }
                        if (_error != null) {
                          return _ErrorBubble(
                            message: _error!,
                            onRetry: _retry,
                          );
                        }
                        return const _TypingBubble();
                      },
                    ),
            ),
            _InputBar(
              controller: _controller,
              enabled: !_loading,
              onSend: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  const _Welcome({required this.suggestions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: FlundsColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: FlundsColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tanya apa saja soal kasmu',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Jawaban dihitung dari transaksi, utang, dan target menabung yang ada di Flunds.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12.5)),
                      backgroundColor: FlundsColors.surface,
                      side: const BorderSide(color: FlundsColors.surfaceLine),
                      onPressed: () => onPick(s),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AiMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82 > 560
              ? 560
              : MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? FlundsColors.primary : FlundsColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: FlundsColors.surfaceLine),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: isUser ? Colors.white : FlundsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FlundsColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Sedang menganalisis…',
              style: TextStyle(fontSize: 12.5, color: FlundsColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
      decoration: const BoxDecoration(
        color: FlundsColors.surface,
        border: Border(top: BorderSide(color: FlundsColors.surfaceLine)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Tanyakan soal keuangan usahamu…',
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: FlundsColors.accent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Text(
              'Jawaban AI bisa keliru dan bukan nasihat keuangan, pajak, '
              'atau hukum resmi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: FlundsColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}


class _ErrorBubble extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBubble({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: FlundsColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FlundsColors.expense.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: FlundsColors.expense,
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(minimumSize: const Size(0, 36)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
