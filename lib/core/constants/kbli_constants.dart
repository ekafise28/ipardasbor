/// Konstanta KBLI yang dipakai bersama (validasi form dan parser OCR),
/// supaya hanya ada satu sumber daftar.
class KbliConstants {
  KbliConstants._();

  static const List<String> daftarDiizinkan = [
    '55105',
    '55104',
    '55103',
    '55102',
    '55101',
    '55106',
    '55203',
    '55201',
    '55202',
    '55204',
    '55300',
    '55209',
    '87303',
    '55909',
    '55901',
    '55110',
    '55120',
    '55130',
    '55191',
    '55192',
    '55193',
    '55194',
    '55199',
    '55900',
  ];

  static bool isDiizinkan(String kbli) => daftarDiizinkan.contains(kbli);
}