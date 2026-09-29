import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/shared/ocr/ocr_result_sheet.dart';

import 'ocr_field_type.dart';
import 'ocr_paste_cleaner.dart';
import 'ocr_result.dart';

/// Tempel dari clipboard ke satu field, dengan pembersihan otomatis.
///
/// Mengembalikan nilai yang harus diisi ke field, atau null kalau tidak ada
/// yang perlu diubah (clipboard kosong, tidak ditemukan, atau dibatalkan).
/// Pesan ke pengguna ditampilkan lewat SnackBar di sini.
///
/// Kalau clipboard memuat beberapa kandidat (misalnya beberapa KBLI),
/// pengguna memilih lewat bottom sheet yang sama dengan hasil scan.
Future<String?> runPaste(
  BuildContext context, {
  required OcrFieldType type,
  String currentValue = '',
}) async {
  final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
  if (!context.mounted) return null;

  final String text = data?.text ?? '';
  if (text.trim().isEmpty) {
    _snack(context, 'Clipboard kosong.');
    return null;
  }

  final List<OcrResult> cands = OcrPasteCleaner.clean(text, type);
  if (cands.isEmpty) {
    _snack(context, 'Tidak ada ${type.displayName} yang ditemukan di clipboard.');
    return null;
  }

  if (cands.length == 1) {
    final OcrResult r = cands.first;
    _snack(
      context,
      r.hasWarning
          ? '${type.displayName} ditempel. ${r.warningMessages.first}'
          : '${type.displayName} ditempel (${r.digitCount} digit).',
    );
    return r.value;
  }

  final OcrSheetResult? sheet = await showOcrResultSheet(
    context,
    results: {type: cands},
    currentValues: {type: currentValue},
    allowRetry: false,
  );
  if (sheet == null || sheet.retry) return null;
  return sheet.values[type];
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}