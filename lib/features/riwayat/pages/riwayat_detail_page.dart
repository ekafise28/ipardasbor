import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exception.dart';
import '../models/riwayat_detail.dart';
import '../services/riwayat_service.dart';

/// Halaman detail penuh untuk satu item riwayat pengawasan.
///
/// Mengambil data lengkap dari endpoint detail (bukan cuma data yang
/// sudah ada di list), lalu menampilkannya dikelompokkan per kategori:
/// Informasi Usaha, Legalitas, Lokasi, dan Hasil Pengawasan.
class RiwayatDetailPage extends StatefulWidget {
  const RiwayatDetailPage({super.key, required this.id});

  final int id;

  @override
  State<RiwayatDetailPage> createState() => _RiwayatDetailPageState();
}

class _RiwayatDetailPageState extends State<RiwayatDetailPage> {
  final RiwayatService _service = RiwayatService();

  bool _loading = true;
  String? _pesanError;
  RiwayatDetail? _detail;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _pesanError = null;
    });

    try {
      final RiwayatDetail hasil = await _service.fetchDetail(widget.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = hasil;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _pesanError = e.message;
      });
    } catch (e, stack) {
      debugPrint('RIWAYAT DETAIL ERROR: $e');
      debugPrint('$stack');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _pesanError = 'Terjadi kesalahan yang tidak terduga.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        title: const Text('Detail Riwayat'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pesanError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_pesanError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _muat, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final RiwayatDetail detail = _detail!;

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _HeaderCard(detail: detail),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.storefront_outlined,
            title: 'Informasi Usaha',
            rows: <_Baris>[
              _Baris('Sumber Data', detail.sumberData),
              _Baris('Nama Brand', detail.namaBrand),
              _Baris('Nama Pemilik', detail.namaPemilik),
              _Baris('Jenis Produk', detail.jenisProduk),
              _Baris('KBLI', detail.kbli),
              _Baris('Deskripsi KBLI', detail.kbliDesc),
              _Baris('Website', detail.website),
              _Baris('No. HP', detail.noHp),
              _Baris('Email', detail.email),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.verified_outlined,
            title: 'Legalitas',
            rows: <_Baris>[
              _Baris('Status Verifikasi', detail.statusVerifikasi),
              _Baris('Memiliki NIB', detail.memilikiNib),
              _Baris('Nomor NIB', detail.nib),
              _Baris('NPWPD', detail.npwpd),
              _Baris('Terdaftar OTA', detail.terdaftarOta),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.place_outlined,
            title: 'Lokasi',
            rows: <_Baris>[
              _Baris('Provinsi', detail.wilayah.provinsi),
              _Baris('Kabupaten/Kota', detail.wilayah.kabupaten),
              _Baris('Kecamatan', detail.wilayah.kecamatan),
              _Baris('Kelurahan', detail.wilayah.kelurahan),
              _Baris('Alamat', detail.alamat),
              _Baris('Koordinat', _formatKoordinat(detail)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.fact_check_outlined,
            title: 'Hasil Pengawasan',
            rows: <_Baris>[
              _Baris('Petugas', detail.petugas),
              _Baris('Status Pengawasan', detail.statusPengawasan),
              _Baris('Status Ketidaksesuaian', detail.statusKetidaksesuaian),
              _Baris('Keterangan', detail.keterangan),
              _Baris('Catatan Petugas', detail.catatanPetugas),
              _Baris('Tanggal Pengawasan', _formatTanggal(detail.tanggalPengawasan)),
              _Baris('Dibuat Pada', _formatTanggalJam(detail.createdAt)),
              _Baris('Diperbarui Pada', _formatTanggalJam(detail.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  static String? _formatKoordinat(RiwayatDetail detail) {
    if (detail.latitude == null || detail.longitude == null) {
      return null;
    }

    return '${detail.latitude}, ${detail.longitude}';
  }

  static String? _formatTanggal(DateTime? tanggal) {
    if (tanggal == null) {
      return null;
    }

    const List<String> bulan = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  static String? _formatTanggalJam(DateTime? tanggal) {
    final String? tanggalLabel = _formatTanggal(tanggal);

    if (tanggalLabel == null || tanggal == null) {
      return null;
    }

    final String jam = tanggal.hour.toString().padLeft(2, '0');
    final String menit = tanggal.minute.toString().padLeft(2, '0');

    return '$tanggalLabel, $jam:$menit';
  }
}

/// Kartu ringkasan di paling atas: nama usaha + badge jenis & status.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail});

  final RiwayatDetail detail;

  Color _warnaJenis() {
    switch (detail.sumberData.toUpperCase()) {
      case 'OSS':
        return AppTheme.menuOss;
      case 'OTA':
        return AppTheme.menuOta;
      case 'NON OSS':
      default:
        return AppTheme.menuNonOss;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool selesai = detail.statusVerifikasi.toUpperCase() == 'SELESAI';
    final Color warnaStatus = selesai ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Chip(text: detail.sumberData, color: _warnaJenis()),
                const SizedBox(width: 8),
                _Chip(text: detail.statusVerifikasi, color: warnaStatus),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail.namaUsaha,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Satu pasangan label-nilai yang akan dirender oleh [_SectionCard].
///
/// Baris dengan nilai null/kosong otomatis disembunyikan supaya section
/// tidak penuh tanda "-" untuk field yang memang tidak diisi.
class _Baris {
  const _Baris(this.label, this.value);

  final String label;
  final String? value;

  bool get adaIsi => value != null && value!.trim().isNotEmpty;
}

/// Kartu section untuk satu kategori field, dengan header ikon + judul.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_Baris> rows;

  @override
  Widget build(BuildContext context) {
    final List<_Baris> rowsTerisi = rows.where((_Baris r) => r.adaIsi).toList();

    if (rowsTerisi.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: AppTheme.menuDashboard),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final _Baris baris in rowsTerisi)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 130,
                      child: Text(
                        baris.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        baris.value!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}