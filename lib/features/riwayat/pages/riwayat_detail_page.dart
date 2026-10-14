import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';

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
                color: _warnaJenisRiwayat(detail.sumberData),
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
              Baris('No. HP', detail.noHp),
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
              Baris('Nomor NIB', detail.nib),
              Baris('NKU', detail.idProyek),
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
                ),
                Baris('Keterangan Validasi', detail.pesanValidasi),
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
              Baris('Alamat', detail.alamat),
              Baris(
                'Koordinat',
                _formatKoordinat(detail),
                url: mapsUrl(detail.latitude, detail.longitude),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.fact_check_outlined,
            title: 'Hasil Pengawasan',
            rows: <Baris>[
              Baris('Petugas', detail.petugas),
              Baris('Status Pengawasan', detail.statusPengawasan),
              Baris(
                'Status Ketidaksesuaian',
                detail.statusKetidaksesuaian.isEmpty
                    ? null
                    : detail.statusKetidaksesuaian.join(', '),
              ),
              Baris(
                'Keterangan Ketidaksesuaian',
                detail.keteranganKetidaksesuaian,
              ),
              Baris('Keterangan', detail.keterangan),
              Baris('Catatan Petugas', detail.catatanPetugas),
              Baris(
                'Tanggal Pengawasan',
                formatTanggal(detail.tanggalPengawasan),
              ),
              Baris('Dibuat Pada', formatTanggalJam(detail.createdAt)),
              Baris('Diperbarui Pada', formatTanggalJam(detail.updatedAt)),
            ],
          ),
          const SizedBox(height: 12),
          _FotoSection(foto: detail.foto),
          const SizedBox(height: 12),
          _OtaSection(ota: detail.ota),
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
}

/// Kartu section khusus foto dokumentasi, tampil grid 3 kolom.
/// Tap foto membuka full-screen viewer dengan zoom.
class _FotoSection extends StatelessWidget {
  const _FotoSection({required this.foto});

  final List<RiwayatDetailFoto> foto;

  @override
  Widget build(BuildContext context) {
    if (foto.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: Icons.photo_library_outlined,
      title: 'Foto Dokumentasi',
      count: foto.length,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: foto.length,
        itemBuilder: (BuildContext context, int index) {
          final RiwayatDetailFoto item = foto[index];

          return GestureDetector(
            onTap: () => _bukaViewer(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black12,
                child: Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _bukaViewer(BuildContext context, int indexAwal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FotoViewerPage(foto: foto, indexAwal: indexAwal),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Halaman full-screen untuk melihat foto satu per satu, bisa swipe
/// antar foto dan pinch-to-zoom.
class _FotoViewerPage extends StatefulWidget {
  const _FotoViewerPage({required this.foto, required this.indexAwal});

  final List<RiwayatDetailFoto> foto;
  final int indexAwal;

  @override
  State<_FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<_FotoViewerPage> {
  late final PageController _pageController = PageController(
    initialPage: widget.indexAwal,
  );
  late int _indexSaatIni = widget.indexAwal;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RiwayatDetailFoto item = widget.foto[_indexSaatIni];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_indexSaatIni + 1} / ${widget.foto.length}'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.foto.length,
              onPageChanged: (int index) {
                setState(() => _indexSaatIni = index);
              },
              itemBuilder: (BuildContext context, int index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.foto[index].url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if ((item.keterangan ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item.keterangan!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu section untuk daftar listing OTA terkait hasil pengawasan.
/// Tiap listing ditampilkan sebagai satu kartu kecil dengan link buka URL.
class _OtaSection extends StatelessWidget {
  const _OtaSection({required this.ota});

  final List<RiwayatDetailOta> ota;

  @override
  Widget build(BuildContext context) {
    if (ota.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: Icons.travel_explore_outlined,
      title: 'Listing OTA',
      count: ota.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < ota.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 20),
            _OtaTile(item: ota[i]),
          ],
        ],
      ),
    );
  }
}

class _OtaTile extends StatelessWidget {
  const _OtaTile({required this.item});

  final RiwayatDetailOta item;

  Color _warnaStatus() {
    switch ((item.statusListing ?? '').toUpperCase()) {
      case 'AKTIF':
        return Colors.green;
      case 'TIDAK AKTIF':
      case 'NONAKTIF':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                item.namaListing ?? '-',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            if ((item.statusListing ?? '').trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _warnaStatus().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusListing!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _warnaStatus(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if ((item.namaPlatform ?? '').trim().isNotEmpty)
          Text(
            item.namaPlatform!,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: <Widget>[
            if (item.hargaTerendah != null)
              _InfoKecil(
                icon: Icons.sell_outlined,
                text: 'Rp ${item.hargaTerendah!.toStringAsFixed(0)}',
              ),
            if (item.rating != null)
              _InfoKecil(
                icon: Icons.star_outline_rounded,
                text: '${item.rating} (${item.jumlahUlasan ?? 0} ulasan)',
              ),
            if (item.tanggalDitemukan != null)
              _InfoKecil(
                icon: Icons.calendar_today_outlined,
                text:
                    'Ditemukan ${formatTanggal(item.tanggalDitemukan)}',
              ),
          ],
        ),
        if ((item.catatan ?? '').trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            item.catatan!,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
        if ((item.urlListing ?? '').trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          if ((item.urlListing ?? '').trim().isNotEmpty ||
              (item.mapsUrl ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if ((item.urlListing ?? '').trim().isNotEmpty)
                  LinkButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'Buka Listing',
                    onTap: () => bukaTautan(context, item.urlListing)
                  ),
                if ((item.mapsUrl ?? '').trim().isNotEmpty)
                  LinkButton(
                    icon: Icons.map_outlined,
                    label: 'Lihat Peta',
                    onTap: () => bukaTautan(context, item.mapsUrl),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _InfoKecil extends StatelessWidget {
  const _InfoKecil({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: AppTheme.textSecondary(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

Color _warnaJenisRiwayat(String jenis) {
  switch (jenis.toUpperCase()) {
    case 'OSS':
      return AppTheme.menuOss;
    case 'OTA':
      return AppTheme.menuOta;
    case 'NON OSS':
    default:
      return AppTheme.menuNonOss;
  }
}
