import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/ocr/ocr_result_sheet.dart';

import 'ocr_field_type.dart';
import 'ocr_service.dart';

/// Alur lengkap scan: pilih Kamera/Galeri, baca teks (dengan loading),
/// tampilkan bottom sheet konfirmasi.
///
/// Mengembalikan nilai yang dicentang pengguna, atau null kalau dibatalkan
/// di tahap mana pun. Map kosong berarti sheet dikonfirmasi tanpa ada yang
/// dicentang. Field form tidak disentuh di sini; pemanggil yang mengisinya.
///
/// [targets] null berarti semua jenis. [currentValues] adalah isi form saat
/// ini, supaya sheet bisa menandai nilai yang akan ditimpa.
Future<Map<OcrFieldType, String>?> runOcrScan(
  BuildContext context, {
  Set<OcrFieldType>? targets,
  Map<OcrFieldType, String> currentValues = const {},
}) async {
  final OcrService service = OcrService();
  OcrImageSource? source = await _pickSource(context);

  while (source != null) {
    if (!context.mounted) return null;

    String? path;
    try {
      final file = await service.pickImage(source);
      path = file?.path;
    } on OcrException catch (e) {
      if (context.mounted) _snack(context, e.message);
      return null;
    }
    if (path == null || !context.mounted) return null; // dibatalkan

    final OcrScanResult? scan =
        await _scanWithLoading(context, service, path, targets);
    if (scan == null || !context.mounted) return null;

    final OcrSheetResult? sheet = await showOcrResultSheet(
      context,
      results: scan.results,
      currentValues: currentValues,
    );
    if (sheet == null) return null;

    if (sheet.retry) {
      if (!context.mounted) return null;
      source = await _pickSource(context);
      continue;
    }
    return sheet.values;
  }
  return null;
}

Future<OcrImageSource?> _pickSource(BuildContext context) {
  return showModalBottomSheet<OcrImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Kamera'),
            subtitle: const Text('Foto langsung angka pada dokumen'),
            onTap: () => Navigator.of(ctx).pop(OcrImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeri'),
            subtitle: const Text('Pilih screenshot atau foto yang sudah ada'),
            onTap: () => Navigator.of(ctx).pop(OcrImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<OcrScanResult?> _scanWithLoading(
  BuildContext context,
  OcrService service,
  String path,
  Set<OcrFieldType>? targets,
) async {
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 14),
                Text('Membaca teks...'),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  try {
    return await service.scanPath(path, targets: targets);
  } on OcrException catch (e) {
    if (context.mounted) _snack(context, e.message);
    return null;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}