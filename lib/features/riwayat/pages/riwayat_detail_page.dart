import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exception.dart';
import '../models/riwayat_detail.dart';
import '../services/riwayat_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static String? _mapsUrl(RiwayatDetail detail) {
    if (detail.latitude == null || detail.longitude == null) {
      return null;
    }

    return 'https://www.google.com/maps?q=${detail.latitude},${detail.longitude}';
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
      appBar: AppBar(title: const Text('Detail Riwayat')),
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
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
              _Baris(
                'Website',
                detail.website,
                url: _normalisasiUrl(detail.website),
              ),
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
              _Baris(
                'Koordinat',
                _formatKoordinat(detail),
                url: _mapsUrl(detail),
              ),
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
              _Baris(
                'Tanggal Pengawasan',
                _formatTanggal(detail.tanggalPengawasan),
              ),
              _Baris('Dibuat Pada', _formatTanggalJam(detail.createdAt)),
              _Baris('Diperbarui Pada', _formatTanggalJam(detail.updatedAt)),
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

  static String? _formatTanggal(DateTime? tanggal) {
    if (tanggal == null) {
      return null;
    }

    const List<String> bulan = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Satu pasangan label-nilai yang akan dirender oleh [_SectionCard].
///
/// Baris dengan nilai null/kosong otomatis disembunyikan supaya section
/// tidak penuh tanda "-" untuk field yang memang tidak diisi.
class _Baris {
  const _Baris(this.label, this.value, {this.url});

  final String label;
  final String? value;

  /// Kalau diisi, baris ini dirender sebagai tautan yang bisa ditekan
  /// untuk membuka [url] (bukan sekadar teks biasa).
  final String? url;

  bool get adaIsi => value != null && value!.trim().isNotEmpty;
  bool get bisaDibuka => url != null && url!.trim().isNotEmpty;
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
                      child: baris.bisaDibuka
                          ? InkWell(
                              onTap: () => _bukaTautan(context, baris.url!),
                              child: Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      baris.value!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            )
                          : Text(
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

/// Kartu section khusus foto dokumentasi, tampil grid 3 kolom.
/// Tap foto membuka full-screen viewer dengan zoom.
class _FotoSection extends StatelessWidget {
  const _FotoSection({required this.foto});

  final List<RiwayatDetailFoto> foto;

  @override
  Widget build(BuildContext context) {
    if (foto.isEmpty) {
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
                Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: AppTheme.menuDashboard,
                ),
                const SizedBox(width: 8),
                Text(
                  'Foto Dokumentasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${foto.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
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
                        errorBuilder: (_, __, ___) => const Center(
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
          ],
        ),
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
                      errorBuilder: (_, __, ___) => const Icon(
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
    if (ota.isEmpty) {
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
                Icon(
                  Icons.travel_explore_outlined,
                  size: 18,
                  color: AppTheme.menuDashboard,
                ),
                const SizedBox(width: 8),
                Text(
                  'Listing OTA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${ota.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < ota.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 20),
              _OtaTile(item: ota[i]),
            ],
          ],
        ),
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
                  color: _warnaStatus().withOpacity(0.12),
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
                    'Ditemukan ${_formatTanggalSingkat(item.tanggalDitemukan!)}',
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
                  _LinkButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'Buka Listing',
                    onTap: () => _bukaUrl(context, item.urlListing!),
                  ),
                if ((item.mapsUrl ?? '').trim().isNotEmpty)
                  _LinkButton(
                    icon: Icons.map_outlined,
                    label: 'Lihat Peta',
                    onTap: () => _bukaUrl(context, item.mapsUrl!),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _bukaUrl(BuildContext context, String url) async {
    final Uri uri = Uri.tryParse(url) ?? Uri();
    debugPrint('DEBUG URL asli: $url');
    debugPrint('DEBUG hasil parse Uri: $uri');
    final bool bisaLaunch = await canLaunchUrl(uri);
    debugPrint('DEBUG canLaunchUrl: $bisaLaunch');

    final bool berhasil = bisaLaunch
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : false;

    if (!berhasil && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  static String _formatTanggalSingkat(DateTime tanggal) {
    const List<String> bulan = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
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

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.menuDashboard,
        side: BorderSide(color: AppTheme.menuDashboard.withOpacity(0.4)),
      ),
    );
  }
}

Future<void> _bukaTautan(BuildContext context, String url) async {
  final Uri? uri = Uri.tryParse(url);

  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tautan tidak valid.')));
    }
    return;
  }

  final bool berhasil = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!berhasil && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka tautan.')),
    );
  }
}

String? _normalisasiUrl(String? website) {
  if (website == null || website.trim().isEmpty) {
    return null;
  }

  final String bersih = website.trim();

  if (bersih.startsWith('http://') || bersih.startsWith('https://')) {
    return bersih;
  }

  return 'https://$bersih';
}
