import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_item.dart';

/// Kategori notifikasi yang DINONAKTIFKAN pengguna. Semua kategori aktif
/// secara default (Set kosong = tidak ada yang dimatikan).
class NotificationCategoryPreferences extends ValueNotifier<Set<NotificationType>> {
  NotificationCategoryPreferences._() : super(<NotificationType>{});

  static final NotificationCategoryPreferences instance =
      NotificationCategoryPreferences._();

  static const String _prefsKey = 'notification_disabled_types';

  Future<void> loadSavedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> disabled = prefs.getStringList(_prefsKey) ?? <String>[];
    value = disabled.map(NotificationType.fromValue).toSet();
  }

  bool isEnabled(NotificationType type) => !value.contains(type);

  Future<void> setEnabled(NotificationType type, bool enabled) async {
    final Set<NotificationType> updated = Set<NotificationType>.from(value);
    if (enabled) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    value = updated;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.map((t) => t.value).toList());
  }
}