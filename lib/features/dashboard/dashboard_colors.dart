import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Palet warna tunggal untuk halaman dashboard.
///
/// Satu kategori = satu warna, di mana pun ia muncul (kartu statistik,
/// grafik, komposisi, peta). Warna kategori mengikuti warna menu di Home:
/// OSS biru, Non-OSS teal, OTA oranye. "Total" sengaja netral (abu-biru)
/// supaya tidak bentrok dengan warna kategori mana pun.
///
/// Warna ya/tidak/tidak tahu (mis. kepemilikan NIB) bersifat semantik,
/// bukan kategori, sehingga memakai hijau/merah/kuning.
class DashboardColors {
  DashboardColors._();

  // ---- Kategori sumber data ----
  static const Color total = AppTheme.menuProfil;
  static const Color totalBg = AppTheme.menuProfilBg;

  static const Color oss = AppTheme.primaryColor;
  static const Color ossBg = AppTheme.menuDashboardBg;

  static const Color nonOss = Color(0xFF00897B);
  static const Color nonOssBg = Color(0xFFE2F5F1);

  static const Color ota = AppTheme.menuOta;
  static const Color otaBg = AppTheme.menuOtaBg;

  // ---- Semantik ----
  static const Color yes = Color(0xFF16A66A);
  static const Color no = Color(0xFFE05C6E);
  static const Color unknown = Color(0xFFF2A93B);
  static const Color neutral = Color(0xFFB6BEC9);
}