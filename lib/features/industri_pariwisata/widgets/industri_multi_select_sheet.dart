// Lembar pilihan multi-pilih untuk filter Industri Pariwisata. Isinya
// kerangka bersama (shared/widgets/app_sheet.dart); berkas ini hanya
// mengubah IndustriOption menjadi OpsiPilihan.

import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/app_sheet.dart';

import '../models/industri_option.dart';

/// Mengembalikan daftar nilai yang dipilih, atau null jika lembar ditutup
/// tanpa menekan tombol pilih.
Future<List<String>?> showIndustriMultiSelect(
  BuildContext context, {
  required String title,
  required List<IndustriOption> options,
  required List<String> selected,
}) {
  return showMultiSelectSheet(
    context,
    title: title,
    selected: selected,
    opsi: <OpsiPilihan>[
      for (final IndustriOption o in options) OpsiPilihan(o.value, o.label),
    ],
  );
}