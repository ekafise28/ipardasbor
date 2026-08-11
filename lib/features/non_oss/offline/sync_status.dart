enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  String get value => name.toUpperCase();

  static SyncStatus fromValue(String value) {
    return SyncStatus.values.firstWhere(
      (SyncStatus status) => status.value == value.toUpperCase(),
      orElse: () => SyncStatus.pending,
    );
  }
}
