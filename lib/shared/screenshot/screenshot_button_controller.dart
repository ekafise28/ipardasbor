import 'package:ipardasbor/shared/utils/pref_notifier.dart';

class ScreenshotButtonController extends BoolPref {
  ScreenshotButtonController._();
  static final ScreenshotButtonController instance =
      ScreenshotButtonController._();

  @override
  String get prefsKey => 'screenshot_button_enabled';
}
