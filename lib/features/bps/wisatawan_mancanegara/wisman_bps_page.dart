import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/features/bps/shared/widgets/wisatawan_filter_sheet.dart';
import 'package:ipardasbor/features/bps/shared/widgets/wisatawan_trend_chart.dart';
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart'
    show PaginationBar;
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart'
    show DataProyekSkeleton;

import 'models/wisman_bps_data.dart';
import 'models/wisman_bps_filter.dart';
import 'services/wisman_bps_service.dart';
import 'widgets/wisman_bps_card.dart';
import 'widgets/wisman_bps_summary_card.dart';
import 'wisman_bps_style.dart';

/// Wisatawan Mancanegara (padanan web /wisman, menu BPS). Satu halaman:
/// ringkasan, grafik garis per bulan untuk tiap jenis pintu, lalu rincian
/// per nama pintu. Default: tahun terbaru, semua pintu dan provinsi.
class WismanBpsPage extends StatefulWidget {
  const WismanBpsPage({super.key});

  @override
  State<WismanBpsPage> createState() => _WismanBpsPageState();
}

class _WismanBpsPageState extends State<WismanBpsPage> {
  final WismanBpsService _service = WismanBpsService();

  late final PaginatedListController<WismanBpsRow> _ctrl;

  WismanBpsFilter _filter = const WismanBpsFilter();
  WismanBpsResult? _hasil;

  final GlobalKey _kunciRincian = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = PaginatedListController<WismanBpsRow>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (WismanBpsRow e) => e.kunci,
      perPage: () => _filter.perPage,
      onLoaded: (PageChunk<WismanBpsRow> c) =>
          _hasil = c.meta! as WismanBpsResult,
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

  Future<PageChunk<WismanBpsRow>> _ambilHalaman(int page) async {
    final WismanBpsResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<WismanBpsRow>(
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

  void _keRincian() {
    final BuildContext? c = _kunciRincian.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /* ---------- filter ---------- */

  void _ubahFilter(WismanBpsFilter baru) {
    setState(() => _filter = baru);
    _ctrl.reload();
  }

  Future<void> _bukaFilter() async {
    final WisatawanPilihan? p = await showWisatawanFilterSheet(
      context,
      loadOptions: _service.fetchOptions,
      tahun: _filter.tahun,
      pintuMasuk: _filter.pintuMasuk,
      provinsi: _filter.provinsi,
      tampilPintu: true,
      title: 'Filter Wisatawan Mancanegara',
      subtitle: 'Tahun, pintu masuk, dan provinsi',
    );
    if (p == null) return;
    _ubahFilter(
      _filter.copyWith(
        tahun: p.tahun,
        pintuMasuk: p.pintuMasuk,
        provinsi: p.provinsi,
      ),
    );
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
    for (final String p in _filter.pintuMasuk)
      FilterChipData(
        label: p,
        onRemove: () => _ubahFilter(
          _filter.copyWith(
            pintuMasuk: _filter.pintuMasuk.where((String e) => e != p).toList(),
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
      message: 'Belum ada data wisatawan mancanegara untuk pilihan ini.',
      actionLabel: _filter.hasActiveFilter ? 'Kembali ke default' : null,
      onAction: _filter.hasActiveFilter
          ? () => _ubahFilter(_filter.reset())
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Wisatawan Mancanegara',
          subtitle: 'Per pintu masuk dan bulan',
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
        title: 'Data wisatawan gagal dimuat',
        message: NetworkStatus.instance.value
            ? 'Tidak ada internet dan data untuk filter ini belum tersimpan. '
                  'Sambungkan internet, lalu coba lagi.'
            : _ctrl.error!,
        onRetry: _ctrl.reload,
      );
    }

    final WismanBpsResult? h = _hasil;
    if (h == null) return const SizedBox.shrink();

    // Tanpa data sama sekali: tampilkan keadaan kosong, bukan kartu bernilai 0.
    if (_ctrl.total == 0) {
      return RefreshIndicator(
        onRefresh: () => _ctrl.reload(showLoading: false),
        child: ScrollableFill(child: _buildKosong()),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _ctrl.reload(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WismanBpsSummaryCard(
              hasil: h,
              tahunOtomatis: _filter.tahun.isEmpty,
            ),
          ),
          for (final WismanBpsGrup g in h.grup)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: WisatawanTrendChart(
                key: ValueKey<String>('grafik-${g.pintuMasuk}'),
                title: '${g.pintuMasuk} per Bulan',
                icon: ikonPintu(g.pintuMasuk),
                series: g.series,
                seriesDipotong: g.seriesDipotong,
                totalSeries: g.totalSeries,
              ),
            ),
          Padding(
            key: _kunciRincian,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Rincian per Pintu Masuk',
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
          for (final WismanBpsRow item in _ctrl.items)
            WismanBpsCard(key: ValueKey<String>(item.kunci), item: item),
        ],
      ),
    );
  }
}