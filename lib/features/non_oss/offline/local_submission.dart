import 'dart:convert';

import 'sync_status.dart';

class LocalSubmission {
  const LocalSubmission({
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;
  final int retryCount;

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

  factory LocalSubmission.fromDatabase(Map<String, Object?> row) {
    final rawPayload = jsonDecode(row['payload_json']! as String) as Map;
    final rawPhotos = jsonDecode(row['photo_paths_json']! as String) as List;

    return LocalSubmission(
      id: row['id']! as int,
      clientUuid: row['client_uuid']! as String,
      payload: rawPayload.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      photoPaths: rawPhotos.map((value) => value.toString()).toList(),
      status: SyncStatus.fromValue(row['sync_status']! as String),
      serverId: row['server_id'] as int?,
      lastError: row['last_error'] as String?,
      retryCount: (row['retry_count'] as int?) ?? 0,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      lastAttemptAt: _dateOrNull(row['last_attempt_at']),
      syncedAt: _dateOrNull(row['synced_at']),
    );
  }

  static DateTime? _dateOrNull(Object? value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return DateTime.parse(value.toString());
  }
}
