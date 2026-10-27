import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/core/cache/cache_status.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/shared/pagination/back_to_top_mixin.dart';
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart'
    show DataProyekSkeleton;

import '../../../app/app_theme.dart';
import 'models/okupansi_hotel_data.dart';
import 'models/okupansi_hotel_filter.dart';
import 'services/okupansi_hotel_service.dart';
import 'widgets/okupansi_filter_sheet.dart';
import 'widgets/okupansi_hotel_card.dart';
import 'widgets/okupansi_ranking_card.dart';
import 'widgets/okupansi_summary_card.dart';
import 'widgets/okupansi_trend_chart.dart';

/// Okupansi hotel (padanan halaman okupansi di web). Tab Ringkasan: angka,
/// grafik garis per bulan, peringkat. Tab Per Hotel: kartu hotel dengan
/// grid 12 bulan, berhalaman. Filter tahun/provinsi berlaku untuk keduanya.
class OkupansiHotelPage extends StatefulWidget {
  const OkupansiHotelPage({super.key});

  @override
  State<OkupansiHotelPage> createState() => _OkupansiHotelPageState();
}

class _OkupansiHotelPageState extends State<OkupansiHotelPage>
    with SingleTickerProviderStateMixin, BackToTopMixin<OkupansiHotelPage> {
  final OkupansiHotelService _service = OkupansiHotelService();
  final TextEditingController _searchController = TextEditingController();

  late final TabController _tab;
  late final PaginatedListController<OkupansiHotelRow> _ctrl;
  Timer? _debounce;

  OkupansiHotelFilter _filter = const OkupansiHotelFilter();
  OkupansiHotelResult? _hasil;

  bool get _tabHotel => _tab.index == 1;

  @override
  void initState() {
    super.initState();
    initBackToTop();

    _tab = TabController(length: 2, vsync: this)..addListener(_onTab);

    _ctrl = PaginatedListController<OkupansiHotelRow>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (OkupansiHotelRow e) => '${e.hotelId}|${e.tahun}',
      perPage: () => _filter.perPage,
      onLoaded: (PageChunk<OkupansiHotelRow> c) =>
          _hasil = c.meta! as OkupansiHotelResult,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    _ctrl.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tab
      ..removeListener(_onTab)
      ..dispose();
    disposeBackToTop();
    _searchController.dispose();
    _ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    super.dispose();
  }

  /// Mode halaman tidak memuat otomatis saat scroll mencapai dasar.
  @override
  void onNearBottom() {}

  Future<PageChunk<OkupansiHotelRow>> _ambilHalaman(int page) async {
    final OkupansiHotelResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<OkupansiHotelRow>(
      items: hasil.items,
      currentPage: hasil.pagination.currentPage,
      hasNext: hasil.pagination.hasNextPage,
      total: hasil.pagination.total,
      meta: hasil,
    );
  }

  void _onTab() {
    if (!mounted || _tab.indexIsChanging) return;
    setState(() {});
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {
      if (_ctrl.loadingFirst) hideBackToTop();
    });
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  /* ---------- filter & pencarian ---------- */

  void _ubahFilter(OkupansiHotelFilter baru) {
    setState(() => _filter = baru);
    jumpKeAtas();
    _ctrl.reload();
  }

  void _terapkanPencarian(String value) {
    if (value.trim() == _filter.search.trim()) return;
    _ubahFilter(_filter.copyWith(search: value));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => _terapkanPencarian(value),
    );
  }

  void _hapusPencarian() {
    _debounce?.cancel();
    _searchController.clear();
    _terapkanPencarian('');
  }

  void _hapusSemuaFilter() {
    _debounce?.cancel();
    _searchController.clear();
    _ubahFilter(OkupansiHotelFilter(perPage: _filter.perPage));
  }

  /// Reset tahun dan provinsi; pencarian dipertahankan.
  void _resetFilterSheet() => _ubahFilter(
    OkupansiHotelFilter(search: _filter.search, perPage: _filter.perPage),
  );

  Future<void> _bukaFilter() async {
    final OkupansiPilihan? p = await showOkupansiFilterSheet(
      context,
      service: _service,
      tahun: _filter.tahun,
      provinsi: _filter.provinsi,
    );
    if (p == null) return;
    _ubahFilter(_filter.copyWith(tahun: p.tahun, provinsi: p.provinsi));
  }

  List<FilterChipData> _chipFilterAktif() => <FilterChipData>[
    for (final int t in _filter.tahun)
      FilterChipData(
        label: 'Tahun $t',
        onRemove: () => _ubahFilter(
          _filter.copyWith(
            tahun: _filter.tahun.where((int e) => e != t).toList(),
          ),
        ),
      ),
    for (final String p in _filter.provinsi)
      FilterChipData(
        label: p,
        onRemove: () => _ubahFilter(
          _filter.copyWith(
            provinsi: _filter.provinsi.where((String e) => e != p).toList(),
          ),
        ),
      ),
  ];

  /* ---------- tampilan ---------- */

  Widget? _buildPaginasi() {
    if (!_tabHotel || _ctrl.error != null || _ctrl.total == 0) return null;
    return PaginationBar(
      currentPage: _ctrl.currentPage,
      totalPages: _ctrl.totalPages,
      perPage: _filter.perPage,
      total: _ctrl.total,
      enabled: !_ctrl.loadingFirst,
      onPageChanged: (int n) {
        _ctrl.goToPage(n);
        jumpKeAtas();
      },
      onPerPageChanged: (int n) => _ubahFilter(_filter.copyWith(perPage: n)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: _tabHotel ? buildBackToTopFab() : null,
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Okupansi Hotel',
          subtitle: 'Rata-rata per provinsi dan hotel',
        ),
        actions: <Widget>[
          FilterAction(
            onPressed: _bukaFilter,
            activeCount: _filter.jumlahFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const <Widget>[
            Tab(text: 'Ringkasan'),
            Tab(text: 'Per Hotel'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Builder(
            builder: (BuildContext context) {
              final List<FilterChipData> chips = _chipFilterAktif();
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActiveFilterChips(
                  chips: chips,
                  onResetAll: _resetFilterSheet,
                ),
              );
            },
          ),
          if (_ctrl.loadingFirst && _hasil != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildIsi(context)),
        ],
      ),
    );
  }

  Widget _buildIsi(BuildContext context) {
    if (_ctrl.loadingFirst && _hasil == null) {
      return const DataProyekSkeleton();
    }

    if (_ctrl.error != null) {
      return ConnectionErrorState(
        title: 'Data okupansi gagal dimuat',
        message: NetworkStatus.instance.value
            ? 'Tidak ada internet dan data untuk filter ini belum tersimpan. '
                  'Sambungkan internet, lalu coba lagi.'
            : _ctrl.error!,
        onRetry: _ctrl.reload,
      );
    }

    return TabBarView(
      controller: _tab,
      children: <Widget>[_tabRingkasan(), _tabHotelList()],
    );
  }

  /* ---------- tab Ringkasan ---------- */

  Widget _tabRingkasan() {
    final OkupansiHotelResult? h = _hasil;
    if (h == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _ctrl.reload(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          OkupansiSummaryCard(hasil: h),
          const SizedBox(height: 12),
          OkupansiTrendChart(
            series: h.series,
            seriesDipotong: h.seriesDipotong,
            totalSeries: h.totalSeries,
          ),
          const SizedBox(height: 12),
          OkupansiRankingCard(series: h.series),
        ],
      ),
    );
  }

  /* ---------- tab Per Hotel ---------- */

  Widget _buildKosong() {
    final bool adaFilter = _filter.hasActiveFilter;

    return EmptyListState(
      icon: adaFilter ? Icons.search_off_rounded : Icons.inbox_outlined,
      title: adaFilter ? 'Tidak ada yang cocok' : 'Belum ada data',
      message: adaFilter
          ? 'Tidak ada data okupansi yang sesuai dengan pencarian atau filter.'
          : 'Belum ada data okupansi hotel.',
      actionLabel: adaFilter ? 'Hapus semua filter' : null,
      onAction: adaFilter ? _hapusSemuaFilter : null,
    );
  }

  Widget _tabHotelList() {
    final List<OkupansiHotelRow> items = _ctrl.items;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ListSearchField(
            controller: _searchController,
            hintText: 'Cari nama hotel atau kab/kota',
            onChanged: _onSearchChanged,
            onSubmitted: (String v) {
              _debounce?.cancel();
              _terapkanPencarian(v);
            },
            onClear: _hapusPencarian,
          ),
        ),
        ListSummaryLine(
          total: _ctrl.total,
          satuan: 'data hotel',
          catatan: CacheStatus.instance.isOffline
              ? 'Data tersimpan. Pencarian atau filter baru perlu internet.'
              : null,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _ctrl.reload(showLoading: false),
            child: ListView.builder(
              controller: scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              itemCount: items.isEmpty ? 1 : items.length,
              itemBuilder: (BuildContext context, int i) {
                if (items.isEmpty) return _buildKosong();
                final OkupansiHotelRow item = items[i];
                return OkupansiHotelCard(
                  key: ValueKey<String>('${item.hotelId}|${item.tahun}'),
                  item: item,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
