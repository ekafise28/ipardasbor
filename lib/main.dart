import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.loadSavedTheme();
  runApp(const IparApp());
}