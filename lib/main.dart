import 'package:flutter/material.dart';
import 'package:ipardasbor/features/non_oss/offline/auto_sync_controller.dart';

import 'app/app.dart';
import 'app/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.loadSavedTheme();
  await AutoSyncController.instance.loadSavedPreference();
  runApp(const IparApp());
}