import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'app_check_setup.dart';

/// Error yang aman ditampilkan kepada pengguna.
class AiException implements Exception {
  final String message;

  const AiException(this.message);

  @override
  String toString() => message;
}

/// Satu pesan dalam percakapan AI.
class AiMessage {
  final bool fromUser;
  final String text;

  const AiMessage({
    required this.fromUser,
    required this.text,
  });
}

/// Jenis kegagalan, menentukan apa yang dilakukan selanjutnya.
enum _Kind {
  timeout, // model terlalu lama -> coba model berikutnya
  transient, // 5xx / sibuk -> retry sekali, lalu model berikutnya
  quota, // kuota model ini habis -> model berikutnya (kuota terpisah)
  modelGone, // 404 / model dimatikan -> model berikutnya
  badRequest, // 400 (mis. level thinking ditolak) -> model berikutnya
  offline, // tidak ada internet -> berhenti
  appCheck, // App Check menolak -> berhenti
  region, // wilayah tidak didukung -> berhenti
  denied, // 403 / API belum aktif -> berhenti
  blocked, // diblokir filter keamanan -> berhenti
}

bool _isFatal(_Kind k) =>
    k == _Kind.offline ||
    k == _Kind.appCheck ||
    k == _Kind.region ||
    k == _Kind.denied ||
    k == _Kind.blocked;

class _EmptyAnswer implements Exception {
  const _EmptyAnswer();
}

class _ModelSpec {
  final String name;
  final String label;
  final ThinkingLevel? thinking;
  final Duration firstChunkTimeout;

  _ModelSpec(this.name, this.label, this.thinking, this.firstChunkTimeout);
}

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  static const String _modelOverride = String.fromEnvironment('AI_MODEL');

  static final List<_ModelSpec> _chain = [
    if (_modelOverride.isNotEmpty)
      _ModelSpec(_modelOverride, _modelOverride, ThinkingLevel.low,
          const Duration(seconds: 15)),
    _ModelSpec('gemini-3.5-flash-lite', 'Gemini 3.5 Flash-Lite', null,
        const Duration(seconds: 12)),
    _ModelSpec('gemini-3.8-flash', 'Gemini 3.8 Flash', ThinkingLevel.low,
        const Duration(seconds: 18)),
    _ModelSpec('gemini-4-hydrogen', 'Gemini 4 Hydrogen', ThinkingLevel.low,
        const Duration(seconds: 20)),
  ];


  static const Duration _idleTimeout = Duration(seconds: 15);


  static const Duration _totalBudget = Duration(seconds: 55);


  static const int _maxOutputTokens = 4096;

  final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  String? lastModelLabel;

  Stream<String> chatStream({
    required List<AiMessage> history,
    required String systemInstruction,
  }) async* {
    if (history.isEmpty) {
      throw const AiException(
        'Percakapan masih kosong. Silakan masukkan pertanyaan.',
      );
    }
    if (!history.last.fromUser) {
      throw const AiException('Pesan terakhir harus berasal dari pengguna.');
    }
    if (history.any((m) => m.text.trim().isEmpty)) {
      throw const AiException('Ada pesan kosong dalam percakapan.');
    }

    // Riwayat harus diawali pesan pengguna.
    final start = history.indexWhere((m) => m.fromUser);
    final trimmed = history.sublist(start);

    final contents = <Content>[
      for (final m in trimmed)
        Content(m.fromUser ? 'user' : 'model', [TextPart(m.text)]),
    ];

    yield* _generateStream(
      systemInstruction: systemInstruction,
      contents: contents,
    );
  }

  /// Satu pertanyaan tanpa riwayat, dengan streaming.
  Stream<String> askStream({
    required String prompt,
    required String systemInstruction,
  }) {
    if (prompt.trim().isEmpty) {
      throw const AiException('Pertanyaan tidak boleh kosong.');
    }
    return chatStream(
      history: [AiMessage(fromUser: true, text: prompt)],
      systemInstruction: systemInstruction,
    );
  }

  /// Versi non-streaming: mengembalikan jawaban utuh.
  Future<String> chat({
    required List<AiMessage> history,
    required String systemInstruction,
  }) {
    return _collect(
      chatStream(history: history, systemInstruction: systemInstruction),
    );
  }

  Future<String> ask({
    required String prompt,
    required String systemInstruction,
  }) {
    return _collect(
      askStream(prompt: prompt, systemInstruction: systemInstruction),
    );
  }

  /// Meminta AI menghasilkan JSON dan mengembalikan Map.
  Future<Map<String, dynamic>> askJson({
    required String prompt,
    required String systemInstruction,
  }) async {
    if (prompt.trim().isEmpty) {
      throw const AiException('Permintaan AI tidak boleh kosong.');
    }
    final raw = await _collect(
      _generateStream(
        systemInstruction: systemInstruction,
        contents: [
          Content('user', [TextPart(prompt)]),
        ],
        json: true,
      ),
    );
    return _parseJson(raw);
  }

  /// Model kadang masih menulis markdown walau dilarang di prompt. Teks di
  /// UI ditampilkan polos, jadi simbol markdown dirapikan.
  static String tidy(String raw) {
    var s = raw.replaceAll(RegExp(r'\*\*|__'), '');
    s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    s = s.replaceAll('`', '');
    s = s.replaceAllMapped(
      RegExp(r'^(\s*)[*•]\s+', multiLine: true),
      (m) => '${m[1]}- ',
    );
    return s.trim();
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  Future<String> _collect(Stream<String> stream) async {
    var last = '';
    await for (final text in stream) {
      last = text;
    }
    return last;
  }

  GenerativeModel _buildModel(
    _ModelSpec spec,
    String systemInstruction,
    bool json,
  ) {
    final level = spec.thinking;
    return FirebaseAI.googleAI().generativeModel(
      model: spec.name,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        maxOutputTokens: _maxOutputTokens,
        responseMimeType: json ? 'application/json' : null,
        thinkingConfig:
            level == null ? null : ThinkingConfig.withThinkingLevel(level),
      ),
    );
  }

  /// Satu permintaan streaming ke satu model, dengan timeout per-chunk.
  Stream<String> _streamOnce(
    _ModelSpec spec,
    String systemInstruction,
    List<Content> contents,
    bool json,
  ) async* {
    final stopwatch = Stopwatch()..start();
    final model = _buildModel(spec, systemInstruction, json);
    final iterator = StreamIterator(model.generateContentStream(contents));
    final buffer = StringBuffer();
    var first = true;

    try {
      while (true) {
        bool hasNext;
        try {
          hasNext = await iterator
              .moveNext()
              .timeout(first ? spec.firstChunkTimeout : _idleTimeout);
        } on TimeoutException {
          if (first) rethrow;
          // Teks sudah mulai tampil lalu macet: tampilkan apa yang ada
          // daripada membuang jawaban setengah jadi.
          debugPrint('[AI] ${spec.name} macet di tengah jawaban, '
              'memakai teks yang sudah ada.');
          break;
        }
        if (!hasNext) break;

        if (first) {
          debugPrint('[AI] ${spec.name}: chunk pertama setelah '
              '${stopwatch.elapsedMilliseconds} ms.');
          first = false;
        }

        final text = iterator.current.text;
        if (text == null || text.isEmpty) continue;

        buffer.write(text);
        yield buffer.toString();
      }
    } finally {
      // Tidak di-await: jika koneksi macet, cancel() tidak boleh ikut
      // menahan error timeout.
      unawaited(iterator.cancel().catchError((_) {}));
    }

    debugPrint('[AI] ${spec.name}: selesai dalam '
        '${stopwatch.elapsedMilliseconds} ms.');

    if (buffer.toString().trim().isEmpty) {
      throw const _EmptyAnswer();
    }
  }

  /// Streaming dengan rantai model cadangan. Pindah model hanya dilakukan
  /// selama belum ada teks yang sampai ke pengguna.
  Stream<String> _generateStream({
    required String systemInstruction,
    required List<Content> contents,
    bool json = false,
  }) async* {
    final total = Stopwatch()..start();
    var lastKind = _Kind.transient;

    try {
      for (var i = 0; i < _chain.length; i++) {
        final spec = _chain[i];
        if (i > 0 && total.elapsed > _totalBudget) break;

        status.value = i == 0 ? null : 'Mencoba ${spec.label}…';

        for (var attempt = 1; attempt <= 2; attempt++) {
          var received = false;
          try {
            await for (final text
                in _streamOnce(spec, systemInstruction, contents, json)) {
              received = true;
              yield text;
            }
            lastModelLabel = spec.label;
            return;
          } catch (e) {
            final kind = _classify(e);
            debugPrint('[AI] ${spec.name} gagal '
                '(percobaan $attempt, $kind): ${_rawMessage(e)}');

            if (received || _isFatal(kind)) {
              throw AiException(await _messageFor(kind));
            }

            lastKind = kind;
            if (kind == _Kind.transient && attempt == 1) {
              await Future.delayed(const Duration(milliseconds: 800));
              continue; // coba model yang sama sekali lagi
            }
            break; // pindah ke model berikutnya
          }
        }
      }

      throw AiException(await _messageFor(lastKind));
    } finally {
      status.value = null;
    }
  }

  Map<String, dynamic> _parseJson(String raw) {
    var cleaned = raw.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r'^```(?:json)?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end > start) {
      try {
        final decoded = jsonDecode(cleaned.substring(start, end + 1));
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    throw const AiException(
      'AI memberikan jawaban dengan format yang tidak valid. '
      'Silakan coba lagi.',
    );
  }


  // KLASIFIKASI ERROR
 

  String _rawMessage(Object e) {
    if (e is FirebaseAIException) return e.message;
    return e.toString();
  }

  _Kind _classify(Object e) {
    if (e is TimeoutException) return _Kind.timeout;
    if (e is _EmptyAnswer) return _Kind.transient;

    final m = _rawMessage(e).toLowerCase();

    if (m.contains('failed host lookup') ||
        m.contains('network is unreachable') ||
        m.contains('no address associated')) {
      return _Kind.offline;
    }
    if (m.contains('app check') ||
        m.contains('app-check') ||
        m.contains('appcheck') ||
        m.contains('attestation')) {
      return _Kind.appCheck;
    }
    if (m.contains('location') && m.contains('not supported')) {
      return _Kind.region;
    }
    if (m.contains('quota') ||
        m.contains('resource_exhausted') ||
        m.contains('daily limit') ||
        m.contains('limit exceeded') ||
        m.contains('429') ||
        m.contains('rate limit') ||
        m.contains('too many requests')) {
      return _Kind.quota;
    }
    if (m.contains('404') ||
        m.contains('not found') ||
        m.contains('no longer available') ||
        m.contains('shut down')) {
      return _Kind.modelGone;
    }
    if (m.contains('403') ||
        m.contains('permission denied') ||
        m.contains('api key') ||
        m.contains('not authorized') ||
        m.contains('has not been used') ||
        m.contains('api not enabled') ||
        m.contains('disabled')) {
      return _Kind.denied;
    }
    if (m.contains('400') ||
        m.contains('invalid_argument') ||
        m.contains('bad request')) {
      return _Kind.badRequest;
    }
    if (m.contains('safety') || m.contains('blocked')) {
      return _Kind.blocked;
    }
    // 5xx, unavailable, overloaded, error tak dikenal: perlakukan sementara.
    return _Kind.transient;
  }

  Future<String> _messageFor(_Kind kind) async {
    switch (kind) {
      case _Kind.timeout:
        final hint = kDebugMode ? '\n[debug] ${await probeAppCheck()}' : '';
        return 'AI belum merespons setelah mencoba beberapa model. '
            'Periksa koneksi internet lalu coba lagi.$hint';
      case _Kind.transient:
        return 'Server AI sedang sibuk. Silakan coba lagi beberapa saat.';
      case _Kind.quota:
        return 'Layanan AI sedang mencapai batas penggunaan. '
            'Silakan coba lagi nanti.';
      case _Kind.modelGone:
        return 'Model AI tidak tersedia. Perbarui aplikasi atau periksa '
            'nama model di konfigurasi.';
      case _Kind.badRequest:
        return 'Permintaan AI tidak dapat diproses. Silakan coba lagi.';
      case _Kind.offline:
        return 'Tidak dapat terhubung ke internet. '
            'Periksa koneksi lalu coba lagi.';
      case _Kind.appCheck:
        if (kDebugMode) {
          return 'App Check menolak token (HTTP 403). Pastikan debug token '
              'di lib/ai/app_check_setup.dart sudah didaftarkan di '
              'Firebase Console > App Check > Manage debug tokens.';
        }
        return 'Verifikasi keamanan aplikasi gagal. '
            'Pastikan aplikasi dipasang dari sumber resmi lalu coba lagi.';
      case _Kind.region:
        return 'Fitur AI belum tersedia di wilayah Anda.';
      case _Kind.denied:
        return 'Akses ke layanan AI ditolak. Pastikan Firebase AI Logic '
            '(Gemini Developer API) sudah diaktifkan di Firebase Console.';
      case _Kind.blocked:
        return 'Pertanyaan ini tidak dapat dijawab oleh AI. '
            'Coba ubah kalimatnya.';
    }
  }
}
