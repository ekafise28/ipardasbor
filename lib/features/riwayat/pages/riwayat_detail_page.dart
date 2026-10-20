import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/shared/screenshot/screenshot_service.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/form/status_ketidaksesuaian_selector.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart';
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
  /// Jarak vertikal antar blok. Satu nilai supaya konsisten.
  static const double _jarak = 14;

  /// Posisi gulir (px) saat judul AppBar berganti jadi nama usaha.
  static const double _batasJudulNama = 90;

  final ValueNotifier<Key?> _disorot = ValueNotifier<Key?>(null);

  final RiwayatService _service = RiwayatService();
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _judulNama = ValueNotifier<bool>(false);

  // Kunci per section untuk chip lompat. Memakai SingleChildScrollView
  // (bukan ListView) supaya semua section sudah terbangun dan kuncinya
  // selalu punya context.
  final GlobalKey _kUsaha = GlobalKey();
  final GlobalKey _kLegalitas = GlobalKey();
  final GlobalKey _kLokasi = GlobalKey();
  final GlobalKey _kHasil = GlobalKey();
  final GlobalKey _kFoto = GlobalKey();
  final GlobalKey _kOta = GlobalKey();

  bool _loading = true;
  String? _pesanError;
  RiwayatDetail? _detail;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _muat();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _judulNama.dispose();
    _disorot.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool lewat = _scroll.hasClients && _scroll.offset > _batasJudulNama;
    if (_judulNama.value != lewat) {
      _judulNama.value = lewat;
    }
  }

  /// Memuat detail. Dengan [senyap] (pull-to-refresh), data lama tetap
  /// tampil dan posisi gulir tidak hilang; kalau gagal, cukup snackbar.
  Future<void> _muat({bool senyap = false}) async {
    if (!senyap || _detail == null) {
      setState(() {
        _loading = true;
        _pesanError = null;
      });
    }

    try {
      final RiwayatDetail hasil = await _service.fetchDetail(widget.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = hasil;
        _loading = false;
        _pesanError = null;
      });
    } on ApiException catch (e) {
      _tanganiGagal(e.message);
    } catch (_) {
      _tanganiGagal('Terjadi kesalahan yang tidak terduga.');
    }
  }

  void _tanganiGagal(String pesan) {
    if (!mounted) {
      return;
    }

    if (_detail != null) {
      // Refresh senyap gagal: pertahankan data lama.
      setState(() => _loading = false);
      tampilkanPesan(context, pesan, sukses: false);
      return;
    }

    setState(() {
      _loading = false;
      _pesanError = pesan;
    });
  }

  Future<void> _gulirKe(GlobalKey key) async {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null) {
      return;
    }
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    if (!mounted) return;
    // Di-null-kan dulu supaya ketukan berulang pada chip yang sama tetap memicu.
    _disorot.value = null;
    _disorot.value = key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: AppTheme.border(context))),
        title: ValueListenableBuilder<bool>(
          valueListenable: _judulNama,
          builder: (BuildContext context, bool tampilNama, Widget? _) {
            final String nama = _detail?.namaUsaha ?? '';
            final bool pakaiNama = tampilNama && nama.isNotEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                pakaiNama ? nama : 'Detail Riwayat',
                key: ValueKey<bool>(pakaiNama),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            );
          },
        ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: _detail == null
          ? null
          : _BarBagikan(onPressed: () => _tampilkanBagikan(_detail!)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const RiwayatDetailSkeleton();
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
    final bool selesai = detail.statusVerifikasi.toUpperCase() == 'SELESAI';

    final Widget isi = SingleChildScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      child: FullPageCapture(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StatusHeaderCard(
                jenis: StatusBadge(
                  text: detail.sumberData,
                  color: AppTheme.warnaJenis(detail.sumberData),
                ),
                title: detail.namaUsaha,
                badges: <StatusBadge>[
                  StatusBadge(
                    text: detail.statusVerifikasi,
                    color: selesai ? AppTheme.success : AppTheme.warning,
                    titik: true,
                  ),
                  if (detail.ossTidakValid)
                    const StatusBadge(
                      text: 'Tidak Valid',
                      color: AppTheme.danger,
                      ikon: Icons.cancel,
                    ),
                ],
                meta: <HeaderMeta>[
                  HeaderMeta('Petugas Pemeriksa', detail.petugas),
                  HeaderMeta(
                    'Tanggal Pengawasan',
                    formatTanggal(detail.tanggalPengawasan),
                  ),
                ],
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kUsaha,
                pemicu: _disorot,
                child:
                    // Informasi Usaha
                    SectionCard(
                      icon: Icons.storefront_outlined,
                      title: 'Informasi Usaha',
                      aksen: AppTheme.menuSinkronisasi,
                      aksenBg: AppTheme.menuSinkronisasiBg,
                      rows: <Baris>[
                        Baris('Sumber Data', detail.sumberData),
                        Baris('Nama Brand', detail.namaBrand),
                        Baris('Nama Pemilik', detail.namaPemilik),
                        Baris('Jenis Produk', detail.jenisProduk),
                        Baris('KBLI', detail.kbli, kode: true),
                        Baris('Deskripsi KBLI', detail.kbliDesc),
                        Baris(
                          'Website',
                          detail.website,
                          url: normalisasiUrl(detail.website),
                        ),
                        Baris.telepon('No. HP', detail.noHp),
                        Baris(
                          'Email',
                          detail.email,
                          url: (detail.email ?? '').trim().isEmpty
                              ? null
                              : 'mailto:${detail.email!.trim()}',
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kLegalitas,
                pemicu: _disorot,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (detail.ossTidakValid) ...<Widget>[
                      _BannerTidakValid(pesan: detail.pesanValidasi),
                      const SizedBox(height: 8),
                    ],
                    // Legalitas
                    SectionCard(
                      icon: Icons.verified_outlined,
                      title: 'Legalitas & Dokumen',
                      aksen: AppTheme.success,
                      aksenBg: AppTheme.menuKeamananBg,
                      rows: <Baris>[
                        Baris(
                          'Status Verifikasi',
                          detail.statusVerifikasi,
                          warnaLencana: selesai
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                        Baris('Memiliki NIB', detail.memilikiNib),
                        Baris('Nomor NIB', detail.nib, salin: true, kode: true),
                        Baris('NKU', detail.idProyek, salin: true, kode: true),
                        Baris('NPWPD', detail.npwpd, kode: true),
                        Baris('Terdaftar OTA', detail.terdaftarOta),
                        if (detail.sumberData.toUpperCase() ==
                            'OSS') ...<Baris>[
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
                  ],
                ),
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kLokasi,
                pemicu: _disorot,
                child:
                    // Lokasi
                    SectionCard(
                      icon: Icons.place_outlined,
                      title: 'Lokasi & Wilayah',
                      aksen: AppTheme.menuTampilan,
                      aksenBg: AppTheme.menuTampilanBg,
                      rows: <Baris>[
                        Baris('Provinsi', detail.wilayah.provinsi),
                        Baris('Kabupaten/Kota', detail.wilayah.kabupaten),
                        Baris('Kecamatan', detail.wilayah.kecamatan),
                        Baris('Kelurahan', detail.wilayah.kelurahan),
                        Baris('Alamat', detail.alamat, salin: true),
                        Baris.koordinat(detail.latitude, detail.longitude),
                      ],
                    ),
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kHasil,
                pemicu: _disorot,
                child:
                    // Hasil Pengawasan
                    SectionCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Hasil Pengawasan',
                      aksen: AppTheme.menuNotifikasi,
                      aksenBg: AppTheme.menuNotifikasiBg,
                      rows: <Baris>[
                        Baris('Petugas', detail.petugas),
                        Baris(
                          'Status Pengawasan',
                          detail.statusPengawasan,
                          warnaLencana: AppTheme.menuProfil,
                        ),
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
                            kotak: KotakBaris.peringatan,
                          )
                        else
                          Baris(
                            'Keterangan',
                            detail.keterangan,
                            kotak: KotakBaris.netral,
                          ),
                        Baris(
                          'Catatan Petugas',
                          detail.catatanPetugas,
                          kotak: KotakBaris.netral,
                        ),
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
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kFoto,
                pemicu: _disorot,
                child: FotoGallerySection(
                  foto: <FotoItem>[
                    for (final RiwayatDetailFoto f in detail.foto)
                      FotoItem.url(f.url, keterangan: f.keterangan),
                  ],
                ),
              ),
              const SizedBox(height: _jarak),
              _KilatSection(
                key: _kOta,
                pemicu: _disorot,
                child: OtaListSection(items: detail.ota.map(_itemOta).toList()),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: <Widget>[
        _barLompat(context, detail),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _muat(senyap: true),
            child: isi,
          ),
        ),
      ],
    );
  }

  /// Chip lompat-section yang menempel di bawah AppBar. Urutan section
  /// tidak berubah; ini hanya jalan pintas.
  Widget _barLompat(BuildContext context, RiwayatDetail d) {
    final List<(String, IconData, GlobalKey)> item =
        <(String, IconData, GlobalKey)>[
          ('Usaha', Icons.storefront_outlined, _kUsaha),
          ('Legalitas', Icons.verified_outlined, _kLegalitas),
          ('Lokasi', Icons.place_outlined, _kLokasi),
          ('Hasil', Icons.fact_check_outlined, _kHasil),
          if (d.foto.isNotEmpty) ('Foto', Icons.photo_library_outlined, _kFoto),
          if (d.ota.isNotEmpty) ('OTA', Icons.hotel_outlined, _kOta),
        ];
    final Color aksen = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            for (final (String, IconData, GlobalKey) e in item)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(e.$2, size: 16, color: aksen),
                  label: Text(
                    e.$1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  backgroundColor: AppTheme.surfaceMuted(context),
                  side: BorderSide(color: AppTheme.border(context)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _gulirKe(e.$3),
                ),
              ),
          ],
        ),
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

  /// Bottom sheet pratinjau: user melihat persis apa yang akan dibagikan,
  /// lalu memilih Salin atau Bagikan.
  Future<void> _tampilkanBagikan(RiwayatDetail d) async {
    final String teks = _ringkasan(d);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface(context),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bagikan ringkasan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(sheetContext),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No. HP, email, dan foto tidak ikut dibagikan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(sheetContext),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted(sheetContext),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border(sheetContext)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        teks,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppTheme.textColor(sheetContext),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: teks));
                          HapticFeedback.lightImpact();
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          if (!mounted) return;
                          tampilkanPesan(
                            context,
                            'Ringkasan disalin.',
                            sukses: true,
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Salin'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _bagikan(d);
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Bagikan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

/// Banner peringatan di atas section Legalitas saat data OSS tidak valid.
class _BannerTidakValid extends StatelessWidget {
  const _BannerTidakValid({required this.pesan});

  final String? pesan;

  @override
  Widget build(BuildContext context) {
    final String isi = (pesan ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tintBackground(
          context,
          AppTheme.danger,
          AppTheme.dangerBackground,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Data OSS tidak valid',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                if (isi.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    isi,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Membungkus satu section dan menampilkan kilatan (2x) saat [pemicu]
/// berisi key milik widget ini. Key yang sama dipakai untuk scroll.
class _KilatSection extends StatefulWidget {
  const _KilatSection({
    super.key,
    required this.pemicu,
    required this.child,
    this.radius = 16,
  });

  final ValueNotifier<Key?> pemicu;
  final Widget child;

  /// Samakan dengan radius sudut SectionCard.
  final double radius;

  @override
  State<_KilatSection> createState() => _KilatSectionState();
}

class _KilatSectionState extends State<_KilatSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // naik-turun-naik-turun = dua kedipan
  late final Animation<double> _opasitas =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        for (int i = 0; i < 4; i++)
          TweenSequenceItem<double>(
            tween: i.isEven
                ? Tween<double>(begin: 0, end: 1)
                : Tween<double>(begin: 1, end: 0),
            weight: 1,
          ),
      ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    widget.pemicu.addListener(_onPemicu);
  }

  @override
  void dispose() {
    widget.pemicu.removeListener(_onPemicu);
    _c.dispose();
    super.dispose();
  }

  void _onPemicu() {
    if (!mounted || widget.pemicu.value != widget.key) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final Color warna = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double a = _opasitas.value;
        return Stack(
          fit: StackFit.passthrough, // supaya anak tetap selebar induk
          children: <Widget>[
            child!,
            if (a > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.14 * a),
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(
                        color: warna.withValues(alpha: 0.9 * a),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bar Bagikan yang menempel di bawah layar.
class _BarBagikan extends StatelessWidget {
  const _BarBagikan({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(top: BorderSide(color: AppTheme.border(context))),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text(
              'Bagikan Ringkasan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
