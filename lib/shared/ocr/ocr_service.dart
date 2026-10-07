import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_field_type.dart';
import 'ocr_parser.dart';
import 'ocr_result.dart';

enum OcrImageSource { camera, gallery }

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Keluaran satu kali scan: teks mentah (untuk debug) dan hasil parser.
class OcrScanResult {
  const OcrScanResult({required this.lines, required this.results});

  final List<String> lines;
  final Map<OcrFieldType, List<OcrResult>> results;

  bool get hasAnyResult => results.values.any((l) => l.isNotEmpty);
}

/// Membungkus image_picker + ML Kit. Tidak menyimpan gambar permanen;
/// file dari image_picker hanya file sementara di cache.
class OcrService {
  OcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Sisi terpanjang maksimal. Hanya memperkecil, tidak pernah memperbesar.
  static const double _maxImageSide = 2048;

  /// Pilih gambar lalu proses. Mengembalikan null kalau pengguna membatalkan.
  Future<OcrScanResult?> scan(
    OcrImageSource source, {
    Set<OcrFieldType>? targets,
    String bidang = 'akomodasi',
  }) async {
    final XFile? file = await pickImage(source);
    if (file == null) return null;
    return scanPath(file.path, targets: targets, bidang: bidang);
  }

  /// Jalankan OCR + parser untuk file yang sudah dipilih.
  Future<OcrScanResult> scanPath(
    String path, {
    Set<OcrFieldType>? targets,
    String bidang = 'akomodasi',
  }) async {
    final List<String> lines = await readLines(path);
    final results = OcrParser.parse(lines, targets: targets, bidang: bidang);
    return OcrScanResult(lines: lines, results: results);
  }

  /// Buka kamera/galeri. Null kalau pengguna membatalkan.
  Future<XFile?> pickImage(OcrImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source == OcrImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxImageSide,
        maxHeight: _maxImageSide,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('OCR gagal memilih gambar: $e');
      throw OcrException(
        source == OcrImageSource.camera
            ? 'Tidak dapat membuka kamera.'
            : 'Tidak dapat membuka galeri.',
      );
    }
  }

  /// Baca teks dari file gambar, dikembalikan per baris visual.
  Future<List<String>> readLines(String path) async {
    final TextRecognizer recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final RecognizedText text = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final List<String> lines = _toVisualRows(text);
      if (kDebugMode) debugPrint('OCR raw lines: $lines');
      return lines;
    } catch (e) {
      debugPrint('OCR gagal membaca gambar: $e');
      throw const OcrException('Gagal membaca teks dari gambar.');
    } finally {
      await recognizer.close();
    }
  }

  /// ML Kit sering memecah label dan nilainya jadi blok terpisah walau
  /// sebaris di layar. Gabungkan baris yang sejajar secara vertikal supaya
  /// aturan "label di baris yang sama" pada parser tetap berlaku.
  List<String> _toVisualRows(RecognizedText text) {
    final List<TextLine> all = [
      for (final block in text.blocks) ...block.lines,
    ];
    all.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final List<List<TextLine>> rows = [];
    Rect? reference;
    for (final line in all) {
      final Rect box = line.boundingBox;
      final bool sameRow =
          rows.isNotEmpty &&
          reference != null &&
          box.center.dy >= reference.top &&
          box.center.dy <= reference.bottom;
      if (sameRow) {
        rows.last.add(line);
      } else {
        rows.add([line]);
        reference = box;
      }
    }

    return rows
        .map((row) {
          row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          return row
              .map((l) => l.text.trim())
              .where((t) => t.isNotEmpty)
              .join(' ');
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
