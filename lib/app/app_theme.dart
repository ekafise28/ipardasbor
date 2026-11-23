import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/pref_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  // ---- Warna dasar terang/gelap (dipakai helper dan ThemeData) ----
  static const Color _scaffoldTerang = Color(0xFFF4F7FC);
  static const Color _scaffoldGelap = Color(0xFF121212);
  static const Color _teksTerang = Color(0xFF152238);
  static const Color _surfaceGelap = Color(0xFF1E1E1E);
  static const Color _borderTerang = Color(0xFFDCE4EF);
  static const Color _borderGelap = Color(0xFF3A3F4B);

  // ---- Brand ----
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF2384DA);
  static const Color secondaryColor = Color(0xFF00A6A6);
  static Color scaffoldColorDynamic(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _scaffoldGelap : _scaffoldTerang;
  }

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryColor, primaryLight],
  );

  // ---- Text ----
  static Color textColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : _teksTerang;
  } // heading

  static Color textSecondary(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFB0B8C4) : const Color(0xFF748197);
  } // body text, secondary icons

  static const Color textMuted = Color(0xFFA1ACBC); // captions, muted icons
  static const Color textOnBrand = Colors.white;
  static const Color textOnBrandMuted = Color(
    0xFFDCEBFF,
  ); // greeting text on gradient
  static const Color textOnBrandBadge = Color(
    0xFFEAF4FF,
  ); // badge text/icon on gradient

  // ---- Skala teks ----
  static const double fontKeterangan = 11.5; // keterangan, label kecil
  static const double fontIsiKecil = 12.5; // isi kecil, subjudul
  static const double fontIsi = 13.5; // isi, nilai baris
  static const double fontJudulKartu = 15; // judul kartu/daftar
  static const double fontJudulHalaman = 18; // judul halaman/sheet
  static const double fontSumbu = 10; // label sumbu/legenda grafik saja
  static const double fontMikro = 9; // header tabel/label rapat di grafik

  // ---- Surfaces ----
  static Color surface(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _surfaceGelap : Colors.white;
  } // cards, dialogs, bottom sheets, etc.

  static Color surfaceMuted(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F9);
  } // icon-button backgrounds

  static Color border(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _borderTerang : _borderTerang;
  }

  /// Latar kotak ikon berwarna: pastel [lightBackground] di mode terang,
  /// warna [color] transparan di mode gelap (supaya tidak ada kotak pastel
  /// terang yang mencolok).
  static Color tintBackground(
    BuildContext context,
    Color color,
    Color lightBackground,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? color.withValues(alpha: 0.18) : lightBackground;
  }

  // ---- Semantic ----
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBackground = Color(0xFFFCE8E8);
  static const Color warning = Color(0xFFEF6C00);
  static const Color warningBackground = Color(0xFFFFF1E3);
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color dangerDark = Color(0xFF8E1B1B);

  // ---- Semantic (dynamic) ----
  static Color warningSurface(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A2A17) : warningBackground;
  }

  static Color warningTitle(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFCC80) : const Color(0xFF5D4037);
  }

  static Color warningBody(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFD7B98E) : const Color(0xFF795548);
  }

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

  static const Color menuFoto = Color(0xFF7E57C2);
  static const Color menuFotoBg = Color(0xFFEDE7F6);

  // ---- Header form (OSS, Non-OSS) ----
  static const List<Color> formHeaderGradient = <Color>[
    Color(0xFF0B4E91),
    primaryColor,
  ];
  static const Color formHeaderText = Color(0xFFE7F2FF);

  // ---- Di atas latar gelap/gradien ----
  static const Color errorOnDark = Color(0xFFFF8A80);

  /// Warna chip jenis data (OSS / OTA / Non-OSS), dipakai kartu dan halaman
  /// detail Riwayat. Jenis yang tidak dikenal dianggap Non-OSS.
  static Color warnaJenis(String jenis) {
    switch (jenis.toUpperCase()) {
      case 'OSS':
        return menuOss;
      case 'OTA':
        return menuOta;
      default:
        return menuNonOss;
    }
  }

  /// Warna tingkat risiko, sama dengan web: Rendah hijau, Menengah Rendah
  /// oranye, Menengah Tinggi ungu, Tinggi merah. Null/tidak dikenal = abu-biru.
  static Color warnaRisiko(String? risiko) {
    switch (risiko?.trim().toLowerCase()) {
      case 'rendah':
        return const Color(0xFF4CAF50);
      case 'menengah rendah':
        return const Color(0xFFFF9800);
      case 'menengah tinggi':
        return const Color(0xFF9C27B0);
      case 'tinggi':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  // ---- Kategori sumber data (dashboard, grafik, peta) ----
  // Satu kategori = satu warna di semua tempat. Mengikuti warna menu di
  // Home: OSS biru, Non-OSS teal, OTA oranye. "Total" sengaja netral
  // (abu-biru) supaya tidak bentrok dengan warna kategori mana pun.
  static const Color categoryTotal = menuProfil;
  static const Color categoryTotalBg = menuProfilBg;

  static const Color categoryOss = primaryColor;
  static const Color categoryOssBg = menuDashboardBg;

  static const Color categoryNonOss = Color(0xFF00897B);
  static const Color categoryNonOssBg = Color(0xFFE2F5F1);

  static const Color categoryOta = menuOta;
  static const Color categoryOtaBg = menuOtaBg;

  // ---- Jawaban ya / tidak / tidak tahu (mis. kepemilikan NIB) ----
  // Bersifat semantik, bukan kategori, jadi memakai hijau/merah/kuning.
  static const Color answerYes = Color(0xFF16A66A);
  static const Color answerNo = Color(0xFFE05C6E);
  static const Color answerUnknown = Color(0xFFF2A93B);
  static const Color answerNone = Color(0xFFB6BEC9);

  // ---- Palet grafik multi-deret ----
  /// Warna deret grafik. Indeks berputar bila deret lebih dari 12. Nilainya
  /// sengaja literal (bukan alias warna merek) supaya palet grafik tidak
  /// ikut berubah saat warna merek diganti.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF8E24AA),
    Color(0xFFD32F2F),
    Color(0xFF00ACC1),
    Color(0xFFF9A825),
    Color(0xFF6D4C41),
    Color(0xFFE91E63),
    Color(0xFF5C6BC0),
    Color(0xFF7CB342),
    Color(0xFF00897B),
  ];

  /// Warna deret ke-[index]. Deret nasional (INDONESIA) selalu abu-biru.
  static Color warnaDeret(int index, {bool nasional = false}) =>
      nasional ? menuProfil : chartPalette[index % chartPalette.length];

  /// Warna batang tunggal grafik (satu deret, tanpa palet).
  static const Color chartBar = primaryColor;

  /// Warna garis bila deret banyak (provinsi/pintu): hue dibagi rata,
  /// seperti di web. Dipakai di mana jumlah deret bisa melebihi 12.
  static Color warnaGarisBagiRata(int index, int total) {
    final double hue = (index * 360 / (total < 1 ? 1 : total)).roundToDouble();
    return HSLColor.fromAHSL(1, hue % 360, 0.78, 0.48).toColor();
  }

  /// Warna tingkat okupansi: merah di bawah 40, kuning 40-59, hijau 60 ke
  /// atas. Null = abu-abu (belum ada data).
  static Color warnaOkupansi(double? v) {
    if (v == null) return answerNone;
    if (v < 40) return answerNo;
    if (v < 60) return answerUnknown;
    return answerYes;
  }

  // ---- Jenis pintu masuk wisatawan mancanegara ----
  static const Color pintuUdara = primaryColor;
  static const Color pintuLaut = categoryNonOss;
  static const Color pintuDarat = warning;

  /// Warna jenis pintu masuk. Nama tak dikenal memakai warna netral.
  static Color warnaPintu(String pintu) {
    switch (pintu) {
      case 'Pintu Udara':
        return pintuUdara;
      case 'Pintu Laut':
        return pintuLaut;
      case 'Pintu Darat':
        return pintuDarat;
      default:
        return menuProfil;
    }
  }

  static IconData ikonPintu(String pintu) {
    switch (pintu) {
      case 'Pintu Udara':
        return Icons.flight_rounded;
      case 'Pintu Laut':
        return Icons.directions_boat_rounded;
      case 'Pintu Darat':
        return Icons.directions_bus_rounded;
      default:
        return Icons.login_rounded;
    }
  }

  // ---- Bayangan ----
  static const Color shadowCard = Color(
    0x0D17243A,
  ); // kartu tipis: dashboard, filter, grafik
  static const Color shadowForm = Color(0x0A152238); // kartu form
  static const Color shadowMap = Color(0x33000000); // kontrol di atas peta

  // ---- Gradien kartu KPI ----
  static const List<Color> kpiBiru = <Color>[
    Color(0xFF064A91),
    Color(0xFF0874BD),
  ];
  static const List<Color> kpiTeal = <Color>[
    Color(0xFF087A9E),
    Color(0xFF11A4BD),
  ];
  static const List<Color> kpiUngu = <Color>[
    Color(0xFF5450A3),
    Color(0xFF776CCC),
  ];
  static const List<Color> kpiAmber = <Color>[
    Color(0xFFB45309),
    Color(0xFFF59E0B),
  ];

  // ---- Hijau terang di atas latar gelap ----
  static const Color hijauMint = Color(0xFF68E7A7);
  static const Color hijauNeon = Color(0xFF7CFFB2);

  // ---- Amber / peringatan (dua saja) ----
  static const Color amber = Color(
    0xFFF59E0B,
  ); // isian, ikon, di atas latar gelap
  static const Color amberDark = Color(0xFFB45309); // teks/ikon di latar terang

  // ---- Status tegas (snackbar, sinkronisasi) ----
  static const Color successBright = Color(
    0xFF22C55E,
  ); // hijau terang (OCR, kategori)
  static const Color errorStrong = Color(0xFFC62828);
  static const Color warningStrong = Color(0xFFC2410C);
  static const Color neutralGrey = Color(0xFF6B7280);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _scaffoldTerang,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _teksTerang,
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
          borderSide: BorderSide(color: _borderTerang),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderTerang),
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
      scaffoldBackgroundColor: _scaffoldGelap,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceGelap,
        surfaceTintColor: _surfaceGelap,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceGelap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderGelap),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderGelap),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
    );
  }

  /// Tema untuk halaman form (OSS, Non-OSS, validasi): warna utama dan gaya
  /// kolom isian tanpa latar terisi. Dipakai lewat
  /// `Theme(data: AppTheme.formTheme(context), child: ...)`.
  static ThemeData formTheme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final OutlineInputBorder garis = OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: border(context)),
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: base.brightness,
        surface: surface(context),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: textSecondary(context)),
        border: garis,
        enabledBorder: garis,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

/// Mengelola status mode gelap aplikasi dan menyimpannya secara lokal
/// agar pilihan pengguna tetap tersimpan setelah aplikasi ditutup.
class ThemeController extends PrefNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);
  static final ThemeController instance = ThemeController._();

  // Kunci lama dipertahankan (tersimpan sebagai bool) supaya pilihan tema
  // pengguna yang sudah ada tetap terbaca.
  @override
  String get prefsKey => 'is_dark_mode';

  bool get isDarkMode => value == ThemeMode.dark;

  @override
  ThemeMode readFrom(SharedPreferences prefs) =>
      (prefs.getBool(prefsKey) ?? false) ? ThemeMode.dark : ThemeMode.light;

  @override
  Future<void> writeTo(SharedPreferences prefs, ThemeMode v) =>
      prefs.setBool(prefsKey, v == ThemeMode.dark);

  Future<void> loadSavedTheme() => loadSavedPreference();

  Future<void> setDarkMode(bool isDark) =>
      save(isDark ? ThemeMode.dark : ThemeMode.light);
}
