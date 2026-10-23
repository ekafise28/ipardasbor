// lib/features/peta_industri/pages/peta_industri_detail_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_perusahaan_page.dart';
import 'package:ipardasbor/shared/pagination/back_to_top_mixin.dart'
    show BackToTopMixin;
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart'
    show PaginatedListController, PageChunk;
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/utils/csv_export.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart' show tampilkanPesan;
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show ListSearchField, StatusFilterBar, StatusFilterOption;
import 'package:ipardasbor/shared/widgets/list_parts.dart' show TintChip;
import 'package:ipardasbor/shared/widgets/page_states.dart'
    show ConnectionErrorState, EmptyListState;
import 'package:ipardasbor/shared/widgets/skeleton.dart' show RekapSkeleton;

import '../../../core/api/api_exception.dart';
import '../models/peta_detail_model.dart';
import '../services/peta_industri_service.dart';

/// Rekap jenis usaha / KBLI / risiko / jumlah proyek untuk satu provinsi
/// (padanan tombol "Detail" di web). Pencarian, pengurutan, dan paginasi
/// dilakukan di server; daftar dimuat bertahap saat di-scroll.
class PetaIndustriDetailPage extends StatefulWidget {
  const PetaIndustriDetailPage({super.key, required this.provinsi});

  final String provinsi;

  @override
  State<PetaIndustriDetailPage> createState() => _PetaIndustriDetailPageState();
}

class _OpsiUrut {
  const _OpsiUrut(this.label, this.sort, this.dir);

  final String label;
  final String sort;
  final String dir;
}

class _PetaIndustriDetailPageState extends State<PetaIndustriDetailPage>
    with BackToTopMixin<PetaIndustriDetailPage> {
  static const List<_OpsiUrut> _opsiUrut = <_OpsiUrut>[
    _OpsiUrut('Jumlah terbanyak', 'jumlah', 'desc'),
    _OpsiUrut('Jumlah tersedikit', 'jumlah', 'asc'),
    _OpsiUrut('Jenis usaha (A-Z)', 'jenis_usaha', 'asc'),
    _OpsiUrut('Nama KBLI (A-Z)', 'nama_kbli', 'asc'),
    _OpsiUrut('Kode KBLI', 'kbli', 'asc'),
  ];

  static const List<String> _opsiRisiko = <String>[
    'Rendah',
    'Menengah Rendah',
    'Menengah Tinggi',
    'Tinggi',
  ];

  String _risiko = ''; // kosong = semua

  final PetaIndustriService _service = PetaIndustriService();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _debounce;

  bool _mengekspor = false;
  int _urutIndex = 0;
  String _search = '';
  late final PaginatedListController<PetaRekapItem> _list;
  int _perPage = 25;

  Future<void> _ekspor() async {
    if (_mengekspor) return;
    setState(() => _mengekspor = true);

    try {
      final List<PetaRekapItem> data = await _service.ambilSemuaRekap(
        widget.provinsi,
      );

      if (!mounted) return;
      if (data.isEmpty) {
        tampilkanPesan(context, 'Tidak ada data untuk diekspor.');
        return;
      }

      await bagikanCsv(
        namaFile: 'rekap-${slugFile(widget.provinsi)}-${stempelFile()}.csv',
        subjek: 'Rekap Industri Pariwisata ${widget.provinsi}',
        baris: <List<String>>[
          <String>[
            'Jenis Usaha',
            'Nama KBLI',
            'KBLI',
            'Risiko',
            'Jumlah Proyek',
          ],
          for (final PetaRekapItem e in data)
            <String>[
              e.jenisUsaha,
              e.namaKbli,
              e.kbli,
              e.risiko,
              e.jumlah.toString(),
            ],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      tampilkanPesan(
        context,
        pesanErrorRamah(e, fallback: 'Ekspor gagal. Silakan coba lagi.'),
      );
    } finally {
      if (mounted) setState(() => _mengekspor = false);
    }
  }

  Future<PageChunk<PetaRekapItem>> _ambil(int page) async {
    final _OpsiUrut urut = _opsiUrut[_urutIndex];
    final PetaRekapHalaman hasil = await _service.ambilDetail(
      widget.provinsi,
      page: page,
      perPage: _perPage,
      search: _search,
      risiko: _risiko,
      sort: urut.sort,
      dir: urut.dir,
    );
    return PageChunk<PetaRekapItem>(
      items: hasil.items,
      currentPage: hasil.page,
      hasNext: hasil.hasMore,
      total: hasil.total,
    );
  }

  void _muatUlang() {
    jumpKeAtas();
    _list.reload();
  }

  Future<void> _gantiHalaman(int page) async {
    await _list.goToPage(page);
    jumpKeAtas();
  }

  void _gantiPerPage(int n) {
    setState(() => _perPage = n);
    _muatUlang();
  }

  @override
  void initState() {
    super.initState();
    initBackToTop();
    _list = PaginatedListController<PetaRekapItem>(
      paged: true,
      fetchPage: _ambil,
      idOf: (PetaRekapItem e) => '${e.kbli}|${e.risiko}|${e.jenisUsaha}',
      perPage: () => _perPage,
      errorMessage: (Object e) => pesanErrorRamah(
        e,
        fallback: 'Detail gagal dimuat. Silakan coba lagi.',
      ),
      onSilentError: (String pesan) {
        if (mounted) tampilkanPesan(context, pesan);
      },
    )..addListener(_onList);
    _list.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _list
      ..removeListener(_onList)
      ..dispose();
    disposeBackToTop();
    super.dispose();
  }

  /// Mode halaman tidak memuat otomatis saat gulir.
  @override
  void onNearBottom() {}

  void _onList() {
    if (!mounted) return;
    setState(() {
      if (_list.loadingFirst) hideBackToTop();
    });
  }

  void _terapkanPencarian(String value) {
    _debounce?.cancel();
    final String kata = value.trim();
    if (kata == _search) return;
    _search = kata;
    _muatUlang();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: buildBackToTopFab(),
      bottomNavigationBar: _buildPaginasi(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Rekap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.provinsi,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          _mengekspor
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Ekspor Excel',
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: _ekspor,
                ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRisiko(),
          _buildInfoBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget? _buildPaginasi() {
    if (_list.error != null || _list.total == 0) return null;
    return PaginationBar(
      currentPage: _list.currentPage,
      totalPages: _list.totalPages,
      perPage: _perPage,
      total: _list.total,
      enabled: !_list.loadingFirst,
      onPageChanged: _gantiHalaman,
      onPerPageChanged: _gantiPerPage,
    );
  }

  Widget _buildFilterRisiko() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: StatusFilterBar(
        options: <StatusFilterOption>[
          const StatusFilterOption(
            value: null,
            label: 'Semua',
            color: AppTheme.primaryColor,
          ),
          for (final String r in _opsiRisiko)
            StatusFilterOption(
              value: r,
              label: r,
              color: AppTheme.warnaRisiko(r),
            ),
        ],
        selected: _risiko.isEmpty ? null : _risiko,
        onChanged: (String? v) => _pilihRisiko(v ?? ''),
      ),
    );
  }

  void _pilihRisiko(String nilai) {
    if (nilai == _risiko) return;
    _risiko = nilai;
    _muatUlang();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: ListSearchField(
        controller: _searchCtrl,
        hintText: 'Cari jenis usaha, KBLI, atau risiko...',
        onChanged: _onSearchChanged,
        onSubmitted: _terapkanPencarian,
        onClear: _hapusPencarian,
      ),
    );
  }

  Widget _buildInfoBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _list.error == null && !_list.loadingFirst
                  ? '${_angka.format(_list.total)} baris'
                  : '',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Urutkan',
            initialValue: _urutIndex,
            onSelected: (int i) {
              if (i == _urutIndex) return;
              setState(() => _urutIndex = i);
              _muatUlang();
            },
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              for (int i = 0; i < _opsiUrut.length; i++)
                CheckedPopupMenuItem<int>(
                  value: i,
                  checked: i == _urutIndex,
                  child: Text(_opsiUrut[i].label),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _opsiUrut[_urutIndex].label,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_list.loadingFirst) return const RekapSkeleton();
    if (_list.error != null) {
      return ConnectionErrorState(
        title: 'Rekap gagal dimuat',
        message: _list.error!,
        onRetry: _list.reload,
      );
    }
    final List<PetaRekapItem> items = _list.items;
    if (items.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyListState(
          icon: Icons.search_off_rounded,
          title: 'Data tidak ditemukan',
          message: 'Coba kata kunci atau filter risiko yang lain.',
        ),
      );
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) => _RekapCard(
        item: items[i],
        angka: _angka,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PetaIndustriPerusahaanPage(
              provinsi: widget.provinsi,
              item: items[i],
            ),
          ),
        ),
      ),
    );
  }
}

class _RekapCard extends StatelessWidget {
  const _RekapCard({
    required this.item,
    required this.angka,
    required this.onTap,
  });

  final PetaRekapItem item;
  final NumberFormat angka;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.warnaRisiko(item.risiko);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.jenisUsaha.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.namaKbli,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TintChip(
                            label: 'KBLI ${item.kbli}',
                            color: AppTheme.textSecondary(context),
                          ),
                          TintChip(label: item.risiko, color: warna),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      angka.format(item.jumlah),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'proyek',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
