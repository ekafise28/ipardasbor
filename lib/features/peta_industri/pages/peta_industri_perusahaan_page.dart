// lib/features/peta_industri/pages/peta_industri_perusahaan_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/core/api/api_exception.dart';
import 'package:ipardasbor/shared/pagination/back_to_top_mixin.dart';
import 'package:ipardasbor/shared/pagination/paginated_list_controller.dart';
import 'package:ipardasbor/shared/pagination/pagination_bar.dart';
import 'package:ipardasbor/shared/utils/csv_export.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart'
    show tampilkanPesan, bukaTautan, salinKeClipboard;
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show ListSearchField;
import 'package:ipardasbor/shared/widgets/list_parts.dart' show TintChip;
import 'package:ipardasbor/shared/widgets/page_states.dart'
    show ConnectionErrorState, EmptyListState;
import 'package:ipardasbor/shared/widgets/skeleton.dart'
    show PerusahaanSkeleton;

import '../models/peta_detail_model.dart';
import '../services/peta_industri_service.dart';

/// Daftar perusahaan di balik satu baris rekap (padanan halaman
/// /home/daftarUsaha di web). Paginasi dan pencarian dilakukan di server.
class PetaIndustriPerusahaanPage extends StatefulWidget {
  const PetaIndustriPerusahaanPage({
    super.key,
    required this.provinsi,
    required this.item,
  });

  final String provinsi;
  final PetaRekapItem item;

  @override
  State<PetaIndustriPerusahaanPage> createState() =>
      _PetaIndustriPerusahaanPageState();
}

class _PetaIndustriPerusahaanPageState extends State<PetaIndustriPerusahaanPage>
    with BackToTopMixin<PetaIndustriPerusahaanPage> {
  final PetaIndustriService _service = PetaIndustriService();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');
  final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final TextEditingController _searchCtrl = TextEditingController();

  late final PaginatedListController<PetaPerusahaanItem> _list;
  Timer? _debounce;
  int _perPage = 25;
  String _search = '';

  static const int _maksBaris = 50000;
  bool _mengekspor = false;
  int _terunduh = 0;

  @override
  void initState() {
    super.initState();
    initBackToTop();
    _list = PaginatedListController<PetaPerusahaanItem>(
      paged: true,
      fetchPage: _ambil,
      idOf: (PetaPerusahaanItem e) => e.id,
      perPage: () => _perPage,
      onSilentError: (String pesan) {
        if (mounted) tampilkanPesan(context, pesan);
      },
    );
    _list.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _list.dispose();
    disposeBackToTop();
    super.dispose();
  }

  // Mode halaman tidak memuat otomatis saat gulir.
  @override
  void onNearBottom() {}

  Future<void> _ekspor() async {
    if (_mengekspor) return;

    if (_list.total > _maksBaris) {
      final bool lanjut = await _konfirmasiBatas();
      if (!lanjut || !mounted) return;
    }

    setState(() {
      _mengekspor = true;
      _terunduh = 0;
    });

    try {
      final List<PetaPerusahaanItem> semua = <PetaPerusahaanItem>[];
      int afterId = 0;
      bool terpotong = false;

      while (true) {
        final hasil = await _service.ambilPerusahaanEkspor(
          widget.provinsi,
          kbli: widget.item.kbli,
          risiko: widget.item.risiko,
          search: _search,
          afterId: afterId,
        );
        if (!mounted) return;

        semua.addAll(hasil.items);
        setState(() => _terunduh = semua.length);

        final int? berikutnya = hasil.berikutnya;
        if (berikutnya == null) break;
        if (semua.length >= _maksBaris) {
          terpotong = true;
          break;
        }
        afterId = berikutnya;
      }

      if (semua.isEmpty) {
        tampilkanPesan(context, 'Tidak ada data untuk diekspor.');
        return;
      }

      // Urutan nama seperti di web (server mengirim menurut id agar cepat).
      semua.sort(
        (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
      );

      final String judul =
          'Daftar_Usaha_${widget.provinsi.trim().replaceAll(RegExp(r'\s+'), '_')}';

      await bagikanCsv(
        namaFile:
            'daftar-usaha-${slugFile(widget.provinsi)}-${widget.item.kbli}-${stempelFile()}.csv',
        subjek: 'Daftar Usaha ${widget.provinsi} (KBLI ${widget.item.kbli})',
        baris: <List<String>>[
          <String>[judul, '', '', '', ''],
          <String>[
            'Nama Perusahaan',
            'Alamat',
            'NIB',
            'Investasi',
            'Tenaga Kerja',
          ],
          for (final PetaPerusahaanItem e in semua)
            <String>[
              e.nama,
              e.alamat,
              e.nib,
              e.investasi.toString(),
              e.tenagaKerja.toString(),
            ],
        ],
      );

      if (mounted && terpotong) {
        tampilkanPesan(
          context,
          'Data baris melebihi batasan yaitu ${_angka.format(_maksBaris)}. '
          'Untuk mengunduh lebih dari batasan, silakan unduh dari web.',
        );
      }
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

  /// Alamat halaman daftar usaha di web (padanan /home/daftarUsaha).
  Uri _urlWeb() {
    final String base = ApiEndpoints.baseUrl.replaceFirst(
      RegExp(r'/api/?$'),
      '',
    );
    return Uri.parse('$base/home/daftarUsaha').replace(
      queryParameters: <String, String>{
        'provinsi': widget.provinsi,
        'kbli': widget.item.kbli,
        'risiko': widget.item.risiko,
      },
    );
  }

  Future<bool> _konfirmasiBatas() async {
    final bool? hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data melebihi batasan'),
        content: Text(
          'Data baris melebihi batasan yaitu ${_angka.format(_maksBaris)}. '
          'Untuk mengunduh lebih dari batasan, silakan unduh dari web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
              bukaTautan(context, _urlWeb().toString());
            },
            child: const Text('Buka web'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Unduh ${_angka.format(_maksBaris)} baris'),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  Future<PageChunk<PetaPerusahaanItem>> _ambil(int page) async {
    final PetaPerusahaanHalaman hasil = await _service.ambilPerusahaan(
      widget.provinsi,
      kbli: widget.item.kbli,
      risiko: widget.item.risiko,
      page: page,
      perPage: _perPage,
      search: _search,
    );

    return PageChunk<PetaPerusahaanItem>(
      items: hasil.items,
      currentPage: hasil.page,
      hasNext: hasil.hasMore,
      total: hasil.total,
    );
  }

  void _terapkanPencarian(String value) {
    _debounce?.cancel();
    final String kata = value.trim();
    if (kata == _search) return;
    _search = kata;
    jumpKeAtas();
    _list.reload();
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

  Future<void> _gantiHalaman(int page) async {
    await _list.goToPage(page);
    jumpKeAtas();
  }

  void _gantiPerPage(int n) {
    setState(() => _perPage = n);
    jumpKeAtas();
    _list.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Perusahaan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${widget.provinsi} • ${widget.item.kbli}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          if (_mengekspor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _angka.format(_terunduh),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Ekspor Excel',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _ekspor,
            ),
        ],
      ),
      floatingActionButton: buildBackToTopFab(),
      bottomNavigationBar: ListenableBuilder(
        listenable: _list,
        builder: (context, _) {
          if (_list.error != null ||
              (_list.total == 0 && !_list.loadingFirst)) {
            return const SizedBox.shrink();
          }
          return PaginationBar(
            currentPage: _list.currentPage,
            totalPages: _list.totalPages,
            perPage: _perPage,
            total: _list.total,
            enabled: !_list.loadingFirst,
            onPageChanged: _gantiHalaman,
            onPerPageChanged: _gantiPerPage,
          );
        },
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildRingkasan(),
          Expanded(
            child: ListenableBuilder(
              listenable: _list,
              builder: (context, _) => _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: ListSearchField(
        controller: _searchCtrl,
        hintText: 'Cari nama, NIB, atau alamat...',
        onChanged: _onSearchChanged,
        onSubmitted: _terapkanPencarian,
        onClear: _hapusPencarian,
      ),
    );
  }

  Widget _buildRingkasan() {
    final PetaRekapItem item = widget.item;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.namaKbli,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TintChip(
            label: item.risiko,
            color: AppTheme.warnaRisiko(item.risiko),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_list.loadingFirst) return const PerusahaanSkeleton();

    if (_list.error != null) {
      return ConnectionErrorState(
        title: 'Daftar perusahaan gagal dimuat',
        message: _list.error!,
        onRetry: _list.reload,
      );
    }

    if (_list.items.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyListState(
          icon: Icons.search_off_rounded,
          title: 'Perusahaan tidak ditemukan',
          message: 'Coba nama, NIB, atau alamat yang lain.',
        ),
      );
    }

    final List<PetaPerusahaanItem> items = _list.items;

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _PerusahaanCard(item: items[i], angka: _angka, rupiah: _rupiah),
    );
  }
}

class _PerusahaanCard extends StatelessWidget {
  const _PerusahaanCard({
    required this.item,
    required this.angka,
    required this.rupiah,
  });

  final PetaPerusahaanItem item;
  final NumberFormat angka;
  final NumberFormat rupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nama,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 15,
                color: AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.alamat,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TintChip(label: 'NIB ${item.nib}', color: AppTheme.primaryColor),
              TintChip(
                label: rupiah.format(item.investasi),
                color: AppTheme.success,
              ),
              TintChip(
                label: '${angka.format(item.tenagaKerja)} tenaga kerja',
                color: AppTheme.warning,
              ),
            ],
          ),
          if (item.adaNib || item.telepon != null || item.adaLokasi) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                // NIB
                if (item.adaNib)
                  _AksiKecil(
                    icon: Icons.copy_rounded,
                    label: 'Salin NIB',
                    onPressed: () => salinKeClipboard(context, item.nib, 'NIB'),
                  ),
                //Telepon
                if (item.telepon != null)
                  _AksiKecil(
                    icon: Icons.call_rounded,
                    label: 'Telepon',
                    onPressed: () => bukaTautan(
                      context,
                      'tel:${item.telepon}',
                      pesanGagal: 'Aplikasi telepon tidak dapat dibuka.',
                    ),
                  ),
                if (item.adaLokasi)
                  _AksiKecil(
                    icon: Icons.map_rounded,
                    label: 'Peta',
                    onPressed: () => bukaTautan(
                      context,
                      'https://www.google.com/maps/search/?api=1'
                      '&query=${item.latitude},${item.longitude}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AksiKecil extends StatelessWidget {
  const _AksiKecil({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
