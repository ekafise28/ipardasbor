int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
String? _str(dynamic v) {
  final String s = '${v ?? ''}'.trim();
  return s.isEmpty ? null : s;
}

/// Satu jenis karyawan: jumlah sebelumnya dan yang terdampak.
class HotelKaryawan {
  const HotelKaryawan(this.label, this.sebelumnya, this.terdampak);
  final String label;
  final int sebelumnya;
  final int terdampak;
}

/// Satu hotel. Field detail (alamat, PIC, dst) hanya terisi dari endpoint
/// detail; daftar tidak mengirimnya, jadi semuanya nullable.
class HotelItem {
  const HotelItem({
    required this.id,
    required this.namaHotel,
    required this.provinsi,
    required this.kabKota,
    required this.karyawan,
    this.statusHotel,
    this.kamar = 0,
    this.meetingMice = 0,
    this.pelayananDapur = 0,
    this.alamat,
    this.kondisiDanDampak,
    this.picEmail,
    this.picWhatsapp,
    this.alatTransportasi,
  });

  final int id;
  final String namaHotel;
  final String provinsi;
  final String kabKota;
  final String? statusHotel;
  final List<HotelKaryawan> karyawan; // Tetap, PKWT, PKWTT, DW, Casual
  final int kamar;
  final int meetingMice;
  final int pelayananDapur;
  final String? alamat;
  final String? kondisiDanDampak;
  final String? picEmail;
  final String? picWhatsapp;
  final String? alatTransportasi;

  int get totalKaryawan => karyawan.fold(0, (int a, HotelKaryawan k) => a + k.sebelumnya);
  int get totalTerdampak => karyawan.fold(0, (int a, HotelKaryawan k) => a + k.terdampak);

  static const Map<String, String> _jenis = <String, String>{
    'tetap': 'Tetap',
    'pkwt': 'PKWT',
    'pkwtt': 'PKWTT',
    'dw': 'DW',
    'casual': 'Casual',
  };

  factory HotelItem.fromJson(Map<String, dynamic> j) {
    return HotelItem(
      id: _int(j['id']),
      namaHotel: _str(j['nama_hotel']) ?? '-',
      provinsi: _str(j['provinsi']) ?? '-',
      kabKota: _str(j['kab_kota']) ?? '-',
      statusHotel: _str(j['status_hotel']),
      karyawan: <HotelKaryawan>[
        for (final MapEntry<String, String> e in _jenis.entries)
          HotelKaryawan(
            e.value,
            _int(j['total_karyawan_${e.key}_sebelumnya']),
            _int(j['total_karyawan_${e.key}_terdampak']),
          ),
      ],
      kamar: _int(j['kapasitas_total_kamar']),
      meetingMice: _int(j['kapasitas_meeting_mice']),
      pelayananDapur: _int(j['kapasitas_pelayanan_dapur']),
      alamat: _str(j['alamat']),
      kondisiDanDampak: _str(j['kondisi_dan_dampak']),
      picEmail: _str(j['pic_email']),
      picWhatsapp: _str(j['pic_whatsapp']),
      alatTransportasi: _str(j['kapasitas_alat_transportasi']),
    );
  }
}