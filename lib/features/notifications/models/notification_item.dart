/// Jenis kejadian yang bisa memicu notifikasi. Menentukan ikon dan warna
/// di NotificationPage (dikerjakan di J3).
enum NotificationType {
  syncFailed,
  syncSuccess,
  waitingTooLong,
  draftLingering;

  String get value => name.toUpperCase();

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (NotificationType t) => t.value == value.toUpperCase(),
      orElse: () => NotificationType.syncFailed,
    );
  }
}

/// Satu notifikasi di inbox, milik satu akun (dibatasi lewat user_id di
/// NotificationService, bukan field di sini - sama pola dengan
/// NonOssLocalData yang tidak menyimpan user_id di objeknya sendiri).
class NotificationItem {
  const NotificationItem({
    this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.dedupeKey,
    this.targetType,
    this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  final int? id;
  final NotificationType type;
  final String title;
  final String body;

  /// Identitas unik kejadian per akun (mis. 'sync_failed:<clientUuid>').
  /// Dua notifikasi dengan dedupeKey sama akan saling menimpa, bukan
  /// menumpuk (lihat UNIQUE INDEX di migrasi).
  final String dedupeKey;

  /// Kemana notifikasi ini membawa saat diketuk. 'submission_detail' perlu
  /// [targetId] = clientUuid; 'sync_page' tidak perlu targetId.
  final String? targetType;
  final String? targetId;

  final bool isRead;
  final DateTime createdAt;

  Map<String, Object?> toDatabase(String userId) {
    return <String, Object?>{
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'dedupe_key': dedupeKey,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationItem.fromDatabase(Map<String, Object?> row) {
    return NotificationItem(
      id: row['id'] as int?,
      type: NotificationType.fromValue(row['type'].toString()),
      title: row['title'].toString(),
      body: row['body'].toString(),
      dedupeKey: row['dedupe_key'].toString(),
      targetType: row['target_type']?.toString(),
      targetId: row['target_id']?.toString(),
      isRead: (row['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }
}