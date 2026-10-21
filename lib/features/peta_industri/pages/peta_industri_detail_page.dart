// lib/features/peta_industri/pages/peta_industri_detail_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_perusahaan_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../models/peta_detail_model.dart';
import '../services/peta_industri_service.dart';
import '../widgets/risiko_warna.dart';

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

class _PetaIndustriDetailPageState extends State<PetaIndustriDetailPage> {
  static const int _perPage = 25;

  static const List<_OpsiUrut> _opsiUrut = <_OpsiUrut>[
    _OpsiUrut('Jumlah terbanyak', 'jumlah', 'desc'),
    _OpsiUrut('Jumlah tersedikit', 'jumlah', 'asc'),
    _OpsiUrut('Jenis usaha (A-Z)', 'jenis_usaha', 'asc'),
    _OpsiUrut('Nama KBLI (A-Z)', 'nama_kbli', 'asc'),
    _OpsiUrut('Kode KBLI', 'kbli', 'asc'),
  ];

  final PetaIndustriService _service = PetaIndustriService();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _debounce;

  final List<PetaRekapItem> _items = <PetaRekapItem>[];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadMoreError = false;
  bool _mengekspor = false;
  String? _error;
  int _urutIndex = 0;
  String _search = '';

  /// Penanda permintaan. Respons dari permintaan lama (mis. setelah pengguna
  /// mengganti kata kunci) diabaikan.
  int _generasi = 0;

  Future<void> _ekspor() async {
    if (_mengekspor) return;
    setState(() => _mengekspor = true);

    try {
      final List<PetaRekapItem> data = await _service.ambilSemuaRekap(
        widget.provinsi,
      );

      if (!mounted) return;
      if (data.isEmpty) {
        _pesan('Tidak ada data untuk diekspor.');
        return;
      }

      // BOM + pemisah ";" sama seperti ekspor di web, agar terbuka benar di Excel.
      final StringBuffer csv = StringBuffer('\uFEFF')
        ..write(
          _barisCsv(<String>[
            'Jenis Usaha',
            'Nama KBLI',
            'KBLI',
            'Risiko',
            'Jumlah Proyek',
          ]),
        );
      for (final PetaRekapItem e in data) {
        csv.write(
          _barisCsv(<String>[
            e.jenisUsaha,
            e.namaKbli,
            e.kbli,
            e.risiko,
            e.jumlah.toString(),
          ]),
        );
      }

      final String slug = widget.provinsi
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final String stempel = DateFormat(
        'yyyyMMdd-HHmmss',
      ).format(DateTime.now());
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/rekap-$slug-$stempel.csv');
      await file.writeAsBytes(utf8.encode(csv.toString()), flush: true);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
          subject: 'Rekap Industri Pariwisata ${widget.provinsi}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _pesan(pesanErrorRamah(e, fallback: 'Ekspor gagal. Silakan coba lagi.'));
    } finally {
      if (mounted) setState(() => _mengekspor = false);
    }
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  /// Satu baris CSV. Nilai "-" (kosong di tampilan) diekspor kosong, dan nilai
  /// berawalan = + - @ diberi tanda ' agar tidak dibaca sebagai rumus Excel.
  String _barisCsv(List<String> kolom) {
    final String baris = kolom
        .map((String v) {
          String s = v == '-' ? '' : v;
          if (RegExp(r'^[=+\-@]').hasMatch(s)) s = "'$s";
          if (s.contains(';') ||
              s.contains('"') ||
              s.contains('\n') ||
              s.contains('\r')) {
            s = '"${s.replaceAll('"', '""')}"';
          }
          return s;
        })
        .join(';');
    return '$baris\r\n';
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _muatAwal();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadMoreError) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _muatBerikut();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final String kata = value.trim();
      if (kata == _search) return;
      _search = kata;
      _muatAwal();
    });
  }

  Future<void> _muatAwal() async {
    _generasi++;
    setState(() {
      _items.clear();
      _page = 0;
      _total = 0;
      _hasMore = true;
      _loading = false;
      _loadMoreError = false;
      _error = null;
    });
    await _muatBerikut();
  }

  Future<void> _muatBerikut() async {
    if (_loading || !_hasMore) return;

    final int generasi = _generasi;
    final _OpsiUrut urut = _opsiUrut[_urutIndex];

    setState(() {
      _loading = true;
      _loadMoreError = false;
    });

    try {
      final PetaRekapHalaman hasil = await _service.ambilDetail(
        widget.provinsi,
        page: _page + 1,
        perPage: _perPage,
        search: _search,
        sort: urut.sort,
        dir: urut.dir,
      );

      if (!mounted || generasi != _generasi) return;
      setState(() {
        _items.addAll(hasil.items);
        _page = hasil.page;
        _total = hasil.total;
        _hasMore = hasil.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generasi != _generasi) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _error = pesanErrorRamah(
            e,
            fallback: 'Detail gagal dimuat. Silakan coba lagi.',
          );
        } else {
          _loadMoreError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _buildInfoBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari jenis usaha, KBLI, atau risiko...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    _debounce?.cancel();
                    _search = '';
                    _muatAwal();
                  },
                ),
        ),
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
              _error == null && !(_loading && _items.isEmpty)
                  ? '${_angka.format(_total)} baris'
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
              _muatAwal();
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
    if (_items.isEmpty) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return _PesanState(
          icon: Icons.cloud_off_rounded,
          iconColor: AppTheme.danger,
          message: _error!,
          onRetry: _muatAwal,
        );
      }
      return const _PesanState(
        icon: Icons.search_off_rounded,
        message: 'Data tidak ditemukan.',
      );
    }

    final bool adaFooter = _hasMore || _loadMoreError;

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length + (adaFooter ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < _items.length) {
          return _RekapCard(
            item: _items[i],
            angka: _angka,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PetaIndustriPerusahaanPage(
                  provinsi: widget.provinsi,
                  item: _items[i],
                ),
              ),
            ),
          );
        }

        if (_loadMoreError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: _muatBerikut,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Gagal memuat. Coba lagi'),
              ),
            ),
          );
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
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
    final Color warna = warnaRisiko(item.risiko);

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
                          _Chip(
                            label: 'KBLI ${item.kbli}',
                            color: AppTheme.textSecondary(context),
                          ),
                          _Chip(label: item.risiko, color: warna),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PesanState extends StatelessWidget {
  const _PesanState({
    required this.icon,
    required this.message,
    this.iconColor,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Color? iconColor;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor ?? AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
