/// Daftar jenis produk akomodasi (kode KBLI 5 digit -> label), dipakai
/// sebagai satu-satunya sumber untuk dropdown "Jenis Produk Akomodasi" -
/// baik di Tahap 1 (OssFormPage) maupun Tahap 2 per item (AkomodasiItemCard).
/// Jangan duplikat daftar ini di tempat lain - kalau daftarnya berubah,
/// cukup edit di sini.
class JenisProdukAkomodasi {
  const JenisProdukAkomodasi._();

  static const List<MapEntry<String, String>> options = [
    MapEntry('55105', 'Hotel Bintang 1'),
    MapEntry('55104', 'Hotel Bintang 2'),
    MapEntry('55103', 'Hotel Bintang 3'),
    MapEntry('55102', 'Hotel Bintang 4'),
    MapEntry('55101', 'Hotel Bintang 5'),
    MapEntry('55106', 'Hotel Non Bintang'),
    MapEntry('55203', 'Vila'),
    MapEntry('55201', 'Homestay'),
    MapEntry('55202', 'Youth Hostel'),
    MapEntry('55204', 'Apartemen Hotel'),
    MapEntry('55300', 'Bumi Perkemahan'),
    MapEntry('55209', 'Akomodasi Jangka Pendek Lainnya'),
    MapEntry('87303', 'Senior Living'),
    MapEntry('55909', 'Akomodasi Lainnya'),
  ];
}