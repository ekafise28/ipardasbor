import 'ocr_field_type.dart';

enum OcrWarning {
  /// Jumlah digit berbeda dari yang lazim.
  unusualLength,

  /// KBLI tidak ada di daftar yang diizinkan.
  notInAllowedList,

  /// Ditemukan tanpa label di dekatnya.
  noLabel,
}

/// Satu kandidat nilai hasil OCR untuk satu jenis field.
class OcrResult {
  const OcrResult({
    required this.type,
    required this.value,
    required this.foundByLabel,
    this.warnings = const [],
  });

  final OcrFieldType type;
  final String value;
  final bool foundByLabel;
  final List<OcrWarning> warnings;

  int get digitCount => value.length;
  bool get hasWarning => warnings.isNotEmpty;

  /// Tanpa peringatan sama sekali. Hanya hasil "bersih" yang layak
  /// tercentang otomatis di bottom sheet.
  bool get isClean => warnings.isEmpty;

  List<String> get warningMessages => warnings.map((w) {
        switch (w) {
          case OcrWarning.unusualLength:
            return 'Jumlah digit tidak biasa ($digitCount digit, '
                'biasanya ${type.expectedLength}), periksa lagi.';
          case OcrWarning.notInAllowedList:
            return 'KBLI tidak ada dalam daftar yang diizinkan.';
          case OcrWarning.noLabel:
            return 'Ditemukan tanpa label, pastikan ini benar.';
        }
      }).toList();

  @override
  String toString() =>
      'OcrResult(${type.displayName}: $value, label: $foundByLabel, $warnings)';
}