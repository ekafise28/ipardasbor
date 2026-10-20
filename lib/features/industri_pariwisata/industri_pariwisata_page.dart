// Halaman Dashboard Industri Pariwisata (padanan index.blade.php di web).
// Tahap ini: header status, filter, dan 3 kartu KPI.
// Tahap berikutnya: 4 grafik + tabel data + 4 tabel peringkat.

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart'; // untuk pesanErrorRamah()
import 'industri_format.dart';
import 'models/industri_dashboard_data.dart';
import 'models/industri_filter.dart';
import 'models/industri_option.dart';
import 'services/industri_pariwisata_service.dart';
import 'widgets/industri_filter_panel.dart';
import 'widgets/industri_kpi_cards.dart';

class IndustriPariwisataPage extends StatefulWidget {
  const IndustriPariwisataPage({super.key});

  @override
  State<IndustriPariwisataPage> createState() => _IndustriPariwisataPageState();
}

class _IndustriPariwisataPageState extends State<IndustriPariwisataPage> {
  // ApiClient dibuat sekali untuk halaman ini dan ditutup di dispose().
  // Polanya sama seperti HomePage.
  late final ApiClient _api;
  late final IndustriPariwisataService _service;

  // ---- State (data yang berubah-ubah dan memengaruhi tampilan) ----
  IndustriFilter _filter = const IndustriFilter(); // pilihan filter saat ini
  IndustriFilterOptions _options = IndustriFilterOptions.fallback;
  bool _optionsLoaded = false; // false -> dicoba lagi saat tarik-refresh
  List<IndustriOption> _kotaOptions = const [];
  IndustriDashboardData? _data; // null = belum ada data
  bool _loading = false;

  // Penomoran permintaan. Padanan "activeRequest" di JavaScript web:
  // jika pengguna menekan Terapkan dua kali, jawaban permintaan LAMA
  // diabaikan supaya tidak menimpa hasil yang baru.
  int _requestId = 0;
  int _kotaRequestId = 0;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _service = IndustriPariwisataService(_api);

    // Seperti di web: opsi filter dan data dashboard dimuat bersamaan.
    _loadFilterOptions();
    _loadDashboard();
  }

  @override
  void dispose() {
    _api.close(); // menutup koneksi HTTP agar tidak bocor
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Pemuatan data
  // ---------------------------------------------------------------

  Future<void> _loadFilterOptions() async {
    if (_optionsLoaded) return;
    try {
      final IndustriFilterOptions result = await _service.fetchFilterOptions();
      if (!mounted) return;
      setState(() {
        _options = result;
        _optionsLoaded = true;
      });
    } catch (e) {
      debugPrint('Industri - opsi filter gagal: $e');
      // Cadangan: daftar tahun tetap muncul (sama seperti web).
      // _optionsLoaded tetap false agar dicoba lagi saat tarik-refresh.
      if (!mounted) return;
      setState(() => _options = IndustriFilterOptions.fallback);
    }
  }

  Future<void> _loadDashboard() async {
    final int requestId = ++_requestId;
    setState(() => _loading = true);

    try {
      final IndustriDashboardData result = await _service.fetchDashboard(
        _filter,
      );
      if (!mounted || requestId != _requestId) return; // jawaban usang
      setState(() => _data = result);
    } catch (e) {
      debugPrint('Industri - dashboard gagal: $e');
      if (!mounted || requestId != _requestId) return;
      _showError(
        pesanErrorRamah(
          e,
          fallback: 'Data utama dashboard belum berhasil dimuat.',
        ),
      );
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  /// Tarik layar ke bawah: muat ulang opsi (jika dulu gagal) dan data.
  Future<void> _refresh() async {
    await Future.wait([_loadFilterOptions(), _loadDashboard()]);
  }

  // ---------------------------------------------------------------
  // Aksi filter
  // ---------------------------------------------------------------

  /// Saat provinsi berubah: kosongkan kota, lalu ambil daftar kota baru.
  Future<void> _onProvinsiChanged(List<String> ids) async {
    final int requestId = ++_kotaRequestId;

    setState(() {
      _filter = _filter.copyWith(provinsi: ids, kota: const []);
      _kotaOptions = const [];
    });
    if (ids.isEmpty) return;

    try {
      // Satu permintaan per provinsi, dijalankan bersamaan.
      final List<List<IndustriOption>> results = await Future.wait(
        ids.map(_service.fetchKota),
      );
      if (!mounted || requestId != _kotaRequestId) return;

      // Gabungkan; kota yang sama (id sama) hanya dimasukkan sekali.
      final Map<String, IndustriOption> unik = {
        for (final List<IndustriOption> list in results)
          for (final IndustriOption option in list) option.value: option,
      };
      setState(() => _kotaOptions = unik.values.toList());
    } catch (e) {
      debugPrint('Industri - kota gagal: $e');
      if (!mounted || requestId != _kotaRequestId) return;
      _showError(
        pesanErrorRamah(e, fallback: 'Daftar kabupaten/kota gagal dimuat.'),
      );
    }
  }

  void _reset() {
    _kotaRequestId++; // batalkan pemuatan kota yang mungkin masih berjalan
    setState(() {
      _filter = const IndustriFilter();
      _kotaOptions = const [];
    });
    _loadDashboard();
  }

  void _showError(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
  }

  // ---------------------------------------------------------------
  // Tampilan
  // ---------------------------------------------------------------

  /// Teks status data di header (padanan #lastUpdated di web).
  String get _statusText {
    final IndustriDashboardData? data = _data;
    if (data == null) {
      return _loading
          ? 'Mohon ditunggu, data sedang dimuat...'
          : 'Data belum berhasil dimuat';
    }
    final DateTime? waktu = data.lastUpdated;
    return waktu == null
        ? 'Data ringkasan belum pernah dihitung'
        : 'Data dihitung ${formatWaktu(waktu)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Industri Pariwisata')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Garis loading tipis di bawah AppBar
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: _refresh,
                child: ListView(
                  // AlwaysScrollable: tarik-refresh tetap bisa walau isi pendek
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _HeroCard(status: _statusText),
                    const SizedBox(height: 14),
                    IndustriFilterPanel(
                      filter: _filter,
                      options: _options,
                      kotaOptions: _kotaOptions,
                      loading: _loading,
                      onTahunChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(tahun: v)),
                      onProvinsiChanged: _onProvinsiChanged,
                      onKotaChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(kota: v)),
                      onKbliChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(kbli: v)),
                      onApply: _loadDashboard,
                      onReset: _reset,
                    ),
                    const SizedBox(height: 14),
                    IndustriKpiCards(kpi: _data?.kpi),
                    // TODO tahap berikutnya: grafik dan tabel diletakkan di sini.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu judul di atas (padanan "hero" di web).
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Usaha Pariwisata Nasional',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ringkasan perkembangan, skala, tingkat risiko, dan persebaran '
            'usaha pariwisata Indonesia.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF68E7A7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
