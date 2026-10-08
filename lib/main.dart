import 'package:flutter/material.dart';
import 'package:ipardasbor/features/non_oss/offline/auto_sync_controller.dart';
import 'package:ipardasbor/features/notifications/services/notification_category_preferences.dart';
import 'package:ipardasbor/features/notifications/services/notification_local_service.dart';
import 'package:ipardasbor/features/notifications/services/notification_retention_controller.dart';
import 'package:ipardasbor/features/notifications/services/notification_statusbar_controller.dart';
import 'package:ipardasbor/shared/screenshot/screenshot_button_controller.dart';

import 'app/app.dart';
import 'app/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.loadSavedTheme();
  await AutoSyncController.instance.loadSavedPreference();
  await NotificationRetentionController.instance.loadSavedPreference();
  await NotificationCategoryPreferences.instance.loadSavedPreference();
  await NotificationStatusBarController.instance.loadSavedPreference();
  await NotificationLocalService.instance.init();
  await ScreenshotButtonController.instance.loadSavedPreference();
  runApp(const IparApp());
}
