import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart'
    show catatanBulanTerakhir;
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
import 'package:ipardasbor/shared/widgets/tahun_provinsi_filter_sheet.dart';

import 'models/wisnus_bps_data.dart';
import 'models/wisnus_bps_filter.dart';
import 'services/wisnus_bps_service.dart';
import 'widgets/wisnus_bps_card.dart';

/// Wisatawan Nusantara (padanan web /wisnus, menu BPS). Satu halaman:
/// grafik garis per bulan, lalu rincian per provinsi dan tahun.
/// Default: tahun terbaru, semua provinsi.
class WisnusBpsPage extends StatefulWidget {
  const WisnusBpsPage({super.key});

  @override
  State<WisnusBpsPage> createState() => _WisnusBpsPageState();
}

class _WisnusBpsPageState extends State<WisnusBpsPage> {
  final WisnusBpsService _service = WisnusBpsService();

  late final PaginatedListController<WisnusBpsRow> _ctrl;

  WisnusBpsFilter _filter = const WisnusBpsFilter();
  WisnusBpsResult? _hasil;

  final GlobalKey _kunciRincian = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = PaginatedListController<WisnusBpsRow>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (WisnusBpsRow e) => e.kunci,
      perPage: () => _filter.perPage,
      onLoaded: (PageChunk<WisnusBpsRow> c) =>
          _hasil = c.meta! as WisnusBpsResult,
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

  Future<PageChunk<WisnusBpsRow>> _ambilHalaman(int page) async {
    final WisnusBpsResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<WisnusBpsRow>(
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

  void _ubahFilter(WisnusBpsFilter baru) {
    setState(() => _filter = baru);
    _ctrl.reload();
  }

  Future<void> _bukaFilter() async {
    final FilterPilihan? p = await showTahunProvinsiFilterSheet(
      context,
      loadOptions: _service.fetchOptions,
      tahun: _filter.tahun,
      provinsi: _filter.provinsi,
      title: 'Filter Wisatawan Nusantara',
      subtitle: 'Tahun dan provinsi',
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
      message: 'Belum ada data wisatawan nusantara untuk pilihan ini.',
      actionLabel: _filter.hasActiveFilter ? 'Kembali ke default' : null,
      onAction: _filter.hasActiveFilter
          ? () => _ubahFilter(_filter.reset())
          : null,
    );
  }

  /// Catatan di bawah legenda grafik: bulan terakhir yang punya data, dan
  /// alasan INDONESIA tidak digambar bila ada provinsi lain.
  String? _catatanGrafik(WisnusBpsResult h) {
    final List<String> bagian = <String>[
      if (h.nasionalTidakIkut)
        'Angka INDONESIA tidak ikut grafik karena jauh lebih besar dari '
            'provinsi; lihat di rincian.',
      ?(catatanBulanTerakhir(h.bulanTerakhir) == null
          ? null
          : 'Data ${catatanBulanTerakhir(h.bulanTerakhir)}'),
    ];
    return bagian.isEmpty ? null : bagian.join('\n');
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
          title: 'Wisatawan Nusantara',
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
        title: 'Data wisatawan gagal dimuat',
        message: NetworkStatus.instance.value
            ? 'Tidak ada internet dan data untuk filter ini belum tersimpan. '
                  'Sambungkan internet, lalu coba lagi.'
            : _ctrl.error!,
        onRetry: _ctrl.reload,
      );
    }

    final WisnusBpsResult? h = _hasil;
    if (h == null) return const SizedBox.shrink();

    // Tanpa data sama sekali: tampilkan keadaan kosong, bukan grafik kosong.
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
            child: WisatawanTrendChart(
              title: 'Wisatawan Nusantara per Bulan',
              series: h.series,
              seriesDipotong: h.seriesDipotong,
              totalSeries: h.totalSeries,
              catatan: _catatanGrafik(h),
            ),
          ),
          Padding(
            key: _kunciRincian,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Rekap per Provinsi',
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
          for (final WisnusBpsRow item in _ctrl.items)
            WisnusBpsCard(key: ValueKey<String>(item.kunci), item: item),
        ],
      ),
    );
  }
}
