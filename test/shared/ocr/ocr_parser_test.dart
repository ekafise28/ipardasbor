import 'package:flutter_test/flutter_test.dart';
import 'package:ipardasbor/shared/ocr/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/ocr_parser.dart';
import 'package:ipardasbor/shared/ocr/ocr_result.dart';

List<String> values(Map<OcrFieldType, List<OcrResult>> r, OcrFieldType t) =>
    r[t]!.map((e) => e.value).toList();

void main() {
  group('contoh dokumen asli', () {
    test('NIB: label di baris atas, angka di baris bawah', () {
      final r = OcrParser.parse([
        'NOMOR INDUK BERUSAHA (NIB)',
        '9120000792674',
      ]);
      expect(values(r, OcrFieldType.nib), ['9120000792674']);
      expect(r[OcrFieldType.nib]!.first.isClean, isTrue);
      expect(values(r, OcrFieldType.nku), isEmpty);
      expect(values(r, OcrFieldType.kbli), isEmpty);
    });

    test('NIB: label dan angka di baris yang sama', () {
      final r = OcrParser.parse([
        'PERIZINAN BERUSAHA BERBASIS RISIKO',
        'NOMOR INDUK BERUSAHA: 1305220047596',
      ]);
      expect(values(r, OcrFieldType.nib), ['1305220047596']);
      expect(r[OcrFieldType.nib]!.first.foundByLabel, isTrue);
    });

    test('NKU: label NKU: di baris yang sama', () {
      final r = OcrParser.parse(['NKU: 202409301125519904207']);
      expect(values(r, OcrFieldType.nku), ['202409301125519904207']);
      expect(r[OcrFieldType.nku]!.first.isClean, isTrue);
      expect(values(r, OcrFieldType.nib), isEmpty);
    });
  });

  group('koreksi dan format', () {
    test('huruf mirip angka dikoreksi di dalam deretan angka', () {
      final r = OcrParser.parse(['NIB: 9l2OOO0792674']);
      expect(values(r, OcrFieldType.nib), ['9120000792674']);
    });

    test('angka terpisah spasi digabung', () {
      final r = OcrParser.parse(['NIB 1305 2200 47596']);
      expect(values(r, OcrFieldType.nib), ['1305220047596']);
    });

    test('kata biasa tidak berubah jadi angka', () {
      final r = OcrParser.parse(['SOLO BASIS ZOOLOGI']);
      expect(values(r, OcrFieldType.nib), isEmpty);
      expect(values(r, OcrFieldType.nku), isEmpty);
      expect(values(r, OcrFieldType.kbli), isEmpty);
    });

    test('jam dan persen baterai tidak jadi kandidat', () {
      final r = OcrParser.parse(['Jam 12.30', 'Baterai 85%']);
      expect(values(r, OcrFieldType.nib), isEmpty);
      expect(values(r, OcrFieldType.nku), isEmpty);
    });
  });

  group('peringatan', () {
    test('NKU bukan 21 digit tetap ditawarkan dengan peringatan', () {
      final r = OcrParser.parse(['NKU: 20240930112551990420']); // 20 digit
      final hasil = r[OcrFieldType.nku]!;
      expect(hasil.single.value, '20240930112551990420');
      expect(hasil.single.warnings, contains(OcrWarning.unusualLength));
      expect(hasil.single.isClean, isFalse);
    });

    test('NKU tanpa label lewat cadangan ditandai noLabel', () {
      final r = OcrParser.parse(['202409301125519904207']);
      final hasil = r[OcrFieldType.nku]!.single;
      expect(hasil.value, '202409301125519904207');
      expect(hasil.foundByLabel, isFalse);
      expect(hasil.warnings, contains(OcrWarning.noLabel));
    });

    test('NIB tanpa label: hanya yang persis 13 digit', () {
      final r = OcrParser.parse(['1305220047596']);
      expect(values(r, OcrFieldType.nib), ['1305220047596']);
      expect(r[OcrFieldType.nib]!.single.warnings, [OcrWarning.noLabel]);
    });
  });

  group('KBLI', () {
    test('hanya KBLI dalam daftar yang diambil, noise diabaikan', () {
      final r = OcrParser.parse([
        'KBLI 55101',
        '56101 restoran',
        'Kode pos 40123',
      ]);
      expect(values(r, OcrFieldType.kbli), ['55101']);
    });

    test('dua KBLI berdampingan dipisah', () {
      final r = OcrParser.parse(['KBLI: 55101 55102']);
      expect(values(r, OcrFieldType.kbli), ['55101', '55102']);
    });

    test('KBLI berlabel tapi tidak di daftar tetap ditawarkan', () {
      final r = OcrParser.parse(['KBLI: 56101']);
      final hasil = r[OcrFieldType.kbli]!.single;
      expect(hasil.value, '56101');
      expect(hasil.warnings, contains(OcrWarning.notInAllowedList));
    });

    test('angka 5 digit tanpa label dan tidak di daftar diabaikan', () {
      final r = OcrParser.parse(['Kode pos 40123']);
      expect(values(r, OcrFieldType.kbli), isEmpty);
    });
  });

  group('semua target sekaligus', () {
    test('ketiganya terisi dari satu teks', () {
      final r = OcrParser.parse([
        'NIB: 1305220047596',
        'NKU: 202409301125519904207',
        'KBLI: 55101',
      ]);
      expect(values(r, OcrFieldType.nib), ['1305220047596']);
      expect(values(r, OcrFieldType.nku), ['202409301125519904207']);
      expect(values(r, OcrFieldType.kbli), ['55101']);
    });

    test('NIB berlabel tanpa nilai tidak mengambil NKU di baris bawahnya', () {
      final r = OcrParser.parse([
        'NIB:',
        'NKU: 202409301125519904207',
      ]);
      expect(values(r, OcrFieldType.nib), isEmpty);
      expect(values(r, OcrFieldType.nku), ['202409301125519904207']);
    });

    test('target tunggal hanya mengembalikan kunci itu', () {
      final r = OcrParser.parse(
        ['NIB: 1305220047596', 'NKU: 202409301125519904207'],
        targets: {OcrFieldType.nku},
      );
      expect(r.keys, [OcrFieldType.nku]);
      expect(values(r, OcrFieldType.nku), ['202409301125519904207']);
    });

    test('tidak ada angka sama sekali', () {
      final r = OcrParser.parse(['Halo dunia']);
      for (final t in OcrFieldType.values) {
        expect(r[t], isEmpty);
      }
    });
  });

  test('digitsOnly membuang semua selain angka tanpa koreksi huruf', () {
    expect(OcrParser.digitsOnly('NKU: 2024 0930-1125.5199 04207'),
        '202409301125519904207');
    expect(OcrParser.digitsOnly('NIB 12B'), '12');
  });
}