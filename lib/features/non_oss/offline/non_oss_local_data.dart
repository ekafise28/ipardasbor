import 'dart:convert';

import 'sync_status.dart';

/// Satu data pengawasan Non-OSS yang tersimpan di antrean lokal.
class NonOssLocalData {
  const NonOssLocalData({
    this.id,
    required this.clientUuid,
    required this.payload,
    required this.photoPaths,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.lastError,
    this.lastAttemptAt,
    this.syncedAt,
    this.retryCount = 0,
  });

  final int? id;
  final String clientUuid;
  final Map<String, String> payload;
  final List<String> photoPaths;
  final SyncStatus status;
  final int? serverId;
  final String? lastError;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;

  bool get isPending => status == SyncStatus.pending;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isSynced => status == SyncStatus.synced;
  bool get isFailed => status == SyncStatus.failed;

  String get displayName {
    final String brand = payload['nama_brand']?.trim() ?? '';
    if (brand.isNotEmpty) {
      return brand;
    }

    final String owner = payload['nama_pemilik']?.trim() ?? '';
    return owner.isNotEmpty ? owner : 'Data Non-OSS';
  }

  Map<String, Object?> toDatabase() {
    return <String, Object?>{
      'client_uuid': clientUuid,
      'payload_json': jsonEncode(payload),
      'photo_paths_json': jsonEncode(photoPaths),
      'sync_status': status.value,
      'server_id': serverId,
      'last_error': lastError,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory NonOssLocalData.fromDatabase(Map<String, Object?> row) {
    final Map<String, dynamic> decodedPayload =
        jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
    final List<dynamic> decodedPhotos =
        jsonDecode(row['photo_paths_json'] as String) as List<dynamic>;

    return NonOssLocalData(
      id: _toNullableInt(row['id']),
      clientUuid: row['client_uuid'].toString(),
      payload: decodedPayload.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, value.toString()),
      ),
      photoPaths: decodedPhotos
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      status: SyncStatus.fromValue(row['sync_status'].toString()),
      serverId: _toNullableInt(row['server_id']),
      lastError: _toNullableString(row['last_error']),
      retryCount: _toNullableInt(row['retry_count']) ?? 0,
      createdAt: DateTime.parse(row['created_at'].toString()),
      updatedAt: DateTime.parse(row['updated_at'].toString()),
      lastAttemptAt: _toNullableDate(row['last_attempt_at']),
      syncedAt: _toNullableDate(row['synced_at']),
    );
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    return value is int ? value : int.tryParse(value.toString());
  }

  static String? _toNullableString(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    return value.toString();
  }

  static DateTime? _toNullableDate(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
