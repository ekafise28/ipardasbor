import 'package:ipardasbor/shared/utils/pref_notifier.dart';

/// Preferensi masa simpan notifikasi (dalam hari). Default 30 hari (1 bulan).
class NotificationRetentionController extends IntPref {
  NotificationRetentionController._() : super(30);
  static final NotificationRetentionController instance =
      NotificationRetentionController._();

  @override
  String get prefsKey => 'notification_retention_days';

  Future<void> setDays(int days) => save(days);
}