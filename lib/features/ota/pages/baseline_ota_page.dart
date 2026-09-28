import 'package:flutter/material.dart';
import 'package:ipardasbor/features/oss/oss_proyek_page.dart';

import '../../../app/app_theme.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

import '../../non_oss/services/region_service.dart';

import '../models/baseline_ota_filter.dart';
import '../models/baseline_ota_item.dart';
import '../models/baseline_ota_page_result.dart';

import '../../non_oss/non_oss_form_page.dart';
import '../widgets/baseline_ota_filter_sheet.dart';

import '../services/baseline_ota_service.dart';

import '../widgets/baseline_ota_card.dart';

class BaselineOtaPage extends StatefulWidget {
  const BaselineOtaPage({super.key});

  @override
  State<BaselineOtaPage> createState() => _BaselineOtaPageState();
}

class _BaselineOtaPageState extends State<BaselineOtaPage> {
  static const _navy = Color(0xFF0B3F78);

  late final BaselineOtaService _service;
  final RegionService _regions = RegionService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  BaselineOtaFilter _filter = BaselineOtaFilter();
  BaselineOtaFilterOptions? _filterOptions;
  String _provinsiNama = '';

  final List<BaselineOtaItem> _items = [];
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loadingFirst = true;
  bool _loadingMore = false;
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
    if (_loadingMore || _page >= _lastPage) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _muatHalamanBerikutnya();
    }
  }

  /// Naik setiap kali daftar dimuat ulang; respons lama diabaikan supaya
  /// hasil yang terlambat tidak menimpa hasil yang lebih baru.
  int _requestId = 0;

  /// [tampilkanLoading] false = refresh diam-diam (tarik layar): daftar lama
  /// tetap terlihat sampai data baru datang, tidak diganti spinner.
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
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      final String pesan = e is ApiException ? e.message : e.toString();

      // Refresh diam-diam gagal tapi daftar sudah terisi: cukup snackbar,
      // jangan buang daftar yang sedang tampil.
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
    setState(() => _loadingMore = true);
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
      // Gagal muat halaman berikut: diam, user bisa scroll ulang untuk
      // mencoba lagi (pemicunya ada di _onScroll).
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
      await _muatHalamanPertama();
    }
  }

  void _cari(String keyword) {
    _filter.namaListing = keyword.trim().isEmpty ? null : keyword.trim();
    _muatHalamanPertama();
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
    if (tersimpan == true && mounted) {
      await _muatHalamanPertama(tampilkanLoading: false);
    }
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
    if (tersimpan == true && mounted) {
      await _muatHalamanPertama(tampilkanLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengawasan OTA',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Verifikasi hasil scraping baseline OTA',
              style: TextStyle(fontSize: 11.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filter.isActive ? Colors.amberAccent : Colors.white,
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
              decoration: InputDecoration(
                hintText: 'Cari listing, alamat, platform...',
                prefixIcon: const Icon(Icons.search, size: 20),
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
      return const Center(child: CircularProgressIndicator());
    }

    // Kondisi error dan kosong dibungkus ListView supaya layar tetap bisa
    // ditarik untuk memuat ulang.
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
      return RefreshIndicator(
        onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            const Text(
              'Belum ada data hasil scraping OTA',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak ditemukan data yang sesuai dengan filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _muatHalamanPertama(tampilkanLoading: false),
      child: ListView.builder(
        controller: _scroll,
        // Wajib: tanpa ini daftar yang lebih pendek dari layar tidak bisa ditarik.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length + (_page < _lastPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final BaselineOtaItem item = _items[index];
          return BaselineOtaCard(
            item: item,
            onAdaNib: () => _bukaOssProyek(item),
            onTidakAda: () => _bukaNonOss(item, 'TIDAK'),
            onTidakTahu: () => _bukaNonOss(item, 'TIDAK TAHU'),
          );
        },
      ),
    );
  }
}
