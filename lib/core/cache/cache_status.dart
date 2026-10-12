import 'package:flutter/foundation.dart';

class CacheStatus extends ValueNotifier<DateTime?> {
  CacheStatus._() : super(null);
  static final CacheStatus instance = CacheStatus._();

  bool get isOffline => value != null;

  void markFromCache(DateTime savedAt) => value = savedAt;
  void markLive() => value = null;
}