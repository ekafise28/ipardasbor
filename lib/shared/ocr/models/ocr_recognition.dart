import 'dart:ui';

/// Satu baris teks asli dari ML Kit beserta kotaknya (dalam piksel gambar).
class OcrTextLine {
  const OcrTextLine({required this.text, required this.box});

  final String text;
  final Rect box;
}

/// Hasil baca satu gambar yang cukup untuk menggambar kotak yang bisa
/// di-tap, tanpa perlu menjalankan OCR dua kali.
///
/// [imageSize] adalah ukuran gambar setelah orientasi EXIF diterapkan,
/// sama dengan ruang koordinat [OcrTextLine.box].
class OcrRecognition {
  const OcrRecognition({
    required this.imagePath,
    required this.imageSize,
    required this.lines,
  });

  final String imagePath;
  final Size imageSize;
  final List<OcrTextLine> lines;

  bool get hasLines => lines.isNotEmpty;
}