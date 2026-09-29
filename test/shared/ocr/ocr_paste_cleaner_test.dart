import 'package:flutter_test/flutter_test.dart';
import 'package:ipardasbor/shared/ocr/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/ocr_paste_cleaner.dart';
import 'package:ipardasbor/shared/ocr/ocr_result.dart';

List<String> values(String text, OcrFieldType type) =>
    OcrPasteCleaner.clean(text, type).map((e) => e.value).toList();

void main() {
  group('teks murni angka', () {
    test('NIB dengan spasi digabung', () {
      final r = OcrPasteCleaner.clean('1305 2200 47596', OcrFieldType.nib);
      expect(r.single.value, '1305220047596');
      expect(r.single.isClean, isTrue);
    });

    test('NKU dengan titik dan strip dibersihkan', () {
      expect(
        values('2024.0930-1125.5199 04207', OcrFieldType.nku),
        ['202409301125519904207'],
      );
    });

    test('spasi khusus (NBSP) dan karakter tak terlihat ditangani', () {
      expect(
        values('\u200B1305\u00A02200\u00A047596 ', OcrFieldType.nib),
        ['1305220047596'],
      );
    });

    test('jumlah digit tidak biasa tetap ditempel dengan peringatan', () {
      final r = OcrPasteCleaner.clean('12345', OcrFieldType.nib);
      expect(r.single.value, '12345');
      expect(r.single.warnings, contains(OcrWarning.unusualLength));
    });

    test('KBLI tunggal di luar daftar tetap ditempel dengan peringatan', () {
      final r = OcrPasteCleaner.clean('56101', OcrFieldType.kbli);
      expect(r.single.value, '56101');
      expect(r.single.warnings, contains(OcrWarning.notInAllowedList));
    });
  });

  group('teks campuran', () {
    test('NKU dengan label', () {
      expect(
        values('NKU: 202409301125519904207', OcrFieldType.nku),
        ['202409301125519904207'],
      );
    });

    test('NIB dengan label panjang', () {
      expect(
        values('Nomor Induk Berusaha: 1305220047596', OcrFieldType.nib),
        ['1305220047596'],
      );
    });

    test('beberapa KBLI dipisah spasi tidak digabung', () {
      expect(values('55101 55102', OcrFieldType.kbli), ['55101', '55102']);
    });

    test('dua NIB di baris berbeda menjadi dua kandidat', () {
      expect(
        values('1305220047596\n9120000792674', OcrFieldType.nib),
        ['1305220047596', '9120000792674'],
      );
    });
  });

  group('tidak ada hasil', () {
    test('kosong', () {
      expect(values('   ', OcrFieldType.nib), isEmpty);
    });

    test('tanpa angka', () {
      expect(values('halo dunia', OcrFieldType.nku), isEmpty);
    });
  });
}