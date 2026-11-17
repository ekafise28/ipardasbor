import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dasar preferensi aplikasi berbentuk ValueNotifier yang disimpan di
/// SharedPreferences. Subclass mengisi [prefsKey]; tipe khusus juga mengisi
/// [readFrom] dan [writeTo].
abstract class PrefNotifier<T> extends ValueNotifier<T> {
  PrefNotifier(super.value);

  String get prefsKey;
  T readFrom(SharedPreferences prefs);
  Future<void> writeTo(SharedPreferences prefs, T newValue);

  /// Dipanggil sekali saat aplikasi dibuka.
  Future<void> loadSavedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    value = readFrom(prefs);
  }

  /// Ubah nilai (UI langsung berubah), lalu simpan.
  Future<void> save(T newValue) async {
    value = newValue;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await writeTo(prefs, newValue);
  }
}

/// Preferensi ya/tidak.
abstract class BoolPref extends PrefNotifier<bool> {
  BoolPref({bool defaultValue = false})
    : _default = defaultValue,
      super(defaultValue);

  final bool _default;

  bool get isEnabled => value;

  @override
  bool readFrom(SharedPreferences prefs) =>
      prefs.getBool(prefsKey) ?? _default;

  @override
  Future<void> writeTo(SharedPreferences prefs, bool newValue) =>
      prefs.setBool(prefsKey, newValue);

  Future<void> setEnabled(bool enabled) => save(enabled);
}

/// Preferensi angka bulat.
abstract class IntPref extends PrefNotifier<int> {
  IntPref(int defaultValue) : _default = defaultValue, super(defaultValue);

  final int _default;

  @override
  int readFrom(SharedPreferences prefs) => prefs.getInt(prefsKey) ?? _default;

  @override
  Future<void> writeTo(SharedPreferences prefs, int newValue) =>
      prefs.setInt(prefsKey, newValue);
}