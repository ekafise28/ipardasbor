/// Memformat bilangan bulat dengan pemisah ribuan titik.
/// Contoh: 1234567 -> "1.234.567".
String formatNumber(int value) {
  final bool negative = value < 0;
  final String source = value.abs().toString();
  final StringBuffer result = StringBuffer(negative ? '-' : '');

  for (int index = 0; index < source.length; index++) {
    final int remaining = source.length - index;

    result.write(source[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      result.write('.');
    }
  }

  return result.toString();
}

/// "350 m", "2,4 km", "12 km".
String formatJarak(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// Menambah https:// bila belum ada skema. Null/kosong menghasilkan null.
String? normalisasiUrl(String? url) {
  final String bersih = (url ?? '').trim();
  if (bersih.isEmpty) return null;
  if (bersih.startsWith('http://') || bersih.startsWith('https://')) {
    return bersih;
  }
  return 'https://$bersih';
}

/// Tautan Google Maps dari lat/lng. Menerima String maupun angka.
/// Null bila salah satunya kosong.
String? mapsUrl(Object? lat, Object? lng) {
  final String a = '${lat ?? ''}'.trim();
  final String b = '${lng ?? ''}'.trim();
  if (a.isEmpty || b.isEmpty) return null;
  return 'https://www.google.com/maps?q=$a,$b';
}

// ======================================================================
// Nomor telepon
// ======================================================================

/// Jenis nomor hasil [klasifikasiNomor].
enum JenisNomor {
  /// Seluler Indonesia (08... / 628...): bisa WhatsApp dan telepon.
  seluler,

  /// Telepon tetap atau nomor layanan (kode area, 1500..., 0800...).
  telepon,

  /// Bukan nomor yang masuk akal: tampil sebagai teks biasa.
  bukanNomor,
}

/// Hasil klasifikasi satu nomor beserta tautan aksinya.
class NomorTelepon {
  const NomorTelepon._(this.jenis, this.waUrl, this.telUrl);

  static const NomorTelepon bukanNomor = NomorTelepon._(
    JenisNomor.bukanNomor,
    null,
    null,
  );

  final JenisNomor jenis;

  /// "https://wa.me/628123..." - hanya untuk [JenisNomor.seluler].
  final String? waUrl;

  /// "tel:08123..." - null untuk [JenisNomor.bukanNomor].
  final String? telUrl;
}

/// Mengklasifikasikan nomor telepon.
///
/// Spasi, strip, titik, dan kurung dibuang dulu; awalan "+" dikenali.
///
/// - `08...` / `628...` (10-14 digit)      -> seluler (WhatsApp + telepon)
/// - `8...` tanpa nol (9-12 digit)         -> dianggap seluler
/// - `0...` selain 08, `62...` selain 628 -> telepon tetap (kode area)
/// - `1500...`, `0800...`, dsb (7-15 digit)-> telepon
/// - berisi huruf/simbol, terlalu pendek/panjang, atau semua digit sama
///                                         -> bukan nomor (tanpa aksi)
NomorTelepon klasifikasiNomor(String? raw) {
  final String teks = (raw ?? '').trim();
  if (teks.isEmpty) return NomorTelepon.bukanNomor;

  final bool pakaiPlus = teks.startsWith('+');
  final String d = teks
      .replaceAll(RegExp(r'[\s\-.()]'), '')
      .replaceFirst(RegExp(r'^\+'), '');

  if (!RegExp(r'^\d+$').hasMatch(d)) return NomorTelepon.bukanNomor;
  if (RegExp(r'^(\d)\1*$').hasMatch(d)) return NomorTelepon.bukanNomor;

  // Bentuk nasional (awalan 0).
  final String n;
  if (d.startsWith('62')) {
    n = '0${d.substring(2)}';
  } else if (!pakaiPlus && d.startsWith('8') && d.length >= 9 && d.length <= 12) {
    n = '0$d'; // nol di depan hilang (mis. karena Excel).
  } else {
    n = d;
  }

  // 0800 adalah nomor layanan bebas pulsa, bukan seluler.
  if (n.startsWith('08') &&
      !n.startsWith('0800') &&
      n.length >= 10 &&
      n.length <= 14) {
    return NomorTelepon._(
      JenisNomor.seluler,
      'https://wa.me/62${n.substring(1)}',
      'tel:$n',
    );
  }

  // Minimal 7 digit supaya nomor layanan seperti "1500123" tetap dikenali.
  if (n.length >= 7 && n.length <= 15) {
    final bool asing = pakaiPlus && !d.startsWith('62');
    return NomorTelepon._(
      JenisNomor.telepon,
      null,
      asing ? 'tel:+$d' : 'tel:$n',
    );
  }

  return NomorTelepon.bukanNomor;
}

// ======================================================================
// Tanggal
// ======================================================================

const List<String> _bulan = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "5 Mar 2026". Null bila [d] null.
String? formatTanggal(DateTime? d) {
  if (d == null) return null;
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

/// "5 Mar 2026, 09:05". Null bila [d] null.
String? formatTanggalJam(DateTime? d) {
  if (d == null) return null;
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${formatTanggal(d)}, ${dua(d.hour)}:${dua(d.minute)}';
}