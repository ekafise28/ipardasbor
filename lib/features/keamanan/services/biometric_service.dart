import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const String _kEnabled = 'app_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  /// Jenis biometrik yang terdaftar dan boleh dipakai aplikasi.
  Future<Set<BiometricType>> types() async {
    try {
      return (await _auth.getAvailableBiometrics()).toSet();
    } on PlatformException {
      return <BiometricType>{};
    }
  }

  /// [biometricOnly] false = PIN/pola HP boleh jadi cadangan.
  Future<bool> authenticate(String alasan, {bool biometricOnly = false}) async {
    try {
      return await _auth.authenticate(
        localizedReason: alasan,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return p.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, value);
  }
}