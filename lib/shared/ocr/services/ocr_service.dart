import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ocr_field_type.dart';
import '../parsing/ocr_parser.dart';
import '../models/ocr_recognition.dart';
import '../models/ocr_result.dart';

enum OcrImageSource { camera, gallery }

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Keluaran satu kali scan: teks mentah (untuk debug), hasil parser, dan
/// [recognition] (posisi baris asli) untuk layar pilih manual dari gambar.
/// [recognition] null kalau ukuran gambar gagal dibaca.
class OcrScanResult {
  const OcrScanResult({
    required this.lines,
    required this.results,
    this.recognition,
  });

  final List<String> lines;
  final Map<OcrFieldType, List<OcrResult>> results;
  final OcrRecognition? recognition;

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

  /// Jalankan OCR + parser untuk file yang sudah dipilih. OCR hanya jalan
  /// sekali; teks per baris asli ikut dikembalikan di [OcrScanResult.recognition].
  Future<OcrScanResult> scanPath(
    String path, {
    Set<OcrFieldType>? targets,
    String bidang = 'akomodasi',
  }) async {
    final RecognizedText text = await _recognize(path);
    final List<String> lines = _toVisualRows(text);
    if (kDebugMode) debugPrint('OCR raw lines: $lines');

    final results = OcrParser.parse(lines, targets: targets, bidang: bidang);
    return OcrScanResult(
      lines: lines,
      results: results,
      recognition: await _buildRecognition(path, text),
    );
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
    final RecognizedText text = await _recognize(path);
    final List<String> lines = _toVisualRows(text);
    if (kDebugMode) debugPrint('OCR raw lines: $lines');
    return lines;
  }

  Future<RecognizedText> _recognize(String path) async {
    final TextRecognizer recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      return await recognizer.processImage(InputImage.fromFilePath(path));
    } catch (e) {
      debugPrint('OCR gagal membaca gambar: $e');
      throw const OcrException('Gagal membaca teks dari gambar.');
    } finally {
      await recognizer.close();
    }
  }

  /// Baris asli ML Kit (bukan baris gabungan) + ukuran gambar. Null kalau
  /// ukuran gambar tidak bisa dibaca; alur utama tidak boleh gagal karenanya.
  Future<OcrRecognition?> _buildRecognition(
    String path,
    RecognizedText text,
  ) async {
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      final image = await decodeImageFromList(bytes);
      final Size size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();

      final List<OcrTextLine> lines = [
        for (final block in text.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty)
              OcrTextLine(text: line.text.trim(), box: line.boundingBox),
      ]..sort((a, b) {
          final int c = a.box.top.compareTo(b.box.top);
          return c != 0 ? c : a.box.left.compareTo(b.box.left);
        });

      return OcrRecognition(imagePath: path, imageSize: size, lines: lines);
    } catch (e) {
      debugPrint('OCR gagal menyiapkan data posisi: $e');
      return null;
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