import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  // ---- Brand ----
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF2384DA);
  static const Color secondaryColor = Color(0xFF00A6A6);
  static const Color scaffoldColor = Color(0xFFF4F7FC);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryColor, primaryLight],
  );

  // ---- Text ----
  static const Color textColor = Color(0xFF152238); // headings
  static const Color textSecondary = Color(0xFF748197); // body/subtext
  static const Color textMuted = Color(0xFFA1ACBC); // captions, muted icons
  static const Color textOnBrand = Colors.white;
  static const Color textOnBrandMuted = Color(
    0xFFDCEBFF,
  ); // greeting text on gradient
  static const Color textOnBrandBadge = Color(
    0xFFEAF4FF,
  ); // badge text/icon on gradient

  // ---- Surfaces ----
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(
    0xFFF0F4F9,
  ); // icon-button backgrounds
  static const Color border = Color(0xFFDCE4EF); // matches your input border

  // ---- Semantic ----
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBackground = Color(0xFFFCE8E8);
  static const Color warning = Color(0xFFEF6C00);
  static const Color warningBackground = Color(0xFFFFF1E3);

  // ---- Setting ----
  static const Color menuTampilan = Color(0xFF5C6BC0);
  static const Color menuTampilanBg = Color(0xFFE8EAF6);

  static const Color menuNotifikasi = Color(0xFFF9A825);
  static const Color menuNotifikasiBg = Color(0xFFFFF8E1);

  static const Color menuKeamanan = Color(0xFF2E7D32);
  static const Color menuKeamananBg = Color(0xFFE8F5E9);

  static const Color menuTentang = Color(0xFF546E7A);
  static const Color menuTentangBg = Color(0xFFECEFF1);

  // ---- Menu category accents ----
  static const Color menuDashboard = primaryColor;
  static const Color menuDashboardBg = Color(0xFFE8F1FD);

  static const Color menuOss = primaryDark;
  static const Color menuOssBg = Color(0xFFE8F1FD);

  static const Color menuNonOss = secondaryColor;
  static const Color menuNonOssBg = Color(0xFFE2F5F1);

  static const Color menuOta = Color(0xFFD84315);
  static const Color menuOtaBg = Color(0xFFFBE9E7);

  static const Color menuRiwayat = warning;
  static const Color menuRiwayatBg = warningBackground;

  static const Color menuSinkronisasi = Color(0xFF0277BD);
  static const Color menuSinkronisasiBg = Color(0xFFE1F5FE);

  static const Color menuProfil = Color(0xFF455A64);
  static const Color menuProfilBg = Color(0xFFECEFF1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldColor,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE4EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE4EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A3F4B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A3F4B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
    );
  }
}

/// Mengelola status mode gelap aplikasi dan menyimpannya secara lokal
/// agar pilihan pengguna tetap tersimpan setelah aplikasi ditutup.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'is_dark_mode';

  bool get isDarkMode => value == ThemeMode.dark;

  /// Dipanggil sekali saat aplikasi pertama kali dijalankan untuk memuat
  /// preferensi tema yang tersimpan.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDark = prefs.getBool(_prefsKey) ?? false;
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}