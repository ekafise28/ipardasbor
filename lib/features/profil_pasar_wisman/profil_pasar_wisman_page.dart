// Halaman Dashboard Profil Pasar Wisatawan Mancanegara
// (padanan wisman_rekap.blade.php di web).
// Isi: header status, filter, 3 kartu KPI, 5 grafik + tabel data.

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart'; // untuk pesanErrorRamah()
import 'models/rekap_dashboard_data.dart';
import 'models/rekap_filter.dart';
import 'services/rekap_service.dart';
import 'widgets/rekap_charts.dart';
import 'widgets/rekap_filter_panel.dart';
import 'widgets/rekap_kpi_cards.dart';
import '../../../shared/widgets/list_parts.dart';

class ProfilPasarWismanPage extends StatefulWidget {
  const ProfilPasarWismanPage({super.key});

  @override
  State<ProfilPasarWismanPage> createState() => _ProfilPasarWismanPageState();
}

class _ProfilPasarWismanPageState extends State<ProfilPasarWismanPage> {
  late final ApiClient _api;
  late final RekapService _service;

  RekapFilter _filter = const RekapFilter();
  RekapFilterOptions _options = const RekapFilterOptions();
  bool _optionsLoaded = false; // false -> dicoba lagi saat tarik-refresh
  RekapDashboardData? _data; // null = belum ada data
  bool _loading = false;

  // Penomoran permintaan: jawaban permintaan LAMA diabaikan.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _service = RekapService(_api);
    _mulai();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  /// Seperti di web: opsi filter dimuat dulu (tahun terbaru otomatis
  /// terpilih), baru data dashboard.
  Future<void> _mulai() async {
    await _loadFilters();
    if (!mounted) return;
    await _loadDashboard();
  }

  Future<void> _loadFilters() async {
    if (_optionsLoaded) return;
    try {
      final RekapFilterOptions result = await _service.fetchFilters();
      if (!mounted) return;
      setState(() {
        _options = result;
        _optionsLoaded = true;
        if (_filter.tahun.isEmpty && result.tahun.isNotEmpty) {
          _filter = _filter.copyWith(tahun: <String>[result.tahun.first]);
        }
      });
    } catch (e) {
      debugPrint('Rekap - opsi filter gagal: $e');
      if (!mounted) return;
      _showError(
        pesanErrorRamah(e, fallback: 'Opsi filter belum berhasil dimuat.'),
      );
    }
  }

  Future<void> _loadDashboard() async {
    final int requestId = ++_requestId;
    setState(() => _loading = true);

    try {
      final RekapDashboardData result = await _service.fetchDashboard(_filter);
      if (!mounted || requestId != _requestId) return; // jawaban usang
      setState(() => _data = result);
    } catch (e) {
      debugPrint('Rekap - dashboard gagal: $e');
      if (!mounted || requestId != _requestId) return;
      _showError(
        pesanErrorRamah(e, fallback: 'Dashboard gagal dimuat. Coba kembali.'),
      );
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _loadFilters();
    await _loadDashboard();
  }

  void _reset() {
    setState(() {
      _filter = RekapFilter(
        tahun: _options.tahun.isEmpty
            ? const <String>[]
            : <String>[_options.tahun.first],
      );
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

  String get _statusText {
    final RekapDashboardData? data = _data;
    if (data == null) {
      return _loading
          ? 'Mohon ditunggu, data sedang dimuat...'
          : 'Data belum berhasil dimuat';
    }
    return 'Sumber: Wisman Rekap · Diperbarui ${data.updatedAt}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Profil Pasar Wisatawan Mancanegara',
          subtitle: 'Dashboard Wisman Rekap',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: <Widget>[
                    _HeroCard(status: _statusText),
                    const SizedBox(height: 14),
                    RekapFilterPanel(
                      filter: _filter,
                      options: _options,
                      loading: _loading,
                      onChanged: (RekapFilter v) => setState(() => _filter = v),
                      onApply: _loadDashboard,
                      onReset: _reset,
                    ),
                    const SizedBox(height: 14),
                    if (_data == null && _loading)
                      const RekapKpiSkeleton()
                    else
                      RekapKpiCards(summary: _data?.summary),
                    const SizedBox(height: 22),
                    RekapChartSection(data: _data, loading: _loading),
                    const SizedBox(height: 24),
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

/// Kartu judul di atas (padanan "wr-hero" di web).
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
        children: <Widget>[
          const Text(
            'Profil Pasar Wisatawan Mancanegara Berdasar Negara',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analisis historis kewarganegaraan dan pintu masuk dari sumber '
            'Wisman Rekap.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
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
