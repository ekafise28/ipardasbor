import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi masa simpan notifikasi (dalam hari). Default 30 hari (1 bulan).
class NotificationRetentionController extends ValueNotifier<int> {
  NotificationRetentionController._() : super(30);

  static final NotificationRetentionController instance =
      NotificationRetentionController._();

  static const String _prefsKey = 'notification_retention_days';

  Future<void> loadSavedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    value = prefs.getInt(_prefsKey) ?? 30;
  }

  Future<void> setDays(int days) async {
    value = days;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, days);
  }
}