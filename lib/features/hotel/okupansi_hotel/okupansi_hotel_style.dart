import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import 'models/okupansi_hotel_data.dart';

const List<Color> _palet = <Color>[
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

/// Warna deret ke-[index] dari palet bersama. Deret nasional (INDONESIA)
/// selalu abu-biru. Dipakai grafik Okupansi dan grafik Wisatawan.
Color warnaDeret(int index, {bool nasional = false}) =>
    nasional ? AppTheme.menuProfil : _palet[index % _palet.length];

Color warnaSeries(int index, OkupansiSeries s) =>
    warnaDeret(index, nasional: s.nasional);

/// Warna tingkat okupansi: merah di bawah 40, kuning 40-59, hijau 60 ke atas.
Color warnaOkupansi(double? v) {
  if (v == null) return AppTheme.answerNone;
  if (v < 40) return AppTheme.answerNo;
  if (v < 60) return AppTheme.answerUnknown;
  return AppTheme.answerYes;
}

/// Kunci unik satu deret (provinsi + tahun).
String kunciSeries(OkupansiSeries s) => '${s.provinsi}|${s.tahun}';
