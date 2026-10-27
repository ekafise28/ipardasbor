import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/core/cache/cache_status.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/features/hotel/data_hotel/pages/hotel_form_pages.dart'
    show HotelFormPage;
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
import 'models/hotel_filter.dart';
import 'models/hotel_item.dart';
import 'models/hotel_page_result.dart';
import 'services/data_hotel_service.dart';
import 'widgets/hotel_card.dart';
import 'widgets/hotel_detail_sheet.dart';
import 'widgets/hotel_filter_sheet.dart';
import 'widgets/hotel_provinsi_chart.dart';
import '../../../core/api/api_exception.dart' show pesanErrorRamah;
import '../../../core/storage/secure_storage.dart';

/// Data hotel (padanan halaman data-hotel di web): grafik jumlah hotel per
/// provinsi, pencarian, filter provinsi, dan detail. CRUD Admin ditambahkan
/// di batch berikutnya.
class DataHotelPage extends StatefulWidget {
  const DataHotelPage({super.key});

  @override
  State<DataHotelPage> createState() => _DataHotelPageState();
}

class _DataHotelPageState extends State<DataHotelPage>
    with BackToTopMixin<DataHotelPage> {
  final DataHotelService _service = DataHotelService();
  final TextEditingController _searchController = TextEditingController();

  /// Role yang boleh menambah/mengubah/menghapus. Untuk membuka akses role
  /// lain, aktifkan baris di bawahnya DAN ubah route API tulis menjadi
  /// RoleAkses::class.':Admin,Operator' (kedua sisi harus sama).
  static const List<String> _roleBolehKelola = <String>['Admin'];
  // static const List<String> _roleBolehKelola = <String>['Admin', 'Operator'];

  bool _bolehKelola = false;

  Future<void> _muatRole() async {
    final String? role = await SecureStorage.getUserRole();
    if (!mounted) return;
    setState(() => _bolehKelola = _roleBolehKelola.contains(role));
  }

  Timer? _debounce;
  late final PaginatedListController<HotelItem> _ctrl;

  HotelFilter _filter = const HotelFilter();
  HotelPageResult? _hasil;

  List<HotelChartPoint> get _chart =>
      _hasil?.chart ?? const <HotelChartPoint>[];

  @override
  void initState() {
    super.initState();
    initBackToTop();

    _ctrl = PaginatedListController<HotelItem>(
      paged: true,
      fetchPage: _ambilHalaman,
      idOf: (HotelItem e) => e.id,
      perPage: () => _filter.perPage,
      onLoaded: (PageChunk<HotelItem> c) => _hasil = c.meta! as HotelPageResult,
      onSilentError: _snack,
    )..addListener(_onCtrl);
    _ctrl.reload();
    unawaited(_muatRole());
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  Future<PageChunk<HotelItem>> _ambilHalaman(int page) async {
    final HotelPageResult hasil = await _service.fetch(
      filter: _filter,
      page: page,
    );
    return PageChunk<HotelItem>(
      items: hasil.items,
      currentPage: hasil.pagination.currentPage,
      hasNext: hasil.pagination.hasNextPage,
      total: hasil.pagination.total,
      meta: hasil,
    );
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

  void _ubahFilter(HotelFilter baru) {
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
    _ubahFilter(HotelFilter(perPage: _filter.perPage));
  }

  /// Reset provinsi saja; pencarian dipertahankan.
  void _resetProvinsi() => _ubahFilter(_filter.copyWith(provinsi: <String>[]));

  void _toggleProvinsi(String nama) {
    final List<String> baru = <String>[..._filter.provinsi];
    baru.contains(nama) ? baru.remove(nama) : baru.add(nama);
    _ubahFilter(_filter.copyWith(provinsi: baru));
  }

  Future<void> _bukaFilter() async {
    final List<String>? hasil = await showHotelFilterSheet(
      context,
      pilihan: <String>[for (final HotelChartPoint p in _chart) p.label]
        ..sort(),
      terpilih: _filter.provinsi,
    );
    if (hasil == null) return;
    _ubahFilter(_filter.copyWith(provinsi: hasil));
  }

  List<FilterChipData> _chipFilterAktif() => <FilterChipData>[
    for (final String p in _filter.provinsi)
      FilterChipData(label: p, onRemove: () => _toggleProvinsi(p)),
  ];

  List<String> get _daftarProvinsi =>
      <String>[for (final HotelChartPoint p in _chart) p.label]..sort();

  void _bukaDetail(HotelItem item) {
    showHotelDetailSheet(
      context,
      item: item,
      service: _service,
      footerBuilder: !_bolehKelola
          ? null
          : (BuildContext sheet, HotelItem h, bool lengkap) => _AksiAdmin(
              bisaUbah: lengkap,
              onUbah: () {
                Navigator.of(sheet).pop();
                _bukaForm(item: h);
              },
              onHapus: () => _konfirmasiHapus(sheet, h),
            ),
    );
  }

  Future<void> _bukaForm({HotelItem? item}) async {
    final bool? ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HotelFormPage(
          service: _service,
          item: item,
          provinsiSaran: _daftarProvinsi,
        ),
      ),
    );
    if (ok != true || !mounted) return;
    _snack(
      item == null
          ? 'Data hotel berhasil ditambahkan.'
          : 'Data hotel berhasil diperbarui.',
    );
    _ctrl.reload(showLoading: false);
  }

  Future<void> _konfirmasiHapus(BuildContext sheet, HotelItem h) async {
    final bool? yakin = await showDialog<bool>(
      context: sheet,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Hapus data hotel?'),
        content: Text('"${h.namaHotel}" akan dihapus permanen.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await _service.remove(h.id);
    } catch (e) {
      _snack(pesanErrorRamah(e, fallback: 'Data hotel gagal dihapus.'));
      return;
    }
    if (sheet.mounted) Navigator.of(sheet).pop();
    if (!mounted) return;
    _snack('Data hotel berhasil dihapus.');
    _ctrl.reload(showLoading: false);
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: buildBackToTopFab(),
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Data Hotel',
          subtitle: 'Hotel, karyawan, dan kapasitas',
        ),
        actions: <Widget>[
          if (_bolehKelola)
            IconButton(
              tooltip: 'Tambah hotel',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _bukaForm(),
            ),
          FilterAction(
            onPressed: _chart.isEmpty ? () {} : _bukaFilter,
            activeCount: _filter.provinsi.length,
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
              hintText: 'Cari nama hotel atau kab/kota',
              onChanged: _onSearchChanged,
              onSubmitted: (String v) {
                _debounce?.cancel();
                _terapkanPencarian(v);
              },
              onClear: _hapusPencarian,
            ),
          ),
          ActiveFilterChips(
            chips: _chipFilterAktif(),
            onResetAll: _resetProvinsi,
          ),
          if (_hasil != null && _ctrl.error == null)
            ListSummaryLine(
              total: _ctrl.total,
              satuan: 'hotel',
              catatan: CacheStatus.instance.isOffline
                  ? 'Data tersimpan. Pencarian atau filter baru perlu internet.'
                  : null,
            ),
          if (_ctrl.loadingFirst && _hasil != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    final bool adaFilter = _filter.hasActiveFilter;

    return EmptyListState(
      icon: adaFilter ? Icons.search_off_rounded : Icons.inbox_outlined,
      title: adaFilter ? 'Tidak ada yang cocok' : 'Belum ada data',
      message: adaFilter
          ? 'Tidak ada hotel yang sesuai dengan pencarian atau filter.'
          : 'Belum ada data hotel.',
      actionLabel: adaFilter ? 'Hapus semua filter' : null,
      onAction: adaFilter ? _hapusSemuaFilter : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_ctrl.loadingFirst && _hasil == null) {
      return const DataProyekSkeleton();
    }

    if (_ctrl.error != null) {
      return ConnectionErrorState(
        title: 'Data hotel gagal dimuat',
        message: NetworkStatus.instance.value
            ? 'Tidak ada internet dan data untuk pencarian atau filter ini '
                  'belum tersimpan. Sambungkan internet, lalu coba lagi.'
            : _ctrl.error!,
        onRetry: _ctrl.reload,
      );
    }

    final List<HotelItem> items = _ctrl.items;
    final int awal = _chart.isEmpty ? 0 : 1; // item pertama = grafik

    return RefreshIndicator(
      onRefresh: () => _ctrl.reload(showLoading: false),
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: awal + (items.isEmpty ? 1 : items.length),
        itemBuilder: (BuildContext context, int i) {
          if (i < awal) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: HotelProvinsiChart(
                data: _chart,
                selected: _filter.provinsi,
                onToggle: _toggleProvinsi,
                onReset: _resetProvinsi,
              ),
            );
          }
          if (items.isEmpty) return _buildKosong();

          final HotelItem item = items[i - awal];
          return HotelCard(
            key: ValueKey<int>(item.id),
            item: item,
            onTap: () => _bukaDetail(item),
          );
        },
      ),
    );
  }
}

class _AksiAdmin extends StatelessWidget {
  const _AksiAdmin({
    required this.bisaUbah,
    required this.onUbah,
    required this.onHapus,
  });

  final bool bisaUbah;
  final VoidCallback onUbah;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Hapus'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: bisaUbah ? onUbah : null,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ubah'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
      ],
    );
  }
}
