import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_banner.dart';
import 'package:ipardasbor/features/oss/pages/oss_proyek_filter_sheet.dart';
import 'package:ipardasbor/shared/scroll/back_to_top_mixin.dart';
import 'package:ipardasbor/shared/widgets/active_filter_chips.dart';
import 'package:ipardasbor/shared/widgets/app_bar_part.dart';
import 'package:ipardasbor/shared/widgets/list_search_field.dart';
import 'package:ipardasbor/shared/widgets/list_summary_line.dart';

import '../../app/app_theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/network/network_status.dart';

import '../../shared/region/models/region_option.dart';

import '../riwayat/models/riwayat_page_result.dart' show RiwayatPagination;
import '../riwayat/pages/riwayat_detail_page.dart';

import 'models/oss_proyek_filter.dart';
import 'models/oss_proyek_item.dart';
import 'models/oss_proyek_page_result.dart';

import 'pages/oss_validasi_page.dart';

import 'services/oss_proyek_service.dart';

import 'widgets/oss_proyek_card.dart';
import 'widgets/oss_proyek_filter_chips.dart';

import '../../shared/utils/skeleton.dart';
import '../../shared/utils/staggered_entrance.dart';
import '../../shared/widgets/page_states.dart';

import 'package:ipardasbor/shared/ocr/ocr.dart';

/// Daftar usaha akomodasi OSS yang perlu diverifikasi.
///
/// Padanan tabel "Daftar Pengawasan OSS Akomodasi" di web: pencarian NIB/NKU,
/// filter wilayah, infinite scroll, dan tarik untuk menyegarkan.
class OssProyekPage extends StatefulWidget {
  const OssProyekPage({
    super.key,
    this.provinsiIdAwal,
    this.kabupatenIdAwal,
    this.baselineOtaId,
    this.bidang = 'akomodasi',
    this.namaBidang,
  });

  /// Slug bidang usaha (key di config bidang_usaha_pariwisata).
  final String bidang;
  final String? namaBidang;

  final int? provinsiIdAwal;

  /// Kalau diisi, filter kabupaten langsung diterapkan saat halaman dibuka
  /// - dipakai saat masuk dari tombol "Ada NIB" di BaselineOtaPage.
  final int? kabupatenIdAwal;

  /// ID baris tbl_oss_baseline_ota yang sedang diverifikasi, kalau halaman
  /// ini dibuka dari BaselineOtaPage. Diteruskan ke OssValidasiPage saat
  /// user memilih salah satu proyek atau memakai Cek Data OSS manual.
  final int? baselineOtaId;

  @override
  State<OssProyekPage> createState() => _OssProyekPageState();
}

class _OssProyekPageState extends State<OssProyekPage>
    with SingleTickerProviderStateMixin, BackToTopMixin<OssProyekPage> {
  final OssProyekService _service = OssProyekService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;

  /// Satu controller untuk animasi masuk kartu (StaggeredEntrance). Diputar
  /// ulang hanya saat daftar dimuat dari awal, bukan saat infinite scroll
  /// atau tarik-untuk-menyegarkan.
  late final AnimationController _entrance;

  /// Kartu yang baru selesai diverifikasi; disorot sekitar 2 detik.
  int? _highlightId;
  Timer? _highlightTimer;

  late OssProyekFilter _filter;
  OssProyekPageResult? _hasil; // hasil terakhir: opsi filter, provinsi, total

  /// Hitungan per status (belum / terverifikasi / tidak valid).
  OssProyekRingkasan? _ringkasan;
  final List<OssProyekItem> _items = <OssProyekItem>[];
  RiwayatPagination _pagination = RiwayatPagination.kosong;

  bool _loadingAwal = true;
  bool _loadingBerikutnya = false;

  String? _pesanError;

  /// Gagal memuat halaman berikutnya (infinite scroll). Selama true, scroll
  /// tidak memicu muat ulang otomatis; user menekan "Coba lagi" di footer.
  bool _gagalBerikutnya = false;
  String? _pesanBerikutnya;

  /// Naik setiap kali daftar dimuat ulang; respons lama diabaikan supaya
  /// hasil pencarian yang terlambat tidak menimpa hasil yang lebih baru.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _filter = OssProyekFilter(
      provinsiId: widget.provinsiIdAwal,
      kabupatenId: widget.kabupatenIdAwal,
    );
    initBackToTop();
    _muatUlang();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _highlightTimer?.cancel();
    _entrance.dispose();
    disposeBackToTop();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void onNearBottom() {
    _muatBerikutnya();
  }

  Future<void> _muatUlang({bool tampilkanLoading = true}) async {
    final int id = ++_requestId;

    setState(() {
      _loadingBerikutnya = false;
      _gagalBerikutnya = false;
      if (tampilkanLoading) {
        _loadingAwal = true;
        _pesanError = null;
      }
    });

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: 1,
        bidang: widget.bidang,
      );
      if (!mounted || id != _requestId) return;

      setState(() {
        _items
          ..clear()
          ..addAll(hasil.items);
        _pagination = hasil.pagination;
        _hasil = hasil;
        _ringkasan = hasil.ringkasan ?? _ringkasan;
        _loadingAwal = false;
        _pesanError = null;
      });

      if (tampilkanLoading) {
        _entrance.forward(from: 0);
      } else if (!_entrance.isAnimating) {
        _entrance.value = 1; // refresh diam-diam: tanpa animasi ulang.
      }
    } on ApiException catch (e) {
      _tanganiError(id, pesanErrorRamah(e), tampilkanLoading);
    }
  }

  void _tanganiError(int id, String pesan, bool tampilkanLoading) {
    if (!mounted || id != _requestId) return;

    // Saat menyegarkan diam-diam dan daftar sudah terisi, cukup snackbar.
    if (!tampilkanLoading && _items.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }

    setState(() {
      _loadingAwal = false;
      _pesanError = pesan;
    });
  }

  Future<void> _muatBerikutnya() async {
    if (_loadingBerikutnya ||
        _loadingAwal ||
        _gagalBerikutnya ||
        !_pagination.hasNextPage) {
      return;
    }

    final int id = _requestId;
    setState(() => _loadingBerikutnya = true);

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: _pagination.currentPage + 1,
        bidang: widget.bidang,
      );
      if (!mounted || id != _requestId) return;

      setState(() {
        _items.addAll(hasil.items);
        _pagination = hasil.pagination;
        _loadingBerikutnya = false;
      });
    } on ApiException catch (e) {
      _gagalMuatBerikutnya(id, e.message);
    } catch (_) {
      _gagalMuatBerikutnya(id, 'Gagal memuat data berikutnya.');
    }
  }

  void _gagalMuatBerikutnya(int id, String pesan) {
    if (!mounted || id != _requestId) return;
    setState(() {
      _loadingBerikutnya = false;
      _gagalBerikutnya = true;
      _pesanBerikutnya = pesan;
    });
  }

  void _cobaLagiBerikutnya() {
    setState(() {
      _gagalBerikutnya = false;
      _pesanBerikutnya = null;
    });
    _muatBerikutnya();
  }

  /// Menghapus SEMUA filter: pencarian, status, wilayah, dan opsi sheet.
  /// Hanya provinsi dan jumlah per halaman yang dipertahankan.
  void _hapusSemuaFilter() {
    _debounce?.cancel();
    _searchController.clear();
    _ubahFilter(
      OssProyekFilter(provinsiId: _filter.provinsiId, perPage: _filter.perPage),
    );
  }

  void _terapkanPencarian(String value) {
    if (value.trim() == _filter.nibNku.trim()) return;
    setState(() => _filter = _filter.copyWith(nibNku: value));
    _muatUlang();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _terapkanPencarian(value),
    );
  }

  /// Mengisi kolom pencarian lewat kode, lalu langsung mencari.
  /// (Mengubah controller.text tidak memicu onChanged.)
  void _isiPencarian(String value) {
    _debounce?.cancel();
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _terapkanPencarian(value);
  }

  /// Menghapus kolom pencarian dan memuat ulang daftar.
  void _hapusPencarian() => _isiPencarian('');

  /// Mengganti filter lalu memuat ulang daftar dari halaman pertama.
  void _ubahFilter(OssProyekFilter baru) {
    setState(() => _filter = baru);
    _muatUlang();
  }

  void _ubahStatus(String? status) {
    if (status == _filter.statusVerifikasi) return;
    _ubahFilter(
      _filter.copyWith(
        statusVerifikasi: status,
        clearStatusVerifikasi: status == null,
      ),
    );
  }

  /// Mereset filter dari sheet. Pencarian dan status tetap dipertahankan.
  void _resetFilterSheet() {
    _ubahFilter(
      OssProyekFilter(
        provinsiId: _filter.provinsiId,
        statusVerifikasi: _filter.statusVerifikasi,
        nibNku: _filter.nibNku,
        perPage: _filter.perPage,
      ),
    );
  }

  /// Chip filter aktif dari sheet filter (tanpa status & pencarian, yang
  /// sudah punya kontrol sendiri). Kecamatan/kelurahan hanya punya ID di
  /// sini (namanya ada di SQLite lokal), jadi labelnya generik.
  List<FilterChipData> _chipFilterAktif() {
    final OssProyekFilter f = _filter;
    final List<FilterChipData> chips = <FilterChipData>[];

    if (f.kabupatenId != null) {
      String nama = 'Kabupaten/Kota';
      for (final RegionOption o
          in _hasil?.kabupatenOptions ?? const <RegionOption>[]) {
        if (o.id == f.kabupatenId) {
          nama = o.name;
          break;
        }
      }
      chips.add(
        FilterChipData(
          label: nama,
          onRemove: () => _ubahFilter(
            f.copyWith(
              clearKabupatenId: true,
              clearKecamatanId: true,
              clearKelurahanId: true,
            ),
          ),
        ),
      );
    }
    if (f.kecamatanId != null) {
      chips.add(
        FilterChipData(
          label: 'Kecamatan dipilih',
          onRemove: () => _ubahFilter(
            f.copyWith(clearKecamatanId: true, clearKelurahanId: true),
          ),
        ),
      );
    }
    if (f.kelurahanId != null) {
      chips.add(
        FilterChipData(
          label: 'Kelurahan dipilih',
          onRemove: () => _ubahFilter(f.copyWith(clearKelurahanId: true)),
        ),
      );
    }
    if (f.statusPenanamanModal != null) {
      chips.add(
        FilterChipData(
          label: f.statusPenanamanModal!,
          onRemove: () =>
              _ubahFilter(f.copyWith(clearStatusPenanamanModal: true)),
        ),
      );
    }
    if (f.uraianSkalaUsaha != null) {
      chips.add(
        FilterChipData(
          label: f.uraianSkalaUsaha!,
          onRemove: () => _ubahFilter(f.copyWith(clearUraianSkalaUsaha: true)),
        ),
      );
    }
    if (f.uraianRisiko != null) {
      chips.add(
        FilterChipData(
          label: 'Risiko ${f.uraianRisiko!}',
          onRemove: () => _ubahFilter(f.copyWith(clearUraianRisiko: true)),
        ),
      );
    }

    return chips;
  }

  /// Scan NIB/NKU dari foto atau screenshot.
  Future<void> _scanPencarian() async {
    final Map<OcrFieldType, String>? values = await runOcrScan(
      context,
      targets: {OcrFieldType.nib, OcrFieldType.nku},
      currentValues: {OcrFieldType.nib: '', OcrFieldType.nku: ''},
      bidang: widget.bidang,
    );
    if (!mounted || values == null || values.isEmpty) return;

    // Kolom pencarian cuma satu: utamakan NKU (lebih spesifik), lalu NIB.
    final OcrFieldType jenis = values.containsKey(OcrFieldType.nku)
        ? OcrFieldType.nku
        : OcrFieldType.nib;
    final String? nilai = values[jenis];
    if (nilai == null || nilai.isEmpty) return;

    _isiPencarian(nilai);
    HapticFeedback.selectionClick();

    final String info = values.length > 1
        ? 'Mencari ${jenis.displayName}. NIB dan NKU sama-sama terbaca, '
              'hanya satu yang dipakai.'
        : 'Mencari ${jenis.displayName} dari hasil scan.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(info)));
  }

  /// Tempel dari clipboard: dicoba sebagai NKU dulu, lalu NIB.
  Future<void> _tempelPencarian() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final String text = data?.text ?? '';
    if (text.trim().isEmpty) {
      _snack('Clipboard kosong.');
      return;
    }

    OcrFieldType jenis = OcrFieldType.nku;
    List<OcrResult> cands = OcrPasteCleaner.clean(text, jenis);
    if (cands.isEmpty) {
      jenis = OcrFieldType.nib;
      cands = OcrPasteCleaner.clean(text, jenis);
    }
    if (cands.isEmpty) {
      _snack('Tidak ada NIB atau NKU yang ditemukan di clipboard.');
      return;
    }

    String? nilai;
    if (cands.length == 1) {
      nilai = cands.first.value;
    } else {
      final OcrSheetResult? sheet = await showOcrResultSheet(
        context,
        results: {jenis: cands},
        currentValues: {jenis: _searchController.text.trim()},
        allowRetry: false,
      );
      if (!mounted || sheet == null || sheet.retry) return;
      nilai = sheet.values[jenis];
    }

    if (nilai == null || nilai.isEmpty) return;
    _isiPencarian(nilai);
    HapticFeedback.selectionClick();
    _snack('${jenis.displayName} ditempel, mencari...');
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _bukaFilter() async {
    final OssProyekPageResult? h = _hasil;

    final OssProyekFilter? hasil = await showOssProyekFilterSheet(
      context,
      filter: _filter,
      provinsiAktifId: h?.provinsiId,
      provinsiOptions: h?.provinsiOptions ?? const [],
      kabupatenOptions: h?.kabupatenOptions ?? const [],
    );

    if (hasil == null) return;

    _ubahFilter(hasil);
  }

  /// Membuka halaman validasi dengan NIB, KBLI, dan NKU terisi dari baris ini.
  Future<void> _bukaVerifikasi(OssProyekItem item) async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssValidasiPage(
          initialNib: item.nib,
          initialKbli: item.kbli,
          initialNku: item.nku,
          namaUsaha: item.namaPerusahaan,
          baselineOtaId: widget.baselineOtaId,
          bidang: widget.bidang,
        ),
      ),
    );

    if (tersimpan == true && mounted) {
      await _segarkanItem(item);
      if (!mounted) return;
      _tandaiSelesai(item.id);
      unawaited(_segarkanRingkasan());
    }
  }

  /// Verifikasi manual untuk usaha yang belum ada di daftar.
  Future<void> _bukaCekManual() async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssValidasiPage(
          baselineOtaId: widget.baselineOtaId,
          bidang: widget.bidang,
        ),
      ),
    );

    if (tersimpan == true && mounted) {
      await _muatUlang(tampilkanLoading: false);
      if (!mounted) return;
      _tandaiSelesai(null);
    }
  }

  /// Umpan balik setelah verifikasi tersimpan: haptic, snackbar, dan sorot
  /// kartunya sebentar. Kalau kartu sudah tidak ada di daftar (mis. filter
  /// "Belum" aktif), cukup snackbar umum.
  void _tandaiSelesai(int? id) {
    OssProyekItem? ditemukan;
    if (id != null) {
      for (final OssProyekItem e in _items) {
        if (e.id == id) {
          ditemukan = e;
          break;
        }
      }
    }

    HapticFeedback.mediumImpact();

    if (ditemukan == null) {
      _snack('Verifikasi tersimpan.');
      return;
    }

    final OssProyekItem usaha = ditemukan;
    _snack(
      usaha.tidakValid
          ? '${usaha.namaPerusahaan}: tersimpan, hasil tidak valid.'
          : '${usaha.namaPerusahaan} berhasil diverifikasi.',
    );

    _highlightTimer?.cancel();
    setState(() => _highlightId = usaha.id);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightId = null);
    });
  }

  /// Memperbarui hitungan per status setelah ada verifikasi baru. Hanya
  /// angka yang diambil; daftar dan posisi scroll tidak disentuh.
  Future<void> _segarkanRingkasan() async {
    final int id = _requestId;
    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: 1,
        bidang: widget.bidang,
      );
      if (!mounted || id != _requestId) return;
      final OssProyekRingkasan? baru = hasil.ringkasan;
      if (baru != null) setState(() => _ringkasan = baru);
    } catch (_) {
      // Angka lama dibiarkan; akan diperbarui pada muat ulang berikutnya.
    }
  }

  void _bukaDetail(OssProyekItem item) {
    final int? id = item.pengawasanId;
    if (id == null) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RiwayatDetailPage(id: id)));
  }

  /// Memuat ulang HANYA halaman server yang memuat [item], lalu mengganti
  /// irisan itu di daftar. Posisi scroll dan halaman lain tidak berubah.
  ///
  /// Kalau filter status aktif (mis. "Belum"), item yang baru diverifikasi
  /// tidak lagi cocok dengan filter sehingga jumlah baris berubah; kasus itu
  /// ditangani oleh cabang muat ulang penuh di bawah.
  Future<void> _segarkanItem(OssProyekItem item) async {
    final int index = _items.indexWhere((OssProyekItem e) => e.id == item.id);
    if (index < 0) return;

    final int perPage = _filter.perPage;
    final int halaman = index ~/ perPage + 1;
    final int awal = (halaman - 1) * perPage;

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: halaman,
        bidang: widget.bidang,
      );
      if (!mounted) return;

      final int akhir = math.min(awal + perPage, _items.length);

      if (hasil.items.length != akhir - awal) {
        await _muatUlang(tampilkanLoading: false);
        return;
      }

      setState(() => _items.replaceRange(awal, akhir, hasil.items));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Daftar belum diperbarui. Tarik ke bawah untuk menyegarkan.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final OssProyekPageResult? h = _hasil;
    final int jumlahFilter = _filter.jumlahFilterSheet;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: buildBackToTopFab(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: TwoLineTitle(
          title: widget.namaBidang ?? 'Validasi OSS',
          subtitle: 'Verifikasi Proyek dan Usaha OSS',
        ),
        actions: <Widget>[
          FilterAction(onPressed: _bukaFilter, activeCount: jumlahFilter),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSearchField(context),
          ),
          OssStatusFilterBar(
            selected: _filter.statusVerifikasi,
            onChanged: _ubahStatus,
            ringkasan: _ringkasan,
          ),
          Builder(
            builder: (BuildContext context) {
              final List<FilterChipData> chips = _chipFilterAktif();
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ActiveFilterChips(
                  chips: chips,
                  onResetAll: _resetFilterSheet,
                ),
              );
            },
          ),
          if (h != null && _pesanError == null)
            ListSummaryLine(
              provinsi: h.provinsiNama,
              total: _pagination.total,
              satuan: 'usaha',
              // Disembunyikan saat daftar disaring per status (angkanya
              // sudah ada di chip).
              belum: _ringkasan != null && _filter.statusVerifikasi == null
                  ? _ringkasan!.belum
                  : null,
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  /// Kolom pencarian NIB/NKU: hanya angka (maks. 21 digit), dengan tombol
  /// tempel dan scan OCR di ujung.
  Widget _buildSearchField(BuildContext context) {
    return ListSearchField(
      controller: _searchController,
      focusNode: _searchFocus,
      hintText: 'Cari NIB atau NKU lengkap',
      contohSaatFokus: 'NIB: 8120115082852 · NKU: 201912311521051085492',
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly, // dulu filter...
        LengthLimitingTextInputFormatter(21), // ...baru batasi panjang
      ],
      onChanged: _onSearchChanged,
      onSubmitted: (String v) {
        _debounce?.cancel();
        _terapkanPencarian(v);
      },
      onClear: _hapusPencarian,
      trailing: OcrFieldActions(
        onPaste: _loadingAwal ? null : _tempelPencarian,
        onScan: _loadingAwal ? null : _scanPencarian,
      ),
    );
  }

  Widget _buildKosong() {
    final bool adaPencarian = _filter.nibNku.trim().isNotEmpty;
    final bool hasFilter = _filter.hasActiveFilter;

    final String judul;
    final String isi;
    if (adaPencarian) {
      judul = 'Usaha tidak ditemukan';
      isi =
          'Pastikan NIB atau NKU diketik lengkap. Kalau usahanya memang '
          'belum ada di daftar, gunakan "Cek Data OSS" di atas.';
    } else if (hasFilter) {
      judul = 'Tidak ada yang cocok';
      isi = 'Tidak ada usaha yang sesuai dengan filter yang dipilih.';
    } else {
      judul = 'Belum ada data';
      isi = 'Belum ada data usaha pada wilayah ini.';
    }

    return EmptyListState(
      icon: hasFilter ? Icons.search_off_rounded : Icons.inbox_outlined,
      title: judul,
      message: isi,
      actionLabel: hasFilter ? 'Hapus semua filter' : null,
      onAction: hasFilter ? _hapusSemuaFilter : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingAwal) {
      return const OssProyekSkeleton();
    }

    if (_pesanError != null) {
      return ConnectionErrorState(
        title: 'Daftar usaha gagal dimuat',
        message: _pesanError!,
        isRetrying: _loadingAwal,
        onRetry: _muatUlang,
      );
    }

    final int jumlahBaris = _items.isEmpty ? 1 : _items.length;

    return RefreshIndicator(
      onRefresh: () => _muatUlang(tampilkanLoading: false),
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: 1 + jumlahBaris + (_pagination.hasNextPage ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return ValueListenableBuilder<bool>(
              valueListenable: NetworkStatus.instance,
              builder: (_, offline, _) =>
                  _KartuCekManual(onTap: _bukaCekManual, offline: offline),
            );
          }

          if (_items.isEmpty) {
            return _buildKosong();
          }

          final int i = index - 1;

          if (i >= _items.length) {
            return LoadMoreFooter(
              gagal: _gagalBerikutnya,
              pesan: _pesanBerikutnya,
              onCobaLagi: _cobaLagiBerikutnya,
            );
          }

          final OssProyekItem item = _items[i];
          final Widget kartu = OssProyekCard(
            key: ValueKey<int>(item.id),
            item: item,
            highlight: item.id == _highlightId,
            onVerifikasi: () => _bukaVerifikasi(item),
            onDetail: () => _bukaDetail(item),
          );

          // Hanya 10 kartu pertama yang dianimasikan; sisanya langsung tampil.
          if (i >= 10) return kartu;

          return StaggeredEntrance(
            key: ValueKey<String>('masuk_${item.id}'),
            animation: _entrance,
            index: i,
            child: kartu,
          );
        },
      ),
    );
  }
}

/// Padanan baris "Cek Data OSS" di web. Sengaja ringkas (satu baris) supaya
/// tidak memakan ruang kartu pertama setiap kali daftar dibuka.
class _KartuCekManual extends StatelessWidget {
  const _KartuCekManual({required this.onTap, this.offline = false});

  final VoidCallback onTap;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    const Color aksen = AppTheme.secondaryColor;

    return Opacity(
      opacity: offline ? 0.5 : 1,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: aksen.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: aksen.withValues(alpha: 0.30)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: offline ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit_note_rounded, color: aksen, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Usaha tidak ada di daftar? ',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        TextSpan(
                          text: offline
                              ? 'Cek Data OSS (perlu koneksi)'
                              : 'Cek Data OSS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 12.5, height: 1.3),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
