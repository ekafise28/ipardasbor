import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/form/status_ketidaksesuaian_selector.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exception.dart';
import '../models/riwayat_detail.dart';
import '../services/riwayat_service.dart';

import '../../../shared/widgets/detail_cards.dart';

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
    } catch (_) {
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
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Riwayat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          if (_detail != null)
            IconButton(
              tooltip: 'Bagikan ringlanjutkasan',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _bagikan(_detail!),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pesanError != null) {
      return ConnectionErrorState(
        title: 'Detail gagal dimuat',
        message: _pesanError!,
        onRetry: _muat,
      );
    }

    final RiwayatDetail detail = _detail!;
    final bool adaKetKetidaksesuaian = (detail.keteranganKetidaksesuaian ?? '')
        .trim()
        .isNotEmpty;

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          StatusHeaderCard(
            title: detail.namaUsaha,
            badges: <StatusBadge>[
              StatusBadge(
                text: detail.sumberData,
                color: AppTheme.warnaJenis(detail.sumberData),
              ),
              StatusBadge(
                text: detail.statusVerifikasi,
                color: detail.statusVerifikasi.toUpperCase() == 'SELESAI'
                    ? Colors.green
                    : Colors.orange,
              ),
              if (detail.ossTidakValid)
                const StatusBadge(text: 'Data Tidak Valid', color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icons.storefront_outlined,
            title: 'Informasi Usaha',
            rows: <Baris>[
              Baris('Sumber Data', detail.sumberData),
              Baris('Nama Brand', detail.namaBrand),
              Baris('Nama Pemilik', detail.namaPemilik),
              Baris('Jenis Produk', detail.jenisProduk),
              Baris('KBLI', detail.kbli),
              Baris('Deskripsi KBLI', detail.kbliDesc),
              Baris(
                'Website',
                detail.website,
                url: normalisasiUrl(detail.website),
              ),
              Baris.telepon('No. HP', detail.noHp),
              Baris('Email', detail.email),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.verified_outlined,
            title: 'Legalitas',
            rows: <Baris>[
              Baris('Status Verifikasi', detail.statusVerifikasi),
              Baris('Memiliki NIB', detail.memilikiNib),
              Baris('Nomor NIB', detail.nib, salin: true),
              Baris('NKU', detail.idProyek, salin: true),
              Baris('NPWPD', detail.npwpd),
              Baris('Terdaftar OTA', detail.terdaftarOta),
              if (detail.sumberData.toUpperCase() == 'OSS') ...<Baris>[
                Baris(
                  'Hasil Validasi OSS',
                  detail.hasilValidasi == 'TIDAK_VALID'
                      ? 'Tidak Valid'
                      : detail.hasilValidasi == 'VALID'
                      ? 'Valid'
                      : null,
                  sorot: detail.ossTidakValid,
                ),
                Baris(
                  'Keterangan Validasi',
                  detail.pesanValidasi,
                  sorot: detail.ossTidakValid,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.place_outlined,
            title: 'Lokasi',
            rows: <Baris>[
              Baris('Provinsi', detail.wilayah.provinsi),
              Baris('Kabupaten/Kota', detail.wilayah.kabupaten),
              Baris('Kecamatan', detail.wilayah.kecamatan),
              Baris('Kelurahan', detail.wilayah.kelurahan),
              Baris('Alamat', detail.alamat, salin: true),
              Baris.koordinat(detail.latitude, detail.longitude),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.fact_check_outlined,
            title: 'Hasil Pengawasan',
            rows: <Baris>[
              Baris('Petugas', detail.petugas),
              Baris('Status Pengawasan', detail.statusPengawasan),
              Baris.chips(
                'Status Ketidaksesuaian',
                detail.statusKetidaksesuaian
                    .map(StatusKetidaksesuaianSelector.labelDari)
                    .toList(),
              ),
              if (adaKetKetidaksesuaian)
                Baris(
                  'Keterangan Ketidaksesuaian',
                  detail.keteranganKetidaksesuaian,
                )
              else
                Baris('Keterangan', detail.keterangan),
              Baris('Catatan Petugas', detail.catatanPetugas),
              Baris(
                'Tanggal Pengawasan',
                formatTanggal(detail.tanggalPengawasan),
              ),
              Baris(
                'Dibuat Pada',
                formatTanggalJam(detail.createdAt?.toLocal()),
              ),
              Baris(
                'Diperbarui Pada',
                formatTanggalJam(detail.updatedAt?.toLocal()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FotoGallerySection(
            foto: <FotoItem>[
              for (final RiwayatDetailFoto f in detail.foto)
                FotoItem.url(f.url, keterangan: f.keterangan),
            ],
          ),
          const SizedBox(height: 12),
          OtaListSection(items: detail.ota.map(_itemOta).toList()),
        ],
      ),
    );
  }

  /// Ringkasan teks untuk dibagikan (mis. ke WhatsApp). Hanya baris yang
  /// terisi. No. HP, email, dan foto sengaja tidak ikut.
  static String _ringkasan(RiwayatDetail d) {
    final List<String> baris = <String>['*Hasil Pengawasan: ${d.namaUsaha}*'];

    void tambah(String label, String? isi) {
      final String bersih = (isi ?? '').trim();
      if (bersih.isNotEmpty) baris.add('$label: $bersih');
    }

    final String status = d.statusVerifikasi.toUpperCase() == 'SELESAI'
        ? 'Selesai'
        : d.statusVerifikasi;
    tambah(
      'Jenis',
      <String>[
        d.sumberData,
        status,
      ].where((String s) => s.trim().isNotEmpty && s != '-').join(' · '),
    );

    final String? validasi = d.hasilValidasi == 'TIDAK_VALID'
        ? 'Tidak valid'
        : d.hasilValidasi == 'VALID'
        ? 'Valid'
        : null;
    final String ketidaksesuaian = d.statusKetidaksesuaian
        .map(StatusKetidaksesuaianSelector.labelDari)
        .join(', ');
    tambah(
      'Hasil',
      validasi == null
          ? ketidaksesuaian
          : (ketidaksesuaian.isEmpty
                ? validasi
                : '$validasi ($ketidaksesuaian)'),
    );
    if (d.ossTidakValid) tambah('Alasan', d.pesanValidasi);

    tambah('NIB', d.nib);
    tambah('NKU', d.idProyek);

    final String wilayah = d.wilayah.gabungan == '-' ? '' : d.wilayah.gabungan;
    tambah(
      'Alamat',
      <String>[
        (d.alamat ?? '').trim(),
        wilayah,
      ].where((String s) => s.isNotEmpty).join(', '),
    );
    tambah('Lokasi', mapsUrl(d.latitude, d.longitude));

    tambah(
      'Petugas',
      <String>[
        (d.petugas ?? '').trim(),
        formatTanggal(d.tanggalPengawasan) ?? '',
      ].where((String s) => s.isNotEmpty).join(' · '),
    );

    if ((d.keteranganKetidaksesuaian ?? '').trim().isNotEmpty) {
      tambah('Keterangan ketidaksesuaian', d.keteranganKetidaksesuaian);
    } else {
      tambah('Keterangan', d.keterangan);
    }
    tambah('Catatan', d.catatanPetugas);

    return baris.join('\n');
  }

  Future<void> _bagikan(RiwayatDetail d) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _ringkasan(d),
          subject: 'Hasil Pengawasan: ${d.namaUsaha}',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      tampilkanPesan(
        context,
        'Tidak dapat membuka menu bagikan.',
        sukses: false,
      );
    }
  }

  /// Judul kartu OTA: nama listing, atau nama platform kalau listing tidak
  /// punya nama (mis. data dari form Non-OSS yang hanya mengisi platform
  /// dan URL).
  static OtaListingItem _itemOta(RiwayatDetailOta o) {
    final bool adaListing = (o.namaListing ?? '').trim().isNotEmpty;
    final bool adaPlatform = (o.namaPlatform ?? '').trim().isNotEmpty;
    final bool adaUrl = (o.urlListing ?? '').trim().isNotEmpty;

    return OtaListingItem(
      judul: adaListing
          ? o.namaListing!
          : (adaPlatform ? o.namaPlatform! : '-'),
      platform: adaListing ? o.namaPlatform : null,
      status: o.statusListing,
      hargaTerendah: o.hargaTerendah,
      rating: o.rating?.toString(),
      jumlahUlasan: o.jumlahUlasan,
      tanggalDitemukan: o.tanggalDitemukan == null
          ? null
          : formatTanggal(o.tanggalDitemukan),
      catatan: o.catatan,
      urls: <String>[if (adaUrl) o.urlListing!],
      mapsUrl: o.mapsUrl,
    );
  }
}
