import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi App Check. Nilai diberikan lewat --dart-define agar tidak
/// ada token/kunci yang ikut ter-commit ke repository.
///
///   flutter run --dart-define=APPCHECK_WEB_DEBUG_TOKEN=<token-debug-web>
///   flutter build web --dart-define=RECAPTCHA_SITE_KEY=<site-key-v3>
const String _webDebugToken =
    String.fromEnvironment('APPCHECK_WEB_DEBUG_TOKEN');
const String _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');


const bool _disableAppCheck = 
    bool.fromEnvironment('DISABLE_APPCHECK', defaultValue: true);

/// Dipanggil SEKALI di main(), setelah Firebase.initializeApp().
///
/// Tidak pernah melempar error: kalau gagal, aplikasi tetap jalan dan fitur AI
/// akan menampilkan pesan yang jelas saat dipakai.
Future<void> initAppCheck() async {
  if (_disableAppCheck) {
    debugPrint('[AppCheck] DIMATIKAN lewat DISABLE_APPCHECK.');
    return;
  }
  try {
    await FirebaseAppCheck.instance
        .activate(
          providerWeb: kDebugMode
              // Tanpa token: SDK membuat token sendiri dan mencetaknya di
              // console browser ("App Check debug token: ...").
              ? WebDebugProvider(
                  debugToken: _webDebugToken.isEmpty ? null : _webDebugToken,
                )
              : (_recaptchaSiteKey.isEmpty
                  ? null
                  : ReCaptchaV3Provider(_recaptchaSiteKey)),
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        )
        .timeout(const Duration(seconds: 8));
    debugPrint('[AppCheck] aktif.');
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
