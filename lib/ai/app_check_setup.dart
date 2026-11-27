import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// App Check untuk Firebase AI Logic.
///
/// Catatan penting: firebase_ai mengambil token App Check SENDIRI pada setiap
/// permintaan, jadi App Check tidak bisa "dimatikan" dari sisi aplikasi. Yang
/// bisa dilakukan adalah memberinya token yang valid.
///
/// MODE TUGAS KULIAH (default): satu debug token TETAP dipakai di semua
/// device (web, Android, iOS). Daftarkan token ini SEKALI di Firebase Console
/// > App Check > Manage debug tokens, dan semua device langsung bisa memakai
/// AI tanpa pendaftaran per device.
///
/// Risiko: token ikut tertanam di aplikasi, jadi siapa pun yang membongkar
/// APK bisa memakainya. Batasi kuota Firebase AI Logic, dan jangan pakai cara
/// ini untuk rilis publik.
///
/// MODE RILIS PUBLIK: jalankan/build dengan --dart-define=APPCHECK_DEBUG_TOKEN=
/// (kosong) agar memakai Play Integrity / DeviceCheck / reCAPTCHA asli.
const String _debugToken = String.fromEnvironment(
  'APPCHECK_DEBUG_TOKEN',
  defaultValue: 'f18287f2-a0bd-476e-9770-8dcabe3aaec4',
);

const String _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// Dipanggil SEKALI di main(), setelah Firebase.initializeApp().
///
/// Tidak pernah melempar error: kalau gagal, aplikasi tetap jalan dan fitur AI
/// akan menampilkan pesan yang jelas saat dipakai.
Future<void> initAppCheck() async {
  final useDebug = _debugToken.isNotEmpty;

  try {
    await FirebaseAppCheck.instance
        .activate(
          providerWeb: useDebug
              ? WebDebugProvider(debugToken: _debugToken)
              : (_recaptchaSiteKey.isEmpty
                  ? null
                  : ReCaptchaV3Provider(_recaptchaSiteKey)),
          providerAndroid: useDebug
              ? AndroidDebugProvider(debugToken: _debugToken)
              : const AndroidPlayIntegrityProvider(),
          providerApple: useDebug
              ? AppleDebugProvider(debugToken: _debugToken)
              : const AppleDeviceCheckProvider(),
        )
        .timeout(const Duration(seconds: 8));
    debugPrint('[AppCheck] aktif (${useDebug ? "debug token tetap" : "provider asli"}).');
  } catch (e) {
    debugPrint('[AppCheck] gagal diaktifkan: $e');
  }
}

/// Diagnosa cepat (hanya dipakai saat debug): apakah App Check bisa
/// menghasilkan token? Jika ini timeout/gagal, penyebab "AI timeout" adalah
/// App Check (debug token belum didaftarkan), bukan model Gemini.
Future<String> probeAppCheck() async {
  try {
    final token = await FirebaseAppCheck.instance
        .getToken()
        .timeout(const Duration(seconds: 8));
    return (token == null || token.isEmpty)
        ? 'App Check: token kosong'
        : 'App Check: token OK';
  } on TimeoutException {
    return 'App Check: getToken timeout. Debug token kemungkinan belum '
        'didaftarkan di Firebase Console > App Check > Manage debug tokens.';
  } catch (e) {
    return 'App Check: gagal ($e)';
  }
}
