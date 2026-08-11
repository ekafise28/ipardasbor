import 'package:flutter/material.dart';

import '../core/storage/secure_storage.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isRedirectingToLogin = false;

  static Future<void> handleSessionExpired() async {
    // Mencegah beberapa request melakukan redirect bersamaan.
    if (_isRedirectingToLogin) {
      return;
    }

    _isRedirectingToLogin = true;

    await SecureStorage.clearSession();

    final NavigatorState? navigator = navigatorKey.currentState;

    if (navigator == null) {
      _isRedirectingToLogin = false;
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  /// Dipanggil setelah login berhasil agar penanganan sesi dapat digunakan lagi.
  static void resetSessionRedirect() {
    _isRedirectingToLogin = false;
  }
}
