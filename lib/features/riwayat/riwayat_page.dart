import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/core/constants/bidang_usaha_constants.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart';

import '../../app/app_theme.dart';

import '../../shared/pagination/paginated_list_controller.dart';
import '../../shared/pagination/back_to_top_mixin.dart';
import '../../shared/widgets/page_states.dart';
import '../../shared/widgets/list_parts.dart';

import 'models/riwayat_filter.dart';
import 'models/riwayat_item.dart';
import 'models/riwayat_page_result.dart';

import 'services/riwayat_service.dart';
import 'pages/riwayat_detail_page.dart';

import 'widgets/riwayat_card.dart';
import 'widgets/riwayat_filter_sheet.dart';

/// Halaman daftar riwayat pengawasan (OSS / Non-OSS / OTA).
///
/// Fitur: pencarian, chip status cepat (Semua / Draft / Selesai), filter
/// (sumber data, bidang, kabupaten, tanggal), infinite scroll, tarik untuk
/// menyegarkan, dan tombol kembali ke atas.
/// Paginasi dikelola [PaginatedListController], sama seperti halaman OTA.
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with BackToTopMixin<RiwayatPage> {
  final RiwayatService _service = RiwayatService();
  final TextEditingController _searchController = TextEditingController();
  late final PaginatedListController<RiwayatItem> _ctrl;

  Timer? _debounce;

  RiwayatFilter _filter = const RiwayatFilter();
  RiwayatFilterOptions _filterOptions = RiwayatFilterOptions.kosong;

  // hitungan per status untuk chip filter cepat.
  RiwayatRingkasan? _ringkasan;

  @override
  void initState() {
    super.initState();
    initBackToTop();
    _ctrl = PaginatedListController<RiwayatItem>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (RiwayatItem e) => e.id,
      perPage: () => _filter.perPage,
      onLoaded: _setelahDimuat,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    _ctrl.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    _searchController.dispose();
    disposeBackToTop();
    super.dispose();
  }

  /// Membaca filter terbaru setiap kali dipanggil.
  Future<PageChunk<RiwayatItem>> _ambilHalaman(int page) async {
    final RiwayatPageResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<RiwayatItem>(
      items: hasil.items,
      currentPage: hasil.pagination.currentPage,
      hasNext: hasil.pagination.hasNextPage,
      total: hasil.pagination.total,
      meta: hasil,
    );
  }

  /// Opsi filter dan ringkasan status dari respons; controller yang memberi
  /// tahu UI sesudahnya, jadi tidak perlu setState di sini.
  void _setelahDimuat(PageChunk<RiwayatItem> chunk) {
    final RiwayatPageResult hasil = chunk.meta! as RiwayatPageResult;
    _filterOptions = hasil.filterOptions;
    // DIUBAH: ringkasan ikut disimpan. Kalau backend belum mengirim,
    // nilai lama dipertahankan.
    _ringkasan = hasil.ringkasan ?? _ringkasan;
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {
      // Daftar diganti skeleton: posisi scroll akan kembali ke 0.
      if (_ctrl.loadingFirst) hideBackToTop();
    });
  }

  @override
  void onNearBottom() {
    _ctrl.loadMore();
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Mengganti filter lalu memuat ulang dari halaman pertama.
  void _ubahFilter(RiwayatFilter baru) {
    setState(() => _filter = baru);
    _ctrl.reload();
  }

  // dipanggil chip status cepat.
  void _ubahStatus(String? status) {
    if (status == _filter.statusVerifikasi) return;
    _ubahFilter(
      _filter.copyWith(
        statusVerifikasi: status,
        clearStatusVerifikasi: status == null,
      ),
    );
  }

  void _terapkanPencarian(String value) {
    if (value.trim() == _filter.search.trim()) return;
    _ubahFilter(_filter.copyWith(search: value));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _terapkanPencarian(value);
    });
  }

  void _hapusPencarian() {
    _debounce?.cancel();
    _searchController.clear();
    _terapkanPencarian('');
  }

  Future<void> _bukaFilter() async {
    final RiwayatFilter? hasil = await showRiwayatFilterSheet(
      context,
      filter: _filter,
      options: _filterOptions,
    );

    if (hasil == null || !mounted) return;
    _ubahFilter(hasil);
  }

  /// Menghapus SEMUA filter: pencarian, status, dan filter dari sheet.
  /// Hanya jumlah per halaman yang dipertahankan.
  void _hapusSemuaFilter() {
    _debounce?.cancel();
    _searchController.clear();
    _ubahFilter(RiwayatFilter(perPage: _filter.perPage));
  }

  /// Reset dari chip filter aktif ("Reset"): hanya filter dari sheet.
  /// Pencarian dan status dipertahankan.
  void _resetFilterSheet() {
    _ubahFilter(
      RiwayatFilter(
        search: _filter.search,
        statusVerifikasi: _filter.statusVerifikasi, // DIUBAH: status dijaga
        perPage: _filter.perPage,
      ),
    );
  }

  void _bukaDetail(RiwayatItem item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RiwayatDetailPage(id: item.id)));
  }

  String _namaKabupaten(int id) {
    for (final RiwayatKabupatenOption o in _filterOptions.kabupaten) {
      if (o.id == id) return o.nama;
    }
    return 'Kabupaten/Kota';
  }

  static String _tgl(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _labelTanggal(DateTime? mulai, DateTime? selesai) {
    if (mulai != null && selesai != null) {
      return '${_tgl(mulai)} - ${_tgl(selesai)}';
    }
    if (mulai != null) return 'Mulai ${_tgl(mulai)}';
    return 'Sampai ${_tgl(selesai!)}';
  }

  /// Chip filter aktif dari sheet (tanpa pencarian dan status, yang punya
  /// kontrol sendiri). Rentang tanggal digabung jadi satu chip.
  List<FilterChipData> _chipFilterAktif() {
    final RiwayatFilter f = _filter;

    return <FilterChipData>[
      if (f.sumberData != null)
        FilterChipData(
          label: f.sumberData!,
          onRemove: () => _ubahFilter(f.copyWith(clearSumberData: true)),
        ),
      // DIHAPUS: chip statusVerifikasi, sekarang ada di StatusFilterBar.
      if (f.bidangUsaha != null)
        FilterChipData(
          label: BidangUsahaOpsi.namaDari(f.bidangUsaha) ?? f.bidangUsaha!,
          onRemove: () => _ubahFilter(f.copyWith(clearBidangUsaha: true)),
        ),
      if (f.kabupatenId != null)
        FilterChipData(
          label: _namaKabupaten(f.kabupatenId!),
          onRemove: () => _ubahFilter(f.copyWith(clearKabupatenId: true)),
        ),
      if (f.tanggalMulai != null || f.tanggalSelesai != null)
        FilterChipData(
          label: _labelTanggal(f.tanggalMulai, f.tanggalSelesai),
          onRemove: () => _ubahFilter(
            f.copyWith(clearTanggalMulai: true, clearTanggalSelesai: true),
          ),
        ),
    ];
  }

  // baris chip status (pilih satu) dengan jumlah per status.
  Widget _buildStatusBar() {
    final RiwayatRingkasan? r = _ringkasan;

    return StatusFilterBar(
      selected: _filter.statusVerifikasi,
      onChanged: _ubahStatus,
      options: <StatusFilterOption>[
        StatusFilterOption(
          value: null,
          label: 'Semua',
          color: AppTheme.primaryColor,
          count: r?.total,
        ),
        StatusFilterOption(
          value: 'DRAFT',
          label: 'Draft',
          color: AppTheme.warning,
          count: r?.draft,
        ),
        StatusFilterOption(
          value: 'SELESAI',
          label: 'Selesai',
          color: AppTheme.success,
          count: r?.selesai,
        ),
      ],
    );
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
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Riwayat',
          subtitle: 'Data Pengawasan yang Telah Dilakukan',
        ),
        actions: <Widget>[
          FilterAction(
            onPressed: _bukaFilter,
            activeCount: _filter.jumlahFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ListSearchField(
              controller: _searchController,
              hintText: 'Cari nama usaha, NIB, atau kode...',
              onChanged: _onSearchChanged,
              onSubmitted: (String v) {
                _debounce?.cancel();
                _terapkanPencarian(v);
              },
              onClear: _hapusPencarian,
            ),
          ),
          _buildStatusBar(),
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
          // DIUBAH: tanpa syarat items.isNotEmpty, sama seperti OTA, supaya
          // hasil kosong tetap menampilkan "0 riwayat".
          if (!_ctrl.loadingFirst && _ctrl.error == null)
            ListSummaryLine(total: _ctrl.total, satuan: 'riwayat'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.loadingFirst) {
      return const RiwayatSkeleton();
    }

    Future<void> segarkan() => _ctrl.reload(showLoading: false);

    // Error dan kosong dibungkus scrollable supaya layar tetap bisa ditarik.
    if (_ctrl.error != null) {
      return RefreshIndicator(
        onRefresh: segarkan,
        child: ScrollableFill(
          child: ConnectionErrorState(
            title: 'Riwayat gagal dimuat',
            message: _ctrl.error!,
            onRetry: _ctrl.reload,
          ),
        ),
      );
    }

    final List<RiwayatItem> items = _ctrl.items;

    if (items.isEmpty) {
      final bool adaFilter = _filter.hasActiveFilter;
      final bool adaCari = _filter.search.trim().isNotEmpty;

      return RefreshIndicator(
        onRefresh: segarkan,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            EmptyListState(
              icon: adaFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.inbox_outlined,
              title: adaFilter
                  ? 'Tidak ada yang cocok'
                  : 'Belum ada riwayat pengawasan',
              // DIUBAH: pesan dibedakan untuk pencarian, filter, dan kosong.
              message: adaCari
                  ? 'Tidak ada riwayat untuk kata kunci tersebut. '
                        'Coba kata kunci lain.'
                  : adaFilter
                  ? 'Tidak ada riwayat yang sesuai dengan filter yang '
                        'dipilih. Coba ubah atau hapus filternya.'
                  : 'Data akan muncul setelah ada pengawasan yang tersimpan.',
              actionLabel: adaFilter ? 'Hapus semua filter' : null,
              actionIcon: Icons.restart_alt_rounded,
              onAction: adaFilter ? _hapusSemuaFilter : null,
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final RiwayatItem item = items[index];
          return RiwayatCard(item: item, onTap: () => _bukaDetail(item));
        },
      ),
    );
  }

  Widget? _buildPaginasi() {
    // Sembunyi kalau error atau datanya muat dalam satu halaman terkecil.
    if (_ctrl.error != null || _ctrl.total <= PaginationBar.opsi.first) {
      return null;
    }
    return PaginationBar(
      currentPage: _ctrl.currentPage,
      totalPages: _ctrl.totalPages,
      perPage: _filter.perPage,
      total: _ctrl.total,
      enabled: !_ctrl.loadingFirst,
      onPageChanged: _ctrl.goToPage,
      onPerPageChanged: (int n) => _ubahFilter(_filter.copyWith(perPage: n)),
    );
  }
}
