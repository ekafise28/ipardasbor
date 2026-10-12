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
import '../../non_oss/models/location_fetch_status.dart';

import '../../non_oss/non_oss_form_page.dart';
import 'baseline_ota_detail_page.dart';

import '../../non_oss/services/region_service.dart';
import '../../oss/widgets/oss_proyek_filter_chips.dart'
    show OssActiveFilterChips, OssFilterChipData;
import '../../../shared/gps/gps_capture_mixin.dart';
import '../../../shared/utils/skeleton.dart';
import '../../../shared/widgets/connection_error_state.dart';
import '../../../shared/widgets/list_states.dart';
import '../services/baseline_ota_service.dart';

import '../widgets/baseline_ota_filter_sheet.dart';
import '../widgets/baseline_ota_card.dart';

class BaselineOtaPage extends StatefulWidget {
  const BaselineOtaPage({super.key});

  @override
  State<BaselineOtaPage> createState() => _BaselineOtaPageState();
}

class _BaselineOtaPageState extends State<BaselineOtaPage>
    with WidgetsBindingObserver, GpsCaptureMixin<BaselineOtaPage> {
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
    initGpsCapture();
    _service = BaselineOtaService(ApiClient());
    _scroll.addListener(_onScroll);
    _muatHalamanPertama();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    disposeGpsCapture();
    super.dispose();
  }

  /// Tombol "kembali ke atas" tampil setelah digulir cukup jauh.
  bool _showBackToTop = false;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final ScrollPosition pos = _scroll.position;

    final bool perluTampil = pos.pixels > 400;
    if (perluTampil != _showBackToTop) {
      setState(() => _showBackToTop = perluTampil);
    }

    if (_loadingMore || _loadMoreError || _page >= _lastPage) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _muatHalamanBerikutnya();
    }
  }

  void _scrollKeAtas() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
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
        _showBackToTop = false;
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

  /// Catatan kalau jarak dihitung dari lokasi tersimpan, bukan posisi sekarang.
  String? _infoLokasi;

  Future<void> _toggleDekatSaya() async {
    if (_filter.urutJarak) {
      setState(() {
        _filter.lat = null;
        _filter.lng = null;
        _infoLokasi = null;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
      await _muatHalamanPertama();
      return;
    }

    await ambilLokasiGps(
      onBerhasil: (hasil) {
        setState(() {
          _filter.lat = hasil.position.latitude;
          _filter.lng = hasil.position.longitude;
          _infoLokasi = hasil.source == LocationSource.gpsLangsung
              ? null
              : 'Memakai lokasi tersimpan, bukan posisi Anda saat ini.';
        });
        if (_scroll.hasClients) _scroll.jumpTo(0);
        _muatHalamanPertama();
      },
    );
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

  /// Menghapus SEMUA filter: pencarian, status, wilayah, platform, dan
  /// mode "Dekat saya". Hanya provinsi dan jumlah per halaman dipertahankan.
  void _resetFilter() {
    _searchCtrl.clear();
    setState(() {
      _filter = _filter.reset();
      _filter.lat = null;
      _filter.lng = null;
      _infoLokasi = null;
      _namaKecamatan = null;
      _namaKelurahan = null;
    });
    _muatHalamanPertama();
  }

  /// Reset dari chip filter aktif ("Reset"): hanya filter dari sheet
  /// (wilayah + platform). Pencarian, status, dan "Dekat saya" dipertahankan.
  void _resetFilterSheet() {
    setState(() {
      _filter = BaselineOtaFilter(
        provinsiId: _filter.provinsiId,
        perPage: _filter.perPage,
        status: _filter.status,
        namaListing: _filter.namaListing,
        lat: _filter.lat,
        lng: _filter.lng,
      );
      _namaKecamatan = null;
      _namaKelurahan = null;
    });
    _muatHalamanPertama();
  }

  Future<void> _setelahTersimpan(BaselineOtaItem item) async {
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
    await _segarkanItem(item);
  }

  /// Memuat ulang HANYA halaman server yang memuat [item], lalu mengganti
  /// irisan itu di daftar. Posisi scroll dan halaman lain tidak berubah.
  ///
  /// Muat ulang penuh (kembali ke halaman 1) dipakai kalau irisan tidak bisa
  /// diganti dengan aman: item sudah tidak ada di hasil (mis. filter "BELUM"
  /// aktif, jadi item yang baru diverifikasi tersaring keluar dan baris di
  /// halaman-halaman setelahnya bergeser), atau jumlah barisnya berbeda.
  Future<void> _segarkanItem(BaselineOtaItem item) async {
    final int index = _items.indexWhere((BaselineOtaItem e) => e.id == item.id);
    if (index < 0) {
      await _muatHalamanPertama(tampilkanLoading: false);
      return;
    }

    final int id = _requestId;
    final int perPage = _filter.perPage;
    final int halaman = index ~/ perPage + 1;
    final int awal = (halaman - 1) * perPage;
    final int akhir = awal + perPage < _items.length
        ? awal + perPage
        : _items.length;

    try {
      final BaselineOtaPageResult hasil = await _service.list(
        _filter,
        page: halaman,
      );
      if (!mounted || id != _requestId) return;

      final bool masihAda = hasil.items.any(
        (BaselineOtaItem e) => e.id == item.id,
      );
      if (!masihAda || hasil.items.length != akhir - awal) {
        await _muatHalamanPertama(tampilkanLoading: false);
        return;
      }

      setState(() {
        _items.replaceRange(awal, akhir, hasil.items);
        _total = hasil.total;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Daftar belum diperbarui. Tarik ke bawah untuk menyegarkan.',
          ),
        ),
      );
    }
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

  /// Data chip filter aktif dari sheet (platform + wilayah), dirender oleh
  /// OssActiveFilterChips yang sama dengan halaman OSS.
  List<OssFilterChipData> _chipFilterAktif() {
    final String? namaKab = _filterOptions?.kabupaten
        .where((e) => e.id == _filter.kabupatenId)
        .firstOrNull
        ?.name;

    return <OssFilterChipData>[
      if ((_filter.platformOta ?? '').trim().isNotEmpty)
        OssFilterChipData(
          label: _filter.platformOta!,
          onRemove: () => _ubahFilter(() => _filter.platformOta = null),
        ),
      if (_filter.kabupatenId != null)
        OssFilterChipData(
          label: namaKab ?? 'Kabupaten/Kota',
          onRemove: () => _ubahFilter(() {
            _filter.kabupatenId = null;
            _filter.kecamatanId = null;
            _filter.kelurahanId = null;
            _namaKecamatan = null;
            _namaKelurahan = null;
          }),
        ),
      if (_filter.kecamatanId != null)
        OssFilterChipData(
          label: _namaKecamatan ?? 'Kecamatan',
          onRemove: () => _ubahFilter(() {
            _filter.kecamatanId = null;
            _filter.kelurahanId = null;
            _namaKecamatan = null;
            _namaKelurahan = null;
          }),
        ),
      if (_filter.kelurahanId != null)
        OssFilterChipData(
          label: _namaKelurahan ?? 'Kelurahan/Desa',
          onRemove: () => _ubahFilter(() {
            _filter.kelurahanId = null;
            _namaKelurahan = null;
          }),
        ),
    ];
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
    if (tersimpan == true) await _setelahTersimpan(item);
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
    if (tersimpan == true) await _setelahTersimpan(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton:
          _showBackToTop && !_loadingFirst && _error == null && _items.isNotEmpty
          ? FloatingActionButton.small(
              onPressed: _scrollKeAtas,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
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
                  builder: (_, value, _) => value.text.isEmpty
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
          _buildBarisFilterCepat(),
          Builder(
            builder: (BuildContext context) {
              final List<OssFilterChipData> chips = _chipFilterAktif();
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OssActiveFilterChips(
                  chips: chips,
                  onResetAll: _resetFilterSheet,
                ),
              );
            },
          ),
          if (!_loadingFirst && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_provinsiNama · $_total data ditemukan'
                      '${_filter.urutJarak ? ' · terdekat dulu' : ''}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    if (_filter.urutJarak && _infoLokasi != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _infoLokasi!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFD08A00),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Satu baris chip yang bisa digeser: pilihan status (pilih satu), pemisah
  /// tipis, lalu "Dekat saya" (mode urutan, bukan status). Tingginya tetap
  /// sehingga header tidak melompat di layar sempit.
  Widget _buildBarisFilterCepat() {
    const List<(String?, String)> opsiStatus = <(String?, String)>[
      (null, 'Semua'),
      ('BELUM', 'Belum diverifikasi'),
      ('SUDAH', 'Terverifikasi'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          for (final (String? value, String label) in opsiStatus)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12.5)),
                selected: _filter.status == value,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _setStatus(value),
              ),
            ),
          Center(
            child: Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.only(left: 2, right: 10),
              color: AppTheme.border(context),
            ),
          ),
          FilterChip(
            avatar: gpsLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.near_me_rounded, size: 16),
            label: const Text('Dekat saya', style: TextStyle(fontSize: 12.5)),
            selected: _filter.urutJarak,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: gpsLoading ? null : (_) => _toggleDekatSaya(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingFirst) {
      return const BaselineOtaSkeleton();
    }

    // Error dan kosong dibungkus scrollable supaya layar tetap bisa ditarik.
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
        child: ScrollableFill(
          child: ConnectionErrorState(
            title: 'Listing OTA gagal dimuat',
            message: _error!,
            onRetry: _muatHalamanPertama,
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      final bool adaFilter = _filter.isActive || _filter.urutJarak;
      return RefreshIndicator(
        onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyListState(
              icon: adaFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.inbox_outlined,
              title: adaFilter
                  ? 'Tidak ada data yang cocok'
                  : 'Belum ada data hasil scraping OTA',
              message: adaFilter
                  ? 'Coba ubah atau hapus filter dan kata kunci pencarian.'
                  : 'Data akan muncul setelah proses scraping selesai.',
              actionLabel: adaFilter ? 'Reset Filter' : null,
              actionIcon: Icons.restart_alt_rounded,
              onAction: adaFilter ? _resetFilter : null,
            ),
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
            return LoadMoreFooter(
              gagal: _loadMoreError,
              onCobaLagi: _muatHalamanBerikutnya,
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