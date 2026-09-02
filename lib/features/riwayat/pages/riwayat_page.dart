import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exception.dart';
import '../models/riwayat_filter.dart';
import '../models/riwayat_item.dart';
import '../models/riwayat_page_result.dart';
import '../services/riwayat_service.dart';
import '../widgets/riwayat_card.dart';
import '../widgets/riwayat_filter_sheet.dart';

/// Halaman daftar riwayat pengawasan (OSS / Non-OSS / OTA).
///
/// Fitur: pencarian, filter (sumber data, status, kabupaten, tanggal),
/// infinite scroll pagination, dan pull-to-refresh.
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final RiwayatService _service = RiwayatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  RiwayatFilter _filter = const RiwayatFilter();
  RiwayatFilterOptions _filterOptions = RiwayatFilterOptions.kosong;

  final List<RiwayatItem> _items = <RiwayatItem>[];
  RiwayatPagination _pagination = RiwayatPagination.kosong;

  bool _loadingAwal = true;
  bool _loadingHalamanBerikutnya = false;
  String? _pesanError;

  @override
  void initState() {
    super.initState();
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
    if (!_scrollController.hasClients) {
      return;
    }

    final bool sudahMendekatiBawah =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    if (sudahMendekatiBawah) {
      _muatHalamanBerikutnya();
    }
  }

  Future<void> _muatUlang() async {
    setState(() {
      _loadingAwal = true;
      _pesanError = null;
    });

    try {
      final RiwayatPageResult hasil = await _service.fetch(
        filter: _filter,
        page: 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(hasil.items);
        _pagination = hasil.pagination;
        _filterOptions = hasil.filterOptions;
        _loadingAwal = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingAwal = false;
        _pesanError = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingAwal = false;
        _pesanError = 'Terjadi kesalahan yang tidak terduga.';
      });
    }
  }

  Future<void> _muatHalamanBerikutnya() async {
    if (_loadingHalamanBerikutnya || _loadingAwal) {
      return;
    }

    if (!_pagination.hasNextPage) {
      return;
    }

    setState(() => _loadingHalamanBerikutnya = true);

    try {
      final RiwayatPageResult hasil = await _service.fetch(
        filter: _filter,
        page: _pagination.currentPage + 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(hasil.items);
        _pagination = hasil.pagination;
        _loadingHalamanBerikutnya = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingHalamanBerikutnya = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingHalamanBerikutnya = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _filter = _filter.copyWith(search: value));
      _muatUlang();
    });
  }

  Future<void> _bukaFilter() async {
    final RiwayatFilter? hasil = await showRiwayatFilterSheet(
      context,
      filter: _filter,
      options: _filterOptions,
    );

    if (hasil == null) {
      return;
    }

    setState(() => _filter = hasil);
    _muatUlang();
  }

  void _bukaDetail(RiwayatItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RiwayatDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Filter',
            onPressed: _bukaFilter,
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filter.hasActiveFilter
                  ? AppTheme.menuDashboard
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama usaha, NIB, atau kode...',
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
      return _ErrorState(message: _pesanError!, onRetry: _muatUlang);
    }

    if (_items.isEmpty) {
      return _EmptyState(hasFilter: _filter.hasActiveFilter);
    }

    return RefreshIndicator(
      onRefresh: _muatUlang,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _items.length + (_pagination.hasNextPage ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final RiwayatItem item = _items[index];
          return RiwayatCard(item: item, onTap: () => _bukaDetail(item));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppTheme.textSecondary(context),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'Tidak ada data yang cocok dengan filter.'
                  : 'Belum ada riwayat pengawasan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

/// Detail sederhana yang ditampilkan dari data yang sudah ada di list.
///
/// Catatan: ini BUKAN memanggil endpoint detail terpisah (foto, OTA, dll)
/// karena endpoint tersebut belum dirancang. Kalau nanti dibutuhkan detail
/// lengkap, tinggal ganti isi sheet ini menjadi pemanggilan service baru
/// (mis. RiwayatService.fetchDetail(id)).
class _RiwayatDetailSheet extends StatelessWidget {
  const _RiwayatDetailSheet({required this.item});

  final RiwayatItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.namaUsaha,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Jenis', value: item.jenis),
            _DetailRow(label: 'Identitas', value: item.identitas.ringkasan),
            _DetailRow(label: 'Lokasi', value: item.lokasi.gabungan),
            _DetailRow(label: 'Petugas', value: item.petugas),
            _DetailRow(label: 'Status', value: item.status),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}