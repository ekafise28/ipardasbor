import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_result.dart';
import 'package:ipardasbor/shared/ocr/pages/ocr_image_picker_page.dart';
import 'package:ipardasbor/shared/ocr/pages/ocr_live_camera_page.dart';
import 'package:ipardasbor/shared/ocr/pages/ocr_live_copy_page.dart';
import 'package:ipardasbor/shared/ocr/services/ocr_service.dart';
import 'package:ipardasbor/shared/ocr/widgets/ocr_result_sheet.dart';

/// Sumber gambar yang ditawarkan ke pengguna. [camera] membuka layar kamera
/// milik aplikasi (dengan bingkai dan deteksi), bukan kamera bawaan HP;
/// layar itu mengembalikan path foto seperti halnya image_picker.
/// [liveCopy] hanya menyalin teks ke clipboard dan tidak mengisi field.
enum _Source { camera, liveCopy, gallery }

/// Alur lengkap scan: pilih Kamera/Galeri, baca teks (dengan loading),
/// tampilkan bottom sheet konfirmasi. Dari sheet,
/// pengguna bisa membuka layar "pilih dari gambar" untuk menunjuk sendiri
/// barisnya; hasilnya kembali ke sheet yang sama.
///
/// Pilihan "Kamera live copy" hanya menyalin teks ke clipboard, jadi selalu
/// mengembalikan null (tidak ada nilai untuk mengisi field).
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
  String bidang = 'akomodasi',
}) async {
  final OcrService service = OcrService();
  _Source? source = await _pickSource(context);

  while (source != null) {
    if (!context.mounted) return null;

    if (source == _Source.liveCopy) {
      await showOcrLiveCopy(context);
      return null; // hanya menyalin, tidak ada yang diisikan ke form
    }

    String? path;
    try {
      if (source == _Source.camera) {
        path = await showOcrLiveCamera(
          context,
          targets: targets,
          bidang: bidang,
        );
      } else {
        final file = await service.pickImage(OcrImageSource.gallery);
        path = file?.path;
      }
    } on OcrException catch (e) {
      if (context.mounted) _snack(context, e.message);
      return null;
    }
    if (path == null || !context.mounted) return null; // dibatalkan

    final OcrScanResult? scan = await _scanWithLoading(
      context,
      service,
      path,
      targets,
      bidang,
    );
    if (scan == null || !context.mounted) return null;

    // Hasil yang sedang ditampilkan. Berubah kalau pengguna memilih
    // manual dari gambar yang sama (tanpa foto/OCR ulang).
    Map<OcrFieldType, List<OcrResult>> results = scan.results;
    Set<OcrFieldType> preChecked = {};
    final recognition = scan.recognition;
    final bool canManual = recognition != null && recognition.hasLines;

    while (true) {
      final OcrSheetResult? sheet = await showOcrResultSheet(
        context,
        results: results,
        currentValues: currentValues,
        canPickManual: canManual,
        preChecked: preChecked,
        bidang: bidang,
      );
      if (sheet == null) return null;
      if (!context.mounted) return null;

      if (sheet.manual && recognition != null) {
        final OcrManualPick? pick = await showOcrImagePicker(
          context,
          recognition: recognition,
          targets: targets,
          initialType: _firstMissing(results),
          bidang: bidang,
        );
        if (!context.mounted) return null;
        if (pick != null) {
          results = {...results, pick.type: pick.results};
          preChecked = {...preChecked, pick.type};
        }
        continue; // kembali ke sheet, dengan atau tanpa perubahan
      }

      if (sheet.retry) {
        source = await _pickSource(context);
        break; // ulang dari awal dengan sumber baru (atau selesai kalau null)
      }
      return sheet.values;
    }
  }
  return null;
}

/// Jenis pertama yang belum ketemu, supaya layar pilih manual langsung
/// terbuka di jenis yang paling butuh bantuan. Null kalau semua sudah ada.
OcrFieldType? _firstMissing(Map<OcrFieldType, List<OcrResult>> results) {
  for (final t in OcrFieldType.values) {
    if (results.containsKey(t) && (results[t] ?? const []).isEmpty) return t;
  }
  return null;
}

Future<_Source?> _pickSource(BuildContext context) {
  return showModalBottomSheet<_Source>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Kamera'),
            subtitle: const Text('Arahkan angka ke bingkai, terbaca otomatis'),
            onTap: () => Navigator.of(ctx).pop(_Source.camera),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: const Text('Kamera live copy'),
            subtitle: const Text('Salin teks langsung dari kamera'),
            onTap: () => Navigator.of(ctx).pop(_Source.liveCopy),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeri'),
            subtitle: const Text('Pilih screenshot atau foto yang sudah ada'),
            onTap: () => Navigator.of(ctx).pop(_Source.gallery),
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
  String bidang,
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
    return await service.scanPath(path, targets: targets, bidang: bidang);
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