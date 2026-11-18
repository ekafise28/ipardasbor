import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/chart_colors.dart';

import 'models/okupansi_hotel_data.dart';

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
