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

/// Firebase AI Logic (Gemini Developer API).
///
/// Perbedaan utama dari versi sebelumnya:
/// - Thinking dibatasi (LOW). Gemini 3.x Flash secara default "berpikir"
///   panjang; itu yang membuat respons lambat dan memakan jatah token.
/// - Memakai streaming: teks tampil bertahap, dan timeout dihitung per-chunk
///   (bukan 40 detik menunggu satu respons utuh).
/// - App Check diaktifkan di main(), bukan di dalam permintaan pertama.
class AiService {
  AiService._();

  static final AiService instance = AiService._();

  /// gemini-3.8-flash tidak mendukung thinking level MINIMAL (error 400),
  /// jadi level terendah yang dipakai adalah LOW.
  static const String modelName = 'gemini-3.8-flash';

  // Menunggu chunk pertama (termasuk waktu thinking + App Check token).
  static const Duration _firstChunkTimeout = Duration(seconds: 25);

  // Jeda maksimal antar chunk setelah teks mulai mengalir.
  static const Duration _idleTimeout = Duration(seconds: 15);

  // 1 percobaan awal + retry untuk gangguan server sementara.
  static const int _maxAttempts = 3;

  // Thinking token ikut dihitung dalam batas ini, jadi jangan terlalu kecil.
  static const int _maxOutputTokens = 2048;

  // ============================================================
  // MODEL
  // ============================================================

  GenerativeModel _model({
    required String systemInstruction,
    bool json = false,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        maxOutputTokens: _maxOutputTokens,
        responseMimeType: json ? 'application/json' : null,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ),
    );
  }

  // ============================================================
  // API PUBLIK
  // ============================================================

  /// Chat multi-giliran dengan streaming. Setiap event adalah TEKS LENGKAP
  /// sejauh ini (bukan potongan), jadi UI cukup mengganti teks bubble.
  ///
  /// Riwayat harus berakhir dengan pesan dari pengguna.
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
      model: _model(systemInstruction: systemInstruction),
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
        model: _model(systemInstruction: systemInstruction, json: true),
        contents: [
          Content('user', [TextPart(prompt)]),
        ],
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

  /// Satu permintaan streaming dengan timeout per-chunk.
  Stream<String> _streamOnce(
    GenerativeModel model,
    List<Content> contents,
  ) async* {
    final stopwatch = Stopwatch()..start();
    final iterator = StreamIterator(model.generateContentStream(contents));
    final buffer = StringBuffer();
    var first = true;

    try {
      while (true) {
        final hasNext = await iterator
            .moveNext()
            .timeout(first ? _firstChunkTimeout : _idleTimeout);
        if (!hasNext) break;

        if (first) {
          debugPrint('[AI] chunk pertama setelah '
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
      // menahan error timeout agar tidak sampai ke pengguna.
      unawaited(iterator.cancel().catchError((_) {}));
    }

    debugPrint('[AI] selesai dalam ${stopwatch.elapsedMilliseconds} ms.');

    if (buffer.toString().trim().isEmpty) {
      throw const AiException(
        'AI tidak memberikan jawaban. Silakan coba pertanyaan lain.',
      );
    }
  }

  /// Streaming + retry untuk gangguan server sementara. Retry hanya
  /// dilakukan selama belum ada teks yang sampai ke pengguna.
  Stream<String> _generateStream({
    required GenerativeModel model,
    required List<Content> contents,
  }) async* {
    for (var attempt = 1;; attempt++) {
      var received = false;
      try {
        await for (final text in _streamOnce(model, contents)) {
          received = true;
          yield text;
        }
        return;
      } on AiException {
        rethrow;
      } on TimeoutException {
        debugPrint('[AI] timeout (percobaan $attempt).');
        final hint = kDebugMode ? '\n[debug] ${await probeAppCheck()}' : '';
        throw AiException(
          'AI terlalu lama merespons. Periksa koneksi internet lalu '
          'coba lagi.$hint',
        );
      } on FirebaseAIException catch (e) {
        debugPrint('[AI] FirebaseAIException '
            '(percobaan $attempt/$_maxAttempts): ${e.message}');

        if (!received && attempt < _maxAttempts && _isRetryable(e.message)) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
          continue;
        }
        throw AiException(_describe(e.message));
      } catch (e) {
        debugPrint('[AI] error tidak terduga: $e');
        throw AiException(_describe(e.toString()));
      }
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

  // ============================================================
  // KLASIFIKASI ERROR
  // ============================================================

  bool _isQuota(String m) =>
      m.contains('quota') ||
      m.contains('resource_exhausted') ||
      m.contains('daily limit') ||
      m.contains('limit exceeded');

  bool _isRetryable(String message) {
    final m = message.toLowerCase();
    if (_isQuota(m)) return false;

    return m.contains('500') ||
        m.contains('502') ||
        m.contains('503') ||
        m.contains('504') ||
        m.contains('internal') ||
        m.contains('unavailable') ||
        m.contains('deadline') ||
        m.contains('high demand') ||
        m.contains('overloaded') ||
        m.contains('server error') ||
        m.contains('try again');
  }

  String _describe(String message) {
    final m = message.toLowerCase();

    if (m.contains('socket') ||
        m.contains('failed host lookup') ||
        m.contains('network') ||
        m.contains('connection')) {
      return 'Tidak dapat terhubung ke internet. '
          'Periksa koneksi lalu coba lagi.';
    }
    if (m.contains('app check') ||
        m.contains('app-check') ||
        m.contains('appcheck') ||
        m.contains('attestation')) {
      if (kDebugMode) {
        return 'App Check menolak token (HTTP 403). Daftarkan debug token di '
            'Firebase Console > App Check > Manage debug tokens, atau jalankan '
            'dengan --dart-define=DISABLE_APPCHECK=true selama App Check '
            'belum di-enforce.';
      }
      return 'Verifikasi keamanan aplikasi gagal. '
          'Pastikan aplikasi dipasang dari sumber resmi lalu coba lagi.';
    }
    if (m.contains('location') && m.contains('not supported')) {
      return 'Fitur AI belum tersedia di wilayah Anda.';
    }
    if (_isQuota(m)) {
      return 'Layanan AI sedang mencapai batas penggunaan. '
          'Silakan coba lagi nanti.';
    }
    if (m.contains('429') ||
        m.contains('rate limit') ||
        m.contains('too many requests')) {
      return 'Permintaan AI terlalu sering. Tunggu sebentar lalu coba lagi.';
    }
    if (m.contains('403') ||
        m.contains('permission denied') ||
        m.contains('api key') ||
        m.contains('not authorized') ||
        m.contains('has not been used') ||
        m.contains('disabled')) {
      return 'Akses ke layanan AI ditolak. '
          'Periksa konfigurasi Firebase AI Logic.';
    }
    if (m.contains('404') || m.contains('not found')) {
      return 'Model AI tidak ditemukan. Periksa nama model di konfigurasi.';
    }
    if (m.contains('500') ||
        m.contains('502') ||
        m.contains('503') ||
        m.contains('504') ||
        m.contains('internal') ||
        m.contains('high demand') ||
        m.contains('overloaded') ||
        m.contains('unavailable') ||
        m.contains('server error')) {
      return 'Server AI sedang sibuk. Silakan coba lagi beberapa saat.';
    }
    if (m.contains('400') ||
        m.contains('invalid_argument') ||
        m.contains('bad request')) {
      return 'Permintaan AI tidak dapat diproses. Silakan coba lagi.';
    }

    return 'Terjadi kendala saat menghubungi AI. Silakan coba lagi.';
  }
}
