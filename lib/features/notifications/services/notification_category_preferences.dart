import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_item.dart';

/// Kategori notifikasi yang DINONAKTIFKAN pengguna. Semua kategori aktif
/// secara default (Set kosong = tidak ada yang dimatikan).
import 'package:ipardasbor/shared/utils/pref_notifier.dart';

class NotificationCategoryPreferences
    extends PrefNotifier<Set<NotificationType>> {
  NotificationCategoryPreferences._() : super(<NotificationType>{});
  static final NotificationCategoryPreferences instance =
      NotificationCategoryPreferences._();

  @override
  String get prefsKey => 'notification_disabled_types';

  @override
  Set<NotificationType> readFrom(SharedPreferences prefs) =>
      (prefs.getStringList(prefsKey) ?? <String>[])
          .map(NotificationType.fromValue)
          .toSet();

  @override
  Future<void> writeTo(SharedPreferences prefs, Set<NotificationType> v) =>
      prefs.setStringList(prefsKey, v.map((t) => t.value).toList());

  bool isEnabled(NotificationType type) => !value.contains(type);

  Future<void> setEnabled(NotificationType type, bool enabled) {
    final Set<NotificationType> updated = Set<NotificationType>.from(value);
    if (enabled) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    return save(updated);
  }
}