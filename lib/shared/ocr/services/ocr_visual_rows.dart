import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ML Kit sering memecah label dan nilainya jadi blok terpisah walau
/// sebaris di layar. Gabungkan baris yang sejajar secara vertikal supaya
/// aturan "label di baris yang sama" pada parser tetap berlaku.
///
/// Dipakai bersama oleh scan foto ([OcrService]) dan deteksi live, supaya
/// keduanya memberi parser masukan yang sama.
List<String> ocrVisualRows(RecognizedText text) {
  return ocrVisualRowsFromLines([
    for (final block in text.blocks) ...block.lines,
  ]);
}

/// Sama seperti [ocrVisualRows], tapi dari daftar baris yang sudah
/// disaring (misalnya hanya yang berada di dalam bingkai kamera).
List<String> ocrVisualRowsFromLines(List<TextLine> lines) {
  final List<TextLine> all = [...lines];
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