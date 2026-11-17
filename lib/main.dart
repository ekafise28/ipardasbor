import 'package:flutter/material.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/auto_sync_controller.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/non_oss_queue_store.dart';
import 'package:ipardasbor/features/notifications/services/notification_category_preferences.dart';
import 'package:ipardasbor/features/notifications/services/notification_local_service.dart';
import 'package:ipardasbor/features/notifications/services/notification_retention_controller.dart';
import 'package:ipardasbor/features/notifications/services/notification_statusbar_controller.dart';
import 'package:ipardasbor/shared/screenshot/screenshot_button_controller.dart';
import 'package:ipardasbor/core/cache/api_cache.dart';
import 'package:ipardasbor/core/cache/cache_preferences.dart';
import 'package:ipardasbor/core/network/network_status.dart';

import 'app/app.dart';
import 'app/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait(<Future<void>>[
    ThemeController.instance.loadSavedTheme(),
    AutoSyncController.instance.loadSavedPreference(),
    NotificationRetentionController.instance.loadSavedPreference(),
    NotificationCategoryPreferences.instance.loadSavedPreference(),
    NotificationStatusBarController.instance.loadSavedPreference(),
    ScreenshotButtonController.instance.loadSavedPreference(),
    CachePreferences.instance.loadSavedPreference(),
  ]);
  await NotificationLocalService.instance.init();
  await NetworkStatus.instance.init();
  ApiCache.instance.pruneExpired(); // tanpa await, jalan di latar belakang
  // Saat app baru dibuka tidak ada proses kirim yang berjalan, jadi semua
  // SYNCING sisa sesi sebelumnya aman dikembalikan ke PENDING.
  try {
    await NonOssQueueStore.instance.restoreInterruptedSyncs(
      staleAfter: Duration.zero,
    );
  } catch (_) {}
  runApp(const IparApp());
}
