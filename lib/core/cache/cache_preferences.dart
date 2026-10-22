import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachePreferences extends ChangeNotifier {
  CachePreferences._();
  static final CachePreferences instance = CachePreferences._();

  static const String _kEnabled = 'cache_enabled';
  static const String _kMaxMb = 'cache_max_mb';
  static const String _kMaxDays = 'cache_max_days';

  static const List<int> pilihanMb = <int>[25, 50, 100, 200];
  static const List<int> pilihanHari = <int>[7, 14, 30, 90];
  static const String _kProyekMaxMb = 'cache_proyek_offline_max_mb';
  static const List<int> pilihanProyekMb = <int>[5, 10, 25, 50];

  bool _enabled = true;
  int _maxMb = 50;
  int _maxDays = 30;

  bool get enabled => _enabled;
  int get maxMb => _maxMb;
  int get maxDays => _maxDays;
  int get maxBytes => _maxMb * 1024 * 1024;
  int _proyekMaxMb = 10;

  int get proyekOfflineMaxMb => _proyekMaxMb;
  int get proyekOfflineMaxBytes => _proyekMaxMb * 1024 * 1024;

  Future<void> setProyekOfflineMaxMb(int value) async {
    _proyekMaxMb = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kProyekMaxMb, value);
  }

  Future<void> loadSavedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? true;
    _maxMb = prefs.getInt(_kMaxMb) ?? 50;
    _maxDays = prefs.getInt(_kMaxDays) ?? 30;
    _proyekMaxMb = prefs.getInt(_kProyekMaxMb) ?? 10;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  Future<void> setMaxMb(int value) async {
    _maxMb = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMaxMb, value);
  }

  Future<void> setMaxDays(int value) async {
    _maxDays = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMaxDays, value);
  }
}
