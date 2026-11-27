import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';


const String _debugToken = String.fromEnvironment(
  'APPCHECK_DEBUG_TOKEN',
  defaultValue: 'f18287f2-a0bd-476e-9770-8dcabe3aaec4',
);

const String _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');


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


    unawaited(
      FirebaseAppCheck.instance
          .getToken()
          .timeout(const Duration(seconds: 10))
          .then<void>((_) {})
          .catchError((Object e) {
        debugPrint('[AppCheck] pemanasan token gagal: $e');
      }),
    );
  } catch (e) {
    debugPrint('[AppCheck] gagal diaktifkan: $e');
  }
}

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
