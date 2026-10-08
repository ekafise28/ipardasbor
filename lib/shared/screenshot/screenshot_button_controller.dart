import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenshotButtonController extends ValueNotifier<bool> {
  ScreenshotButtonController._() : super(false);

  static final ScreenshotButtonController instance =
      ScreenshotButtonController._();

  static const String _key = 'screenshot_button_enabled';

  bool get isEnabled => value;

  Future<void> loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}