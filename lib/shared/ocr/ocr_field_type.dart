/// Jenis angka yang bisa dideteksi OCR, beserta aturannya.
enum OcrFieldType {
  nib(
    displayName: 'NIB',
    labelPattern: r'(?:NOMOR\s*)?INDUK\s*BERUSAHA|\bNIB\b',
    expectedLength: 13,
    minLength: 8,
    maxLength: 20,
    fallbackMinLength: 13,
    fallbackMaxLength: 13,
  ),
  nku(
    displayName: 'NKU',
    labelPattern: r'\bNKU\b',
    expectedLength: 21,
    minLength: 10,
    maxLength: 30,
    fallbackMinLength: 15,
    fallbackMaxLength: 30,
  ),
  kbli(
    displayName: 'KBLI',
    labelPattern: r'\bKBLI\b',
    expectedLength: 5,
    minLength: 5,
    maxLength: 5,
    fallbackMinLength: 5,
    fallbackMaxLength: 5,
  );

  const OcrFieldType({
    required this.displayName,
    required this.labelPattern,
    required this.expectedLength,
    required this.minLength,
    required this.maxLength,
    required this.fallbackMinLength,
    required this.fallbackMaxLength,
  });

  final String displayName;

  /// Pola label (tidak peka huruf besar/kecil) yang dicari di teks.
  final String labelPattern;

  /// Panjang yang lazim. Bukan syarat penolakan, hanya dasar peringatan
  /// dan peringkat.
  final int expectedLength;

  /// Batas panjang kandidat kalau ditemukan dekat label.
  final int minLength;
  final int maxLength;

  /// Batas panjang kandidat kalau label tidak ditemukan (lebih ketat).
  final int fallbackMinLength;
  final int fallbackMaxLength;

  RegExp get labelRegex => RegExp(labelPattern, caseSensitive: false);

  bool acceptsLength(int length, {required bool byLabel}) {
    if (byLabel) return length >= minLength && length <= maxLength;
    return length >= fallbackMinLength && length <= fallbackMaxLength;
  }
}