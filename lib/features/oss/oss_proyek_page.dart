import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/features/oss/oss_proyek_filter_sheet.dart';

import '../../app/app_theme.dart';
import '../../core/api/api_exception.dart';
import '../riwayat/models/riwayat_page_result.dart' show RiwayatPagination;
import '../riwayat/pages/riwayat_detail_page.dart';
import '../../shared/widgets/connection_error_state.dart';
import 'models/oss_proyek_filter.dart';
import 'models/oss_proyek_item.dart';
import 'models/oss_proyek_page_result.dart';
import 'pages/oss_validasi_page.dart';
import 'services/oss_proyek_service.dart';
import 'widgets/oss_proyek_card.dart';

/// Daftar usaha akomodasi OSS yang perlu diverifikasi.
///
/// Padanan tabel "Daftar Pengawasan OSS Akomodasi" di web: pencarian NIB/NKU,
/// filter wilayah, infinite scroll, dan tarik untuk menyegarkan.
class OssProyekPage extends StatefulWidget {
  const OssProyekPage({
    super.key,
    this.provinsiIdAwal,
    this.kabupatenIdAwal,
    this.baselineOtaId,
    this.bidang = 'akomodasi',
    this.namaBidang,
  });

  /// Slug bidang usaha (key di config bidang_usaha_pariwisata).
  final String bidang;
  final String? namaBidang;

  final int? provinsiIdAwal;

  /// Kalau diisi, filter kabupaten langsung diterapkan saat halaman dibuka
  /// - dipakai saat masuk dari tombol "Ada NIB" di BaselineOtaPage.
  final int? kabupatenIdAwal;

  /// ID baris tbl_oss_baseline_ota yang sedang diverifikasi, kalau halaman
  /// ini dibuka dari BaselineOtaPage. Diteruskan ke OssValidasiPage saat
  /// user memilih salah satu proyek atau memakai Cek Data OSS manual.
  final int? baselineOtaId;

  @override
  State<OssProyekPage> createState() => _OssProyekPageState();
}

class _OssProyekPageState extends State<OssProyekPage> {
  final OssProyekService _service = OssProyekService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  late OssProyekFilter _filter;
  OssProyekPageResult? _hasil; // hasil terakhir: opsi filter, provinsi, total
  final List<OssProyekItem> _items = <OssProyekItem>[];
  RiwayatPagination _pagination = RiwayatPagination.kosong;

  bool _loadingAwal = true;
  bool _loadingBerikutnya = false;
  bool _showBackToTop = false;
  String? _pesanError;

  /// Naik setiap kali daftar dimuat ulang; respons lama diabaikan supaya
  /// hasil pencarian yang terlambat tidak menimpa hasil yang lebih baru.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _filter = OssProyekFilter(
      provinsiId: widget.provinsiIdAwal,
      kabupatenId: widget.kabupatenIdAwal,
    );
    _scrollController.addListener(_onScroll);
    _muatUlang();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final bool dekatBawah =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    if (dekatBawah) _muatBerikutnya();

    // Back to top: tampil setelah digulir cukup jauh.
    final bool perluTampil = _scrollController.position.pixels > 400;
    if (perluTampil != _showBackToTop) {
      setState(() => _showBackToTop = perluTampil);
    }
  }

  void _scrollKeAtas() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Future<void> _muatUlang({bool tampilkanLoading = true}) async {
    final int id = ++_requestId;

    setState(() {
      _loadingBerikutnya = false;
      if (tampilkanLoading) {
        _loadingAwal = true;
        _pesanError = null;
      }
    });

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: 1,
        bidang: widget.bidang,
      );
      if (!mounted || id != _requestId) return;

      setState(() {
        _items
          ..clear()
          ..addAll(hasil.items);
        _pagination = hasil.pagination;
        _hasil = hasil;
        _loadingAwal = false;
        _pesanError = null;
      });
    } on ApiException catch (e) {
      _tanganiError(id, e.message, tampilkanLoading);
    } catch (_) {
      _tanganiError(
        id,
        'Terjadi kesalahan yang tidak terduga.',
        tampilkanLoading,
      );
    }
  }

  void _tanganiError(int id, String pesan, bool tampilkanLoading) {
    if (!mounted || id != _requestId) return;

    // Saat menyegarkan diam-diam dan daftar sudah terisi, cukup snackbar.
    if (!tampilkanLoading && _items.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }

    setState(() {
      _loadingAwal = false;
      _pesanError = pesan;
    });
  }

  Future<void> _muatBerikutnya() async {
    if (_loadingBerikutnya || _loadingAwal || !_pagination.hasNextPage) return;

    final int id = _requestId;
    setState(() => _loadingBerikutnya = true);

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: _pagination.currentPage + 1,
        bidang: widget.bidang,
      );
      if (!mounted || id != _requestId) return;

      setState(() {
        _items.addAll(hasil.items);
        _pagination = hasil.pagination;
        _loadingBerikutnya = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _loadingBerikutnya = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _loadingBerikutnya = false);
    }
  }

  void _terapkanPencarian(String value) {
    if (value.trim() == _filter.nibNku.trim()) return;
    setState(() => _filter = _filter.copyWith(nibNku: value));
    _muatUlang();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _terapkanPencarian(value),
    );
  }

  Future<void> _bukaFilter() async {
    final OssProyekPageResult? h = _hasil;

    final OssProyekFilter? hasil = await showOssProyekFilterSheet(
      context,
      filter: _filter,
      provinsiAktifId: h?.provinsiId,
      provinsiOptions: h?.provinsiOptions ?? const [],
      kabupatenOptions: h?.kabupatenOptions ?? const [],
    );

    if (hasil == null) return;

    setState(() => _filter = hasil);
    _muatUlang();
  }

  void _infoSegeraHadir() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Validasi untuk bidang ini segera hadir.')),
    );
  }

  /// Membuka halaman validasi dengan NIB, KBLI, dan NKU terisi dari baris ini.
  Future<void> _bukaVerifikasi(OssProyekItem item) async {
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssValidasiPage(
          initialNib: item.nib,
          initialKbli: item.kbli,
          initialNku: item.nku,
          namaUsaha: item.namaPerusahaan,
          baselineOtaId: widget.baselineOtaId,
          bidang: widget.bidang,
        ),
      ),
    );

    if (tersimpan == true && mounted) {
      await _segarkanItem(item);
    }
  }

  /// Verifikasi manual untuk usaha yang belum ada di daftar.
  Future<void> _bukaCekManual() async {
    final bool? tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OssValidasiPage(
          baselineOtaId: widget.baselineOtaId,
          bidang: widget.bidang,
        ),
      ),
    );

    if (tersimpan == true && mounted) {
      await _muatUlang(tampilkanLoading: false);
    }
  }

  void _bukaDetail(OssProyekItem item) {
    final int? id = item.pengawasanId;
    if (id == null) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RiwayatDetailPage(id: id)));
  }

  /// Memuat ulang HANYA halaman server yang memuat [item], lalu mengganti
  /// irisan itu di daftar. Posisi scroll dan halaman lain tidak berubah.
  Future<void> _segarkanItem(OssProyekItem item) async {
    final int index = _items.indexWhere((OssProyekItem e) => e.id == item.id);
    if (index < 0) return;

    final int perPage = _filter.perPage;
    final int halaman = index ~/ perPage + 1;
    final int awal = (halaman - 1) * perPage;

    try {
      final OssProyekPageResult hasil = await _service.fetch(
        filter: _filter,
        page: halaman,
        bidang: widget.bidang,
      );
      if (!mounted) return;

      final int akhir = math.min(awal + perPage, _items.length);

      if (hasil.items.length != akhir - awal) {
        await _muatUlang(tampilkanLoading: false);
        return;
      }

      setState(() => _items.replaceRange(awal, akhir, hasil.items));
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

  static String _ribuan(int angka) {
    final String s = angka.toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final OssProyekPageResult? h = _hasil;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              onPressed: _scrollKeAtas,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaBidang ?? 'Validasi OSS',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Verifikasi Proyek dan Usaha OSS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Filter',
            onPressed: _bukaFilter,
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filter.hasActiveFilter ? AppTheme.menuDashboard : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (String v) {
                _debounce?.cancel();
                _terapkanPencarian(v);
              },
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // dulu filter...
                LengthLimitingTextInputFormatter(21), // ...baru batasi panjang
              ],
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari NIB atau NKU lengkap',
                helperText:
                    'Contoh NIB: 8120115082852\nContoh NKU: 201912311521051085492',
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary(context),
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.surface(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (h != null && _pesanError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${h.provinsiNama} · ${_ribuan(_pagination.total)} usaha',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingAwal) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pesanError != null) {
      return ConnectionErrorState(
        title: 'Daftar usaha gagal dimuat',
        message: _pesanError!,
        isRetrying: _loadingAwal,
        onRetry: _muatUlang,
      );
    }

    final int jumlahBaris = _items.isEmpty ? 1 : _items.length;

    return RefreshIndicator(
      onRefresh: () => _muatUlang(tampilkanLoading: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: 1 + jumlahBaris + (_pagination.hasNextPage ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _KartuCekManual(onTap: _bukaCekManual);
          }

          if (_items.isEmpty) {
            return _EmptyState(hasFilter: _filter.hasActiveFilter);
          }

          final int i = index - 1;

          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final OssProyekItem item = _items[i];
          return OssProyekCard(
            key: ValueKey<int>(item.id),
            item: item,
            onVerifikasi: () => _bukaVerifikasi(item),
            onDetail: () => _bukaDetail(item),
          );
        },
      ),
    );
  }
}

/// Padanan baris "Cek Data OSS" di web.
class _KartuCekManual extends StatelessWidget {
  const _KartuCekManual({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color aksen = AppTheme.secondaryColor;

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: aksen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: aksen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cek Data OSS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gunakan apabila data usaha belum tersedia di daftar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Tidak ada usaha yang cocok dengan pencarian atau filter.'
                : 'Belum ada data usaha pada wilayah ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
