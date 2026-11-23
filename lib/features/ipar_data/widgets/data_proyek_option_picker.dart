import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/app_sheet.dart';

import '../models/proyek_data_option.dart';
import '../services/proyek_data_service.dart';

/// Mengembalikan nilai yang dipilih (daftar kosong = "hapus pilihan"),
/// atau null kalau sheet ditutup tanpa memilih.
Future<List<String>?> showProyekDataOptionPicker(
  BuildContext context, {
  required String title,
  required ProyekDataOptionType tipe,
  required ProyekDataService service,
  required List<String> selected,
  bool single = false,
  String? provinsi,
}) {
  final bool kbli = tipe == ProyekDataOptionType.kbli;

  return showMultiSelectSheet(
    context,
    title: title,
    selected: selected,
    single: single,
    hintCari: kbli ? 'Kode atau nama KBLI...' : 'Cari...',
    minKarakter: kbli ? 2 : 0,
    petunjukAwal: kbli ? 'Ketik minimal 2 karakter kode atau nama KBLI.' : null,
    muat: (String q) async {
      final ProyekDataOptionResult r = await service.fetchOptions(
        tipe: tipe,
        q: q,
        provinsi: provinsi,
      );
      return HasilOpsi(
        opsi: <OpsiPilihan>[
          for (final ProyekDataOption o in r.options)
            OpsiPilihan(o.value, o.labelTampil),
        ],
        pesan: r.message,
      );
    },
  );
}