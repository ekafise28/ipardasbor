import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/features/oss/oss_proyek_page.dart';
import 'package:ipardasbor/shared/pagination/back_to_top_mixin.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../../app/app_theme.dart';

import '../../core/api/api_client.dart';
import '../../core/network/network_status.dart';

import 'models/baseline_ota_filter.dart';
import 'models/baseline_ota_item.dart';
import 'models/baseline_ota_page_result.dart';
import '../../shared/gps/location_fetch_status.dart';
import 'models/baseline_ota_ringkasan.dart';

import '../non_oss/non_oss_form_page.dart';
import 'pages/baseline_ota_detail_page.dart';

import '../../shared/region/services/region_service.dart';
import '../../shared/gps/gps_capture_mixin.dart';
import '../../shared/pagination/paginated_list_controller.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/page_states.dart';
import 'services/baseline_ota_service.dart';

import 'widgets/baseline_ota_filter_sheet.dart';
import 'widgets/baseline_ota_card.dart';

class BaselineOtaPage extends StatefulWidget {
  const BaselineOtaPage({super.key});

  @override
  State<BaselineOtaPage> createState() => _BaselineOtaPageState();
}

class _BaselineOtaPageState extends State<BaselineOtaPage>
    with
        WidgetsBindingObserver,
        GpsCaptureMixin<BaselineOtaPage>,
        BackToTopMixin<BaselineOtaPage> {
  late final BaselineOtaService _service;
  late final PaginatedListController<BaselineOtaItem> _ctrl;
  final RegionService _regions = RegionService();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  BaselineOtaFilter _filter = BaselineOtaFilter();
  BaselineOtaFilterOptions? _filterOptions;
  String _provinsiNama = '';
  String? _namaKecamatan;
  String? _namaKelurahan;

  /// Hitungan per status untuk chip filter cepat dan keterangan jumlah.
  BaselineOtaRingkasan? _ringkasan;

  @override
  void initState() {
    super.initState();
    initGpsCapture();
    _service = BaselineOtaService(ApiClient());
    _ctrl = PaginatedListController<BaselineOtaItem>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (BaselineOtaItem e) => e.id,
      perPage: () => _filter.perPage,
      onLoaded: _setelahDimuat,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    initBackToTop();
    _ctrl.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    disposeBackToTop();
    _searchCtrl.dispose();
    disposeGpsCapture();
    super.dispose();
  }

  /// Membaca filter terbaru setiap kali dipanggil.
  Future<PageChunk<BaselineOtaItem>> _ambilHalaman(int page) async {
    final BaselineOtaPageResult hasil = await _service.list(
      _filter,
      page: page,
    );
    return PageChunk<BaselineOtaItem>(
      items: hasil.items,
      currentPage: hasil.currentPage,
      hasNext: hasil.hasMore,
      total: hasil.total,
      meta: hasil,
    );
  }

  /// Data tambahan dari respons; controller yang memberi tahu UI sesudahnya,
  /// jadi tidak perlu setState di sini.
  void _setelahDimuat(PageChunk<BaselineOtaItem> chunk) {
    final BaselineOtaPageResult hasil = chunk.meta! as BaselineOtaPageResult;
    _filterOptions = hasil.filterOptions;
    _provinsiNama = hasil.provinsiNama;
    _filter.provinsiId ??= hasil.provinsiId;
    _ringkasan = hasil.ringkasan ?? _ringkasan;
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {
      // Daftar diganti skeleton: posisi scroll akan kembali ke 0.
      if (_ctrl.loadingFirst) hideBackToTop();
    });
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  void onNearBottom() {
    _ctrl.loadMore();
  }

  /// Catatan kalau jarak dihitung dari lokasi tersimpan, bukan posisi sekarang.
  String? _infoLokasi;

  Future<void> _toggleDekatSaya() async {
    if (_filter.urutJarak) {
      setState(() {
        _filter.lat = null;
        _filter.lng = null;
        _infoLokasi = null;
      });
      jumpKeAtas();
      await _ctrl.reload();
      return;
    }

    await ambilLokasiGps(
      onBerhasil: (hasil) {
        setState(() {
          _filter.lat = hasil.position.latitude;
          _filter.lng = hasil.position.longitude;
          _infoLokasi = hasil.source == LocationSource.gpsLangsung
              ? null
              : 'Memakai lokasi tersimpan, bukan posisi Anda saat ini.';
        });
        jumpKeAtas();
        _ctrl.reload();
      },
    );
  }

  Future<void> _bukaFilter() async {
    if (_filterOptions == null) return;
    final BaselineOtaFilter? hasil =
        await showModalBottomSheet<BaselineOtaFilter>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OssBaselineOtaFilterSheet(
            filter: _filter,
            filterOptions: _filterOptions!,
            regionService: _regions,
          ),
        );
    if (hasil != null) {
      setState(() => _filter = hasil);
      _searchCtrl.text = hasil.namaListing ?? '';
      _muatNamaWilayah(); // sengaja tanpa await, jalan paralel dengan load daftar
      await _ctrl.reload();
    }
  }

  /// Menerapkan kata kunci. Tidak memuat ulang kalau kata kuncinya sama.
  void _terapkanPencarian(String keyword) {
    _debounce?.cancel();
    final String? baru = keyword.trim().isEmpty ? null : keyword.trim();
    if (baru == _filter.namaListing) return;
    _filter.namaListing = baru;
    jumpKeAtas();
    _ctrl.reload();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _terapkanPencarian(value),
    );
  }

  void _hapusPencarian() {
    _searchCtrl.clear();
    _terapkanPencarian('');
  }

  void _setStatus(String? status) {
    if (_filter.status == status) return;
    setState(() => _filter.status = status);
    _ctrl.reload();
  }

  /// Menghapus SEMUA filter: pencarian, status, wilayah, platform, dan
  /// mode "Dekat saya". Hanya provinsi dan jumlah per halaman dipertahankan.
  void _resetFilter() {
    _searchCtrl.clear();
    setState(() {
      _filter = _filter.reset();
      _filter.lat = null;
      _filter.lng = null;
      _infoLokasi = null;
      _namaKecamatan = null;
      _namaKelurahan = null;
    });
    _ctrl.reload();
  }

  /// Reset dari chip filter aktif ("Reset"): hanya filter dari sheet
  /// (wilayah + platform). Pencarian, status, dan "Dekat saya" dipertahankan.
  void _resetFilterSheet() {
    setState(() {
      _filter = BaselineOtaFilter(
        provinsiId: _filter.provinsiId,
        perPage: _filter.perPage,
        status: _filter.status,
        namaListing: _filter.namaListing,
        lat: _filter.lat,
        lng: _filter.lng,
      );
      _namaKecamatan = null;
      _namaKelurahan = null;
    });
    _ctrl.reload();
  }

  Future<void> _setelahTersimpan(BaselineOtaItem item) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _filter.status == 'BELUM'
                ? 'Verifikasi tersimpan. Listing ini pindah ke daftar "Terverifikasi".'
                : 'Verifikasi tersimpan.',
          ),
        ),
      );
    await _ctrl.refreshItem(item);
  }

  /// Jumlah filter yang tampil sebagai chip (status tidak dihitung karena
  /// sudah punya chip cepat sendiri, pencarian teks ada di kolom search).
  int get _jumlahFilterAktif =>
      (_filter.kabupatenId != null ? 1 : 0) +
      (_filter.kecamatanId != null ? 1 : 0) +
      (_filter.kelurahanId != null ? 1 : 0) +
      (_filter.platformOta.isNotEmpty ? 1 : 0);

  /// Filter sheet hanya mengembalikan ID, jadi nama kecamatan/kelurahan
  /// diambil ulang dari RegionService untuk label chip.
  Future<void> _muatNamaWilayah() async {
    String? kec;
    String? kel;
    try {
      if (_filter.kabupatenId != null && _filter.kecamatanId != null) {
        final list = await _regions.districts(_filter.kabupatenId!);
        kec = list.where((e) => e.id == _filter.kecamatanId).firstOrNull?.name;
      }
      if (_filter.kecamatanId != null && _filter.kelurahanId != null) {
        final list = await _regions.villages(_filter.kecamatanId!);
        kel = list.where((e) => e.id == _filter.kelurahanId).firstOrNull?.name;
      }
    } catch (_) {
      // Nama gagal diambil: chip tetap tampil dengan label generik.
    }
    if (!mounted) return;
    setState(() {
      _namaKecamatan = kec;
      _namaKelurahan = kel;
    });
  }

  void _ubahFilter(void Function() ubah) {
    setState(ubah);
    _ctrl.reload();
  }

  /// Data chip filter aktif dari sheet (platform + wilayah), dirender oleh
  /// ActiveFilterChips yang sama dengan halaman OSS.
  List<FilterChipData> _chipFilterAktif() {
    final String? namaKab = _filterOptions?.kabupaten
        .where((e) => e.id == _filter.kabupatenId)
        .firstOrNull
        ?.name;

    return <FilterChipData>[
      for (final String p in _filter.platformOta)
        FilterChipData(
          label: p,
          onRemove: () => _ubahFilter(
            () => _filter.platformOta = _filter.platformOta
                .where((String e) => e != p)
                .toList(),
          ),
        ),
      if (_filter.kabupatenId != null)
        FilterChipData(
          label: namaKab ?? 'Kabupaten/Kota',
          onRemove: () => _ubahFilter(() {
            _filter.kabupatenId = null;
            _filter.kecamatanId = null;
            _filter.kelurahanId = null;
            _namaKecamatan = null;
            _namaKelurahan = null;
          }),
        ),
      if (_filter.kecamatanId != null)
        FilterChipData(
          label: _namaKecamatan ?? 'Kecamatan',
          onRemove: () => _ubahFilter(() {
            _filter.kecamatanId = null;
            _filter.kelurahanId = null;
            _namaKecamatan = null;
            _namaKelurahan = null;
          }),
        ),
      if (_filter.kelurahanId != null)
        FilterChipData(
          label: _namaKelurahan ?? 'Kelurahan/Desa',
          onRemove: () => _ubahFilter(() {
            _filter.kelurahanId = null;
            _namaKelurahan = null;
          }),
        ),
    ];
  }

  Future<void> _bukaDetail(BaselineOtaItem item) async {
    final BaselineOtaAksi? aksi = await Navigator.of(context)
        .push<BaselineOtaAksi>(
          MaterialPageRoute<BaselineOtaAksi>(
            builder: (_) => BaselineOtaDetailPage(item: item),
          ),
        );
    if (aksi == null || !mounted) return;

    switch (aksi) {
      case BaselineOtaAksi.adaNib:
        await _bukaOssProyek(item);
      case BaselineOtaAksi.tidakAda:
        await _bukaNonOss(item, 'TIDAK');
      case BaselineOtaAksi.tidakTahu:
        await _bukaNonOss(item, 'TIDAK TAHU');
    }
  }

  Future<void> _bukaOssProyek(BaselineOtaItem item) async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssProyekPage(
          provinsiIdAwal: item.provinsiId,
          kabupatenIdAwal: item.kabupatenId,
          baselineOtaId: item.id,
        ),
      ),
    );
    if (tersimpan == true) await _setelahTersimpan(item);
  }

  Future<void> _bukaNonOss(BaselineOtaItem item, String memilikiNib) async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NonOssFormPage(
          memilikiNibTerkunci: memilikiNib,
          baselineOtaId: item.id,
        ),
      ),
    );
    if (tersimpan == true) await _setelahTersimpan(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildPaginasi(),
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: buildBackToTopFab(
        enabled:
            !_ctrl.loadingFirst &&
            _ctrl.error == null &&
            _ctrl.items.isNotEmpty,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const TwoLineTitle(
          title: 'Pengawasan OTA',
          subtitle: 'Verifikasi hasil scraping baseline OTA',
        ),
        actions: <Widget>[
          FilterAction(onPressed: _bukaFilter, activeCount: _jumlahFilterAktif),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ListSearchField(
              controller: _searchCtrl,
              hintText: 'Cari listing, alamat, platform...',
              onChanged: _onSearchChanged,
              onSubmitted: (String v) {
                FocusScope.of(context).unfocus();
                _terapkanPencarian(v);
              },
              onClear: _hapusPencarian,
            ),
          ),
          _buildBarisFilterCepat(),
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
          if (!_ctrl.loadingFirst && _ctrl.error == null)
            ListSummaryLine(
              provinsi: _provinsiNama,
              total: _ctrl.total,
              satuan: 'data',
              belum: _ringkasan != null && _filter.status == null
                  ? _ringkasan!.belum
                  : null,
              akhiran: _filter.urutJarak ? 'terdekat dulu' : null,
              catatan: _filter.urutJarak ? _infoLokasi : null,
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Dua baris: chip status (pilih satu, dengan jumlah per status) di atas,
  /// lalu "Dekat saya" di bawahnya (mode urutan, bukan status).
  Widget _buildBarisFilterCepat() {
    final BaselineOtaRingkasan? r = _ringkasan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatusFilterBar(
          selected: _filter.status,
          onChanged: _setStatus,
          options: <StatusFilterOption>[
            StatusFilterOption(
              value: null,
              label: 'Semua',
              color: AppTheme.primaryColor,
              count: r?.total,
            ),
            StatusFilterOption(
              value: 'BELUM',
              label: 'Belum',
              color: AppTheme.warning,
              count: r?.belum,
            ),
            StatusFilterOption(
              value: 'SUDAH',
              label: 'Terverifikasi',
              color: AppTheme.success,
              count: r?.sudah,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: FilterChip(
            avatar: gpsLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.near_me_rounded, size: 16),
            label: const Text('Dekat saya', style: TextStyle(fontSize: 12.5)),
            selected: _filter.urutJarak,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: gpsLoading ? null : (_) => _toggleDekatSaya(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_ctrl.loadingFirst) {
      return const BaselineOtaSkeleton();
    }

    Future<void> segarkan() => _ctrl.reload(showLoading: false);

    // Error dan kosong dibungkus scrollable supaya layar tetap bisa ditarik.
    if (_ctrl.error != null) {
      return RefreshIndicator(
        onRefresh: segarkan,
        child: ScrollableFill(
          child: ConnectionErrorState(
            title: 'Listing OTA gagal dimuat',
            message: _ctrl.error!,
            onRetry: _ctrl.reload,
          ),
        ),
      );
    }

    final List<BaselineOtaItem> items = _ctrl.items;

    if (items.isEmpty) {
      final bool adaFilter = _filter.isActive || _filter.urutJarak;
      return RefreshIndicator(
        onRefresh: segarkan,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyListState(
              icon: adaFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.inbox_outlined,
              title: adaFilter
                  ? 'Tidak ada yang cocok'
                  : 'Belum ada data hasil scraping OTA',
              message: adaFilter
                  ? 'Tidak ada listing yang sesuai dengan filter atau kata '
                        'kunci. Coba ubah atau hapus filternya.'
                  : 'Data akan muncul setelah proses scraping selesai.',
              actionLabel: adaFilter ? 'Hapus semua filter' : null,
              actionIcon: Icons.restart_alt_rounded,
              onAction: adaFilter ? _resetFilter : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: segarkan,
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final BaselineOtaItem item = items[index];
          return BaselineOtaCard(
            item: item,
            onTap: () => _bukaDetail(item),
            onAdaNib: () => _bukaOssProyek(item),
            onTidakAda: () => _bukaNonOss(item, 'TIDAK'),
            onTidakTahu: () => _bukaNonOss(item, 'TIDAK TAHU'),
          );
        },
      ),
    );
  }

  Widget? _buildPaginasi() {
    if (_ctrl.error != null || _ctrl.total == 0) {
      return null;
    }
    return PaginationBar(
      currentPage: _ctrl.currentPage,
      totalPages: _ctrl.totalPages,
      perPage: _filter.perPage,
      total: _ctrl.total,
      enabled: !_ctrl.loadingFirst,
      onPageChanged: _ctrl.goToPage,
      onPerPageChanged: (int n) => _ubahFilter(() => _filter.perPage = n),
    );
  }
}
