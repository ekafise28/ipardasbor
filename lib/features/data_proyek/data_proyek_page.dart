import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/features/data_proyek/widgets/data_proyek_unduh_sheet.dart';
import 'package:ipardasbor/shared/pagination/back_to_top_mixin.dart';
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/widgets/animation.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';
import 'package:ipardasbor/shared/widgets/page_states.dart';

import '../../app/app_theme.dart';
import 'models/proyek_data_filter.dart';
import 'models/proyek_data_item.dart';
import 'models/proyek_data_page_result.dart';
import 'services/proyek_data_service.dart';
import 'widgets/data_proyek_card.dart';
import 'widgets/data_proyek_detail_sheet.dart';
import 'widgets/data_proyek_filter_sheet.dart';

/// Penelusuran data proyek dan pelaku usaha berdasarkan data BKPM
/// (padanan halaman IPAR Data di web). Paginasi mode halaman (10/25/50).
///
/// TODO(offline): halaman ini belum punya cache offline. Rencana, dikerjakan
/// belakangan:
///  - Tombol "Unduh untuk offline" di AppBar. Manual, TIDAK otomatis.
///  - Batas maksimal memori/ukuran unduhan (ikuti CachePreferences.maxBytes
///    atau batas khusus yang bisa diatur user).
///  - Progres unduhan (mis. "3 dari 10 halaman", persen) dan tombol batal.
///  - Simpan lewat ApiCache/OfflineDatabase, terenkripsi per akun.
///  - Saat offline, tampilkan hanya data yang sudah diunduh dan beri tahu
///    bahwa filter/pencarian baru butuh koneksi.
class DataProyekPage extends StatefulWidget {
  const DataProyekPage({super.key});

  @override
  State<DataProyekPage> createState() => _DataProyekPageState();
}

class _DataProyekPageState extends State<DataProyekPage>
    with SingleTickerProviderStateMixin, BackToTopMixin<DataProyekPage> {
  final ProyekDataService _service = ProyekDataService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;
  late final AnimationController _entrance;
  late final PaginatedListController<ProyekDataItem> _ctrl;
  bool _sedangMuat = true;

  ProyekDataFilter _filter = const ProyekDataFilter();
  ProyekDataPageResult? _hasil;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    initBackToTop();

    _ctrl = PaginatedListController<ProyekDataItem>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (ProyekDataItem e) => e.id,
      perPage: () => _filter.perPage,
      onLoaded: _setelahDimuat,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    _ctrl.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _entrance.dispose();
    disposeBackToTop();
    _searchController.dispose();
    _searchFocus.dispose();
    _ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    super.dispose();
  }

  /// Mode halaman tidak memuat otomatis saat scroll mencapai dasar.
  @override
  void onNearBottom() {}

  void _bukaUnduh() => showDataProyekUnduhSheet(
    context,
    filter: _filter,
    service: _service,
    total: _ctrl.total,
  );

  Future<PageChunk<ProyekDataItem>> _ambilHalaman(int page) async {
    final ProyekDataPageResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<ProyekDataItem>(
      items: hasil.items,
      currentPage: hasil.pagination.currentPage,
      hasNext: hasil.pagination.hasNextPage,
      total: hasil.pagination.total,
      meta: hasil,
    );
  }

  void _setelahDimuat(PageChunk<ProyekDataItem> chunk) {
    _hasil = chunk.meta! as ProyekDataPageResult;
  }

  void _onCtrl() {
    if (!mounted) return;
    final bool baruSelesai = _sedangMuat && !_ctrl.loadingFirst;
    _sedangMuat = _ctrl.loadingFirst;
    setState(() {
      if (_ctrl.loadingFirst) hideBackToTop();
    });
    if (baruSelesai && _ctrl.error == null) _entrance.forward(from: 0);
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  /* ---------- filter & pencarian ---------- */

  void _ubahFilter(ProyekDataFilter baru) {
    setState(() => _filter = baru);
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
    _ubahFilter(ProyekDataFilter(perPage: _filter.perPage));
  }

  /// Reset filter sheet saja; pencarian dipertahankan.
  void _resetFilterSheet() => _ubahFilter(
    ProyekDataFilter(search: _filter.search, perPage: _filter.perPage),
  );

  Future<void> _bukaFilter() async {
    final ProyekDataFilter? hasil = await showDataProyekFilterSheet(
      context,
      filter: _filter,
      service: _service,
      provinsiTerkunci: _hasil?.provinsiUser,
    );
    if (hasil == null) return;
    _ubahFilter(hasil);
  }

  List<FilterChipData> _chipFilterAktif() {
    final ProyekDataFilter f = _filter;
    final List<FilterChipData> chips = <FilterChipData>[];

    if (f.provinsi != null) {
      chips.add(
        FilterChipData(
          label: f.provinsi!,
          onRemove: () => _ubahFilter(f.denganProvinsi(null)),
        ),
      );
    }
    for (final String k in f.kota) {
      chips.add(
        FilterChipData(
          label: k,
          onRemove: () => _ubahFilter(
            f.copyWith(kota: f.kota.where((String e) => e != k).toList()),
          ),
        ),
      );
    }
    for (final String k in f.kbli) {
      chips.add(
        FilterChipData(
          label: 'KBLI $k',
          onRemove: () => _ubahFilter(
            f.copyWith(kbli: f.kbli.where((String e) => e != k).toList()),
          ),
        ),
      );
    }
    for (final String s in f.statusModal) {
      chips.add(
        FilterChipData(
          label: s,
          onRemove: () => _ubahFilter(
            f.copyWith(
              statusModal: f.statusModal.where((String e) => e != s).toList(),
            ),
          ),
        ),
      );
    }
    for (final String r in f.risiko) {
      chips.add(
        FilterChipData(
          label: 'Risiko $r',
          onRemove: () => _ubahFilter(
            f.copyWith(risiko: f.risiko.where((String e) => e != r).toList()),
          ),
        ),
      );
    }
    if (f.versiKbli != null) {
      chips.add(
        FilterChipData(
          label: 'Versi KBLI ${f.versiKbli}',
          onRemove: () => _ubahFilter(f.copyWith(clearVersiKbli: true)),
        ),
      );
    }
    return chips;
  }

  /* ---------- tampilan ---------- */

  Widget? _buildPaginasi() {
    if (_ctrl.error != null || _ctrl.total == 0) return null;
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

  @override
  Widget build(BuildContext context) {
    final ProyekDataPageResult? h = _hasil;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: buildBackToTopFab(),
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Data Proyek',
          subtitle: 'Penelusuran data proyek BKPM',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Unduh CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: (_ctrl.loadingFirst || _ctrl.total == 0)
                ? null
                : _bukaUnduh,
          ),
          // TODO(offline): tombol "Unduh untuk offline" (lihat catatan kelas).
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
              focusNode: _searchFocus,
              hintText: 'Cari NIB, KBLI, atau nama perusahaan',
              contohSaatFokus:
                  'NIB dan KBLI diketik lengkap · nama cukup awalannya',
              onChanged: _onSearchChanged,
              onSubmitted: (String v) {
                _debounce?.cancel();
                _terapkanPencarian(v);
              },
              onClear: _hapusPencarian,
            ),
          ),
          Builder(
            builder: (BuildContext context) {
              final List<FilterChipData> chips = _chipFilterAktif();
              if (chips.isEmpty) return const SizedBox.shrink();
              return ActiveFilterChips(
                chips: chips,
                onResetAll: _resetFilterSheet,
              );
            },
          ),
          if (h != null && _ctrl.error == null)
            ListSummaryLine(
              provinsi: _filter.provinsi ?? h.provinsiUser,
              total: _ctrl.total,
              satuan: 'proyek',
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    final bool adaPencarian = _filter.search.trim().isNotEmpty;
    final bool adaFilter = _filter.hasActiveFilter;

    final String judul;
    final String isi;
    if (adaPencarian) {
      judul = 'Data tidak ditemukan';
      isi =
          'Pastikan NIB atau KBLI diketik lengkap. Pencarian nama '
          'perusahaan cocok dari huruf awalnya.';
    } else if (adaFilter) {
      judul = 'Tidak ada yang cocok';
      isi = 'Tidak ada proyek yang sesuai dengan filter yang dipilih.';
    } else {
      judul = 'Belum ada data';
      isi = 'Belum ada data proyek pada wilayah ini.';
    }

    return EmptyListState(
      icon: adaFilter ? Icons.search_off_rounded : Icons.inbox_outlined,
      title: judul,
      message: isi,
      actionLabel: adaFilter ? 'Hapus semua filter' : null,
      onAction: adaFilter ? _hapusSemuaFilter : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_ctrl.loadingFirst) {
      return const LoadingState(message: 'Memuat data proyek...');
    }

    if (_ctrl.error != null) {
      return ConnectionErrorState(
        title: 'Data proyek gagal dimuat',
        message: _ctrl.error!,
        onRetry: _ctrl.reload,
      );
    }

    final List<ProyekDataItem> items = _ctrl.items;

    return RefreshIndicator(
      onRefresh: () => _ctrl.reload(showLoading: false),
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: items.isEmpty ? 1 : items.length,
        itemBuilder: (BuildContext context, int i) {
          if (items.isEmpty) return _buildKosong();

          final ProyekDataItem item = items[i];
          final Widget kartu = DataProyekCard(
            key: ValueKey<int>(item.id),
            item: item,
            onTap: () => showDataProyekDetailSheet(context, item),
          );

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
