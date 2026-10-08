import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ipardasbor/features/oss/oss_proyek_page.dart';

import '../../../app/app_theme.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

import '../models/baseline_ota_filter.dart';
import '../models/baseline_ota_item.dart';
import '../models/baseline_ota_page_result.dart';

import '../../non_oss/non_oss_form_page.dart';
import 'baseline_ota_detail_page.dart';

import '../../non_oss/services/region_service.dart';
import '../services/baseline_ota_service.dart';

import '../widgets/baseline_ota_filter_sheet.dart';
import '../widgets/baseline_ota_card.dart';
import '../widgets/baseline_ota_skeleton.dart';

class BaselineOtaPage extends StatefulWidget {
  const BaselineOtaPage({super.key});

  @override
  State<BaselineOtaPage> createState() => _BaselineOtaPageState();
}

class _BaselineOtaPageState extends State<BaselineOtaPage> {
  late final BaselineOtaService _service;
  final RegionService _regions = RegionService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  BaselineOtaFilter _filter = BaselineOtaFilter();
  BaselineOtaFilterOptions? _filterOptions;
  String _provinsiNama = '';
  String? _namaKecamatan;
  String? _namaKelurahan;

  final List<BaselineOtaItem> _items = [];
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _loadMoreError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = BaselineOtaService(ApiClient());
    _scroll.addListener(_onScroll);
    _muatHalamanPertama();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loadMoreError || _page >= _lastPage) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _muatHalamanBerikutnya();
    }
  }

  /// Naik setiap kali daftar dimuat ulang; respons lama diabaikan supaya
  /// hasil yang terlambat tidak menimpa hasil yang lebih baru.
  int _requestId = 0;

  Future<void> _muatHalamanPertama({bool tampilkanLoading = true}) async {
    final int id = ++_requestId;

    if (tampilkanLoading) {
      setState(() {
        _loadingFirst = true;
        _error = null;
      });
    }

    try {
      final BaselineOtaPageResult hasil = await _service.list(_filter, page: 1);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items
          ..clear()
          ..addAll(hasil.items);
        _page = hasil.currentPage;
        _lastPage = hasil.lastPage;
        _total = hasil.total;
        _filterOptions = hasil.filterOptions;
        _provinsiNama = hasil.provinsiNama;
        _filter.provinsiId ??= hasil.provinsiId;
        _error = null;
        _loadMoreError = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      final String pesan = _pesanRamah(e);

      if (!tampilkanLoading && _items.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pesan)));
      } else {
        setState(() => _error = pesan);
      }
    } finally {
      if (mounted && id == _requestId) setState(() => _loadingFirst = false);
    }
  }

  Future<void> _muatHalamanBerikutnya() async {
    final int id = _requestId;
    setState(() {
      _loadingMore = true;
      _loadMoreError = false;
    });
    try {
      final BaselineOtaPageResult hasil = await _service.list(
        _filter,
        page: _page + 1,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _items.addAll(hasil.items);
        _page = hasil.currentPage;
        _lastPage = hasil.lastPage;
        _total = hasil.total;
      });
    } catch (_) {
      if (mounted && id == _requestId) setState(() => _loadMoreError = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _bukaFilter() async {
    if (_filterOptions == null) return;
    final BaselineOtaFilter? hasil =
        await showModalBottomSheet<BaselineOtaFilter>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
      await _muatHalamanPertama();
    }
  }

  void _cari(String keyword) {
    FocusScope.of(context).unfocus();
    _filter.namaListing = keyword.trim().isEmpty ? null : keyword.trim();
    _muatHalamanPertama();
  }

  void _setStatus(String? status) {
    if (_filter.status == status) return;
    setState(() => _filter.status = status);
    _muatHalamanPertama();
  }

  /// Pesan dari server (ApiException) dipakai apa adanya; error teknis lain
  /// diganti pesan yang dimengerti pengguna.
  String _pesanRamah(Object e) {
    if (e is ApiException) return e.message;
    if (e is SocketException || e is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda lalu coba lagi.';
    }
    return 'Terjadi kesalahan saat memuat data. Silakan coba lagi.';
  }

  void _resetFilter() {
    _searchCtrl.clear();
    setState(() {
      _filter = _filter.reset();
      _namaKecamatan = null;
      _namaKelurahan = null;
    });
    _muatHalamanPertama();
  }

  Future<void> _setelahTersimpan() async {
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
    await _muatHalamanPertama(tampilkanLoading: false);
  }

  /// Jumlah filter yang tampil sebagai chip (status tidak dihitung karena
  /// sudah punya chip cepat sendiri, pencarian teks ada di kolom search).
  int get _jumlahFilterAktif =>
      (_filter.kabupatenId != null ? 1 : 0) +
      (_filter.kecamatanId != null ? 1 : 0) +
      (_filter.kelurahanId != null ? 1 : 0) +
      ((_filter.platformOta ?? '').trim().isNotEmpty ? 1 : 0);

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
    _muatHalamanPertama();
  }

  Widget _buildChipFilterAktif() {
    if (_jumlahFilterAktif == 0) return const SizedBox.shrink();

    final String? namaKab = _filterOptions?.kabupaten
        .where((e) => e.id == _filter.kabupatenId)
        .firstOrNull
        ?.name;

    InputChip chip(String label, VoidCallback onHapus) => InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      onDeleted: onHapus,
      deleteIconColor: AppTheme.textSecondary(context),
    );

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if ((_filter.platformOta ?? '').trim().isNotEmpty)
            chip(
              _filter.platformOta!,
              () => _ubahFilter(() => _filter.platformOta = null),
            ),
          if (_filter.kabupatenId != null)
            chip(
              namaKab ?? 'Kabupaten/Kota',
              () => _ubahFilter(() {
                _filter.kabupatenId = null;
                _filter.kecamatanId = null;
                _filter.kelurahanId = null;
                _namaKecamatan = null;
                _namaKelurahan = null;
              }),
            ),
          if (_filter.kecamatanId != null)
            chip(
              _namaKecamatan ?? 'Kecamatan',
              () => _ubahFilter(() {
                _filter.kecamatanId = null;
                _filter.kelurahanId = null;
                _namaKecamatan = null;
                _namaKelurahan = null;
              }),
            ),
          if (_filter.kelurahanId != null)
            chip(
              _namaKelurahan ?? 'Kelurahan/Desa',
              () => _ubahFilter(() {
                _filter.kelurahanId = null;
                _namaKelurahan = null;
              }),
            ),
        ].expand((w) => [w, const SizedBox(width: 8)]).toList(),
      ),
    );
  }

  void _todoVerifikasi(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alur "$label" belum tersambung - menyusul di batch berikutnya.',
        ),
      ),
    );
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
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssProyekPage(
          provinsiIdAwal: item.provinsiId,
          kabupatenIdAwal: item.kabupatenId,
          baselineOtaId: item.id,
        ),
      ),
    );
    if (tersimpan == true) await _setelahTersimpan();
  }

  Future<void> _bukaNonOss(BaselineOtaItem item, String memilikiNib) async {
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NonOssFormPage(
          memilikiNibTerkunci: memilikiNib,
          baselineOtaId: item.id,
        ),
      ),
    );
    if (tersimpan == true) await _setelahTersimpan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengawasan OTA',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'Verifikasi hasil scraping baseline OTA',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _jumlahFilterAktif > 0,
              label: Text('$_jumlahFilterAktif'),
              backgroundColor: Colors.amberAccent,
              textColor: Colors.black87,
              child: const Icon(Icons.filter_list_rounded, color: Colors.white),
            ),
            onPressed: _bukaFilter,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari listing, alamat, platform...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchCtrl,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchCtrl.clear();
                            _cari('');
                          },
                        ),
                ),
                filled: true,
                fillColor: AppTheme.surface(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onSubmitted: _cari,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children:
                    [
                      (null, 'Semua'),
                      ('BELUM', 'Belum diverifikasi'),
                      ('SUDAH', 'Terverifikasi'),
                    ].map((e) {
                      final (String? value, String label) = e;
                      return ChoiceChip(
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        selected: _filter.status == value,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _setStatus(value),
                      );
                    }).toList(),
              ),
            ),
          ),
          _buildChipFilterAktif(),
          if (!_loadingFirst && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_provinsiNama · $_total data ditemukan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingFirst) {
      return const BaselineOtaSkeletonList();
    }

    // Error dan kosong dibungkus ListView supaya layar tetap bisa ditarik.
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Icon(Icons.wifi_off_rounded, size: 42, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton(
                onPressed: _muatHalamanPertama,
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      final bool adaFilter = _filter.isActive;
      return RefreshIndicator(
        onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Icon(
              adaFilter ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              adaFilter
                  ? 'Tidak ada data yang cocok'
                  : 'Belum ada data hasil scraping OTA',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              adaFilter
                  ? 'Coba ubah atau hapus filter dan kata kunci pencarian.'
                  : 'Data akan muncul setelah proses scraping selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
            if (adaFilter) ...[
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset Filter'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length + (_page < _lastPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return _loadMoreError
                ? _FooterGagal(onRetry: _muatHalamanBerikutnya)
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
          }
          final BaselineOtaItem item = _items[index];
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
}

class _FooterGagal extends StatelessWidget {
  const _FooterGagal({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'Gagal memuat data berikutnya.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
