// lib/features/peta_industri/peta_industri_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_detail_page.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_grafik_page.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/api_exception.dart';
import 'models/peta_industri_model.dart';
import 'services/peta_industri_service.dart';

/// Peta Industri Pariwisata Indonesia (padanan menu "Peta Industri" di web).
/// Batch 1: peta + marker per provinsi + info total usaha.
/// Batch berikutnya: grafik risiko per KBLI dan detail rekap.
class PetaIndustriPage extends StatefulWidget {
  const PetaIndustriPage({super.key});

  @override
  State<PetaIndustriPage> createState() => _PetaIndustriPageState();
}

class _PetaIndustriPageState extends State<PetaIndustriPage> {
  final PetaIndustriService _service = PetaIndustriService();
  final MapController _mapController = MapController();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');

  // Sama dengan web: setView([-2.5, 118], 5).
  static const LatLng _pusatIndonesia = LatLng(-2.5, 118);

  PetaIndustriData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final PetaIndustriData data = await _service.ambilPeta();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = pesanErrorRamah(
          e,
          fallback: 'Data peta gagal dimuat. Silakan coba lagi.',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peta Industri',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loading ? null : _muat,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: 12, left: 12, right: 12, child: _buildHeaderCard()),
          if (_loading) const Positioned.fill(child: _LoadingOverlay()),
          if (_error != null && !_loading)
            Positioned.fill(
              child: _ErrorOverlay(message: _error!, onRetry: _muat),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final List<PetaProvinsi> daftar = _data?.provinsi ?? const <PetaProvinsi>[];

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _pusatIndonesia,
        initialZoom: 4.6,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.go.kemenpar.ipardasbor',
          errorTileCallback: (tile, error, stackTrace) {
            // Gagal memuat tile (offline/lambat) adalah kondisi normal.
          },
        ),
        MarkerLayer(markers: daftar.map(_buildMarker).toList()),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  Marker _buildMarker(PetaProvinsi p) {
    return Marker(
      point: LatLng(p.latitude, p.longitude),
      width: 42,
      height: 42,
      // Ujung bawah pin berada tepat di koordinat.
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _tampilkanInfo(p),
        child: const _IndustriPin(),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final PetaIndustriData? data = _data;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33042D58),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peta Industri Pariwisata Indonesia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data == null
                      ? 'Sebaran usaha pariwisata berdasarkan provinsi'
                      : '${_angka.format(data.totalNasional)} usaha di '
                            '${data.provinsi.length} provinsi',
                  style: const TextStyle(
                    color: AppTheme.textOnBrandMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bukaGrafik(PetaProvinsi p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetaIndustriGrafikPage(provinsi: p.nama),
      ),
    );
  }

  void _bukaDetail(PetaProvinsi p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetaIndustriDetailPage(provinsi: p.nama),
      ),
    );
  }

  void _tampilkanInfo(PetaProvinsi p) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.nama,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tintBackground(
                    context,
                    AppTheme.primaryColor,
                    AppTheme.menuDashboardBg,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Jumlah usaha',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _angka.format(p.total),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bukaGrafik(p);
                      },
                      icon: const Icon(Icons.pie_chart_rounded),
                      label: const Text('Grafik'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bukaDetail(p);
                      },
                      icon: const Icon(Icons.table_rows_rounded),
                      label: const Text('Detail'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndustriPin extends StatelessWidget {
  const _IndustriPin();

  @override
  Widget build(BuildContext context) {
    // Meniru .tourism-marker di web: kotak membulat diputar -45 derajat
    // (pin), ikon gedung di dalamnya diputar balik.
    return Transform.rotate(
      angle: -0.785398, // -45 derajat
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16A3E0), AppTheme.primaryColor],
          ),
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(19),
            topRight: Radius.circular(19),
            bottomRight: Radius.circular(19),
            bottomLeft: Radius.circular(5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59054582),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: 0.785398,
          child: const Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.75),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26142F4B),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Memuat data...',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 34,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
