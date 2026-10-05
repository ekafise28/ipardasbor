class BidangUsahaOpsi {
  const BidangUsahaOpsi(this.slug, this.nama);

  final String slug;
  final String nama;

  static const List<BidangUsahaOpsi> daftar = <BidangUsahaOpsi>[
    BidangUsahaOpsi('transportasi-wisata', 'Jasa Transportasi Wisata'),
    BidangUsahaOpsi('akomodasi', 'Penyediaan Akomodasi'),
    BidangUsahaOpsi('makanan-minuman', 'Jasa Makanan dan Minuman'),
    BidangUsahaOpsi('kawasan-pariwisata', 'Kawasan Pariwisata'),
    BidangUsahaOpsi('konsultan-pariwisata', 'Jasa Konsultan Pariwisata'),
    BidangUsahaOpsi('perjalanan-wisata', 'Jasa Perjalanan Wisata'),
    BidangUsahaOpsi('informasi-pariwisata', 'Jasa Informasi Pariwisata'),
    BidangUsahaOpsi('pramuwisata', 'Jasa Pramuwisata'),
    BidangUsahaOpsi('mice-event', 'Penyelenggara MICE dan Event'),
    BidangUsahaOpsi('hiburan-rekreasi', 'Penyelenggaraan Kegiatan Hiburan dan Rekreasi'),
    BidangUsahaOpsi('daya-tarik-wisata', 'Daya Tarik Wisata'),
    BidangUsahaOpsi('wisata-tirta', 'Wisata Tirta'),
    BidangUsahaOpsi('spa', 'SPA'),
  ];

  /// Nama bidang dari slug, atau null kalau slug kosong/tidak dikenal.
  static String? namaDari(String? slug) {
    if (slug == null) return null;
    for (final BidangUsahaOpsi b in daftar) {
      if (b.slug == slug) return b.nama;
    }
    return null;
  }
}