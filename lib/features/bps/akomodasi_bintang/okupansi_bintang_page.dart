import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/features/bps/akomodasi_bintang/widgets/okupansi_bintang_card.dart' show OkupansiBintangCard;
import 'package:ipardasbor/features/hotel/okupansi_hotel/widgets/okupansi_filter_sheet.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/widgets/okupansi_trend_chart.dart';
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart'
    show PaginationBar;
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart'
    show DataProyekSkeleton;

import 'models/okupansi_bintang_data.dart';
import 'models/okupansi_bintang_filter.dart';
import 'services/okupansi_bintang_service.dart';

/// Okupansi Akomodasi Bintang (padanan web /okupansi, menu BPS).
/// Satu halaman: grafik garis per bulan, lalu rincian (Batch 5).
/// Default: INDONESIA + tahun terbaru. Filter berlaku untuk keduanya.
class OkupansiBintangPage extends StatefulWidget {
  const OkupansiBintangPage({super.key});

  @override
  State<OkupansiBintangPage> createState() => _OkupansiBintangPageState();
}

class _OkupansiBintangPageState extends State<OkupansiBintangPage> {
  final OkupansiBintangService _service = OkupansiBintangService();

  late final PaginatedListController<OkupansiBintangRow> _ctrl;

  OkupansiBintangFilter _filter = const OkupansiBintangFilter();
  OkupansiBintangResult? _hasil;

  @override
  void initState() {
    super.initState();
    _ctrl = PaginatedListController<OkupansiBintangRow>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (OkupansiBintangRow e) => e.kunci,
      perPage: () => _filter.perPage,
      onLoaded: (PageChunk<OkupansiBintangRow> c) =>
          _hasil = c.meta! as OkupansiBintangResult,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    _ctrl.reload();
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    super.dispose();
  }

  Future<PageChunk<OkupansiBintangRow>> _ambilHalaman(int page) async {
    final OkupansiBintangResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<OkupansiBintangRow>(
      items: hasil.items,
      currentPage: hasil.pagination.currentPage,
      hasNext: hasil.pagination.hasNextPage,
      total: hasil.pagination.total,
      meta: hasil,
    );
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {});
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  final GlobalKey _kunciRincian = GlobalKey();

  void _keRincian() {
    final BuildContext? c = _kunciRincian.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget? _buildPaginasi() {
    if (_ctrl.error != null || _ctrl.total == 0) return null;
    return PaginationBar(
      currentPage: _ctrl.currentPage,
      totalPages: _ctrl.totalPages,
      perPage: _filter.perPage,
      total: _ctrl.total,
      enabled: !_ctrl.loadingFirst,
      onPageChanged: (int n) {
        _ctrl.goToPage(n);
        WidgetsBinding.instance.addPostFrameCallback((_) => _keRincian());
      },
      onPerPageChanged: (int n) => _ubahFilter(_filter.copyWith(perPage: n)),
    );
  }

  Widget _buildKosong() {
    return EmptyListState(
      icon: Icons.inbox_outlined,
      title: 'Belum ada data',
      message: 'Belum ada data okupansi untuk pilihan ini.',
      actionLabel: _filter.hasActiveFilter ? 'Kembali ke default' : null,
      onAction: _filter.hasActiveFilter
          ? () => _ubahFilter(_filter.reset())
          : null,
    );
  }

  /* ---------- filter ---------- */

  void _ubahFilter(OkupansiBintangFilter baru) {
    setState(() => _filter = baru);
    _ctrl.reload();
  }

  Future<void> _bukaFilter() async {
    final OkupansiPilihan? p = await showOkupansiFilterSheet(
      context,
      loadOptions: _service.fetchOptions,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Okupansi Akomodasi Bintang',
          subtitle: 'Per provinsi dan bulan',
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
          Builder(
            builder: (BuildContext context) {
              final List<FilterChipData> chips = _chipFilterAktif();
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActiveFilterChips(
                  chips: chips,
                  onResetAll: () => _ubahFilter(_filter.reset()),
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

    final OkupansiBintangResult? h = _hasil;
    if (h == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _ctrl.reload(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: <Widget>[
          if (_filter.tahun.isEmpty && h.tahun.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Tahun terbaru: ${h.tahun.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OkupansiTrendChart(
              series: h.series,
              seriesDipotong: h.seriesDipotong,
              totalSeries: h.totalSeries,
            ),
          ),
          Padding(
            key: _kunciRincian,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Rincian Data Okupansi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ),
                Text(
                  '${_ctrl.total} data',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          if (_ctrl.items.isEmpty)
            _buildKosong()
          else
            for (final OkupansiBintangRow item in _ctrl.items)
              OkupansiBintangCard(
                key: ValueKey<String>(item.kunci),
                item: item,
              ),
        ],
      ),
    );
  }
}
