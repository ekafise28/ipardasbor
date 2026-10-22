import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_detail_page.dart';
import 'package:ipardasbor/features/peta_industri/pages/peta_industri_grafik_page.dart';
import 'package:ipardasbor/shared/region/data/wilayah_local_database.dart';
import 'package:ipardasbor/shared/region/services/wilayah_akses_service.dart';
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

class _PetaIndustriPageState extends State<PetaIndustriPage>
    with SingleTickerProviderStateMixin {
  final PetaIndustriService _service = PetaIndustriService();
  final MapController _mapController = MapController();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');

  /// Nama provinsi (sudah dinormalisasi) yang menjadi wilayah kewenangan akun.
  Set<String> _wilayahSaya = <String>{};

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // Sama dengan web: setView([-2.5, 118], 5).
  static const LatLng _pusatIndonesia = LatLng(-2.5, 118);

  PetaIndustriData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _denyut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _muat();
    _muatWilayahSaya();
  }

  @override
  void dispose() {
    _denyut.dispose();
    _mapController.dispose();
    super.dispose();
  }

  late final AnimationController _denyut;
  PetaProvinsi? _sorot;

  /// Cincin berdenyut 3 kali di titik provinsi, lalu hilang sendiri.
  void _sorotProvinsi(PetaProvinsi p) {
    setState(() => _sorot = p);
    _denyut.repeat(count: 3).whenComplete(() {
      if (mounted) setState(() => _sorot = null);
    });
  }

  /// Provinsi akses akun diambil dari ID lokal, lalu dicocokkan lewat nama
  /// ke nama provinsi di data peta.
  Future<void> _muatWilayahSaya() async {
    try {
      final akses = await WilayahAksesService.instance.current();
      if (akses == null || akses.fullAccess || akses.provinsiIds.isEmpty) {
        return;
      }

      final List<String?> nama = await Future.wait(
        akses.provinsiIds.map(WilayahLocalDatabase.instance.provinceName),
      );
      if (!mounted) return;

      setState(() {
        _wilayahSaya = nama.whereType<String>().map(_norm).toSet();
      });
    } catch (e, st) {
      debugPrint('[PETA] _muatWilayahSaya gagal: $e');
      debugPrint('$st');
    }
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

  /// 32 (paling sedikit) sampai 48 (paling banyak). Akar kuadrat agar selisih
  /// antarprovinsi tidak terlalu ekstrem.
  double _ukuranPin(PetaProvinsi p, int maks) {
    if (maks <= 0) return 38;
    return 32 + 16 * math.sqrt(p.total / maks);
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
            tooltip: 'Daftar provinsi',
            onPressed: (_loading || _data == null) ? null : _bukaDaftar,
            icon: const Icon(Icons.format_list_numbered_rounded),
          ),
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
    final int maks = daftar.fold<int>(
      0,
      (int m, PetaProvinsi p) => p.total > m ? p.total : m,
    );

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
        if (_sorot != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_sorot!.latitude, _sorot!.longitude),
                width: 130,
                height: 130,
                child: _DenyutSorot(animasi: _denyut),
              ),
            ],
          ),
        MarkerLayer(
          markers:
              (<PetaProvinsi>[...daftar]..sort((a, b) {
                    // Wilayah akun paling atas; selebihnya yang besar digambar dulu.
                    final int sa = _wilayahSaya.contains(_norm(a.nama)) ? 1 : 0;
                    final int sb = _wilayahSaya.contains(_norm(b.nama)) ? 1 : 0;
                    if (sa != sb) return sa.compareTo(sb);
                    return b.total.compareTo(a.total);
                  }))
                  .map((PetaProvinsi p) => _buildMarker(p, maks))
                  .toList(),
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  Marker _buildMarker(PetaProvinsi p, int maks) {
    final double ukuran = _ukuranPin(p, maks);

    return Marker(
      point: LatLng(p.latitude, p.longitude),
      width: ukuran + 4,
      height: ukuran + 4,
      // Ujung bawah pin berada tepat di koordinat.
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _tampilkanInfo(p),
        child: _IndustriPin(
          ukuran: ukuran,
          milikSaya: _wilayahSaya.contains(_norm(p.nama)),
        ),
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

  Future<void> _bukaDaftar() async {
    final PetaIndustriData? data = _data;
    if (data == null || data.provinsi.isEmpty) return;

    final PetaProvinsi? dipilih = await showModalBottomSheet<PetaProvinsi>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _DaftarProvinsiSheet(daftar: data.provinsi, angka: _angka),
    );

    if (dipilih == null || !mounted) return;

    _mapController.move(LatLng(dipilih.latitude, dipilih.longitude), 7);
    _sorotProvinsi(dipilih);

    // Beri waktu denyut terlihat dulu sebelum sheet info menutupi peta.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _tampilkanInfo(dipilih);
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

class _DenyutSorot extends StatelessWidget {
  const _DenyutSorot({required this.animasi});

  final Animation<double> animasi;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animasi,
        builder: (context, _) {
          final double t = animasi.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              _cincin(t),
              // Cincin kedua menyusul agar denyutnya terasa berlapis.
              if (t >= 0.35) _cincin((t - 0.35) / 0.65),
            ],
          );
        },
      ),
    );
  }

  Widget _cincin(double t) {
    final double ukuran = 24 + 100 * Curves.easeOut.transform(t);
    final double alpha = 1 - t;

    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.18 * alpha),
        border: Border.all(
          color: const Color(0xFF16A3E0).withValues(alpha: alpha),
          width: 3,
        ),
      ),
    );
  }
}

class _IndustriPin extends StatelessWidget {
  const _IndustriPin({this.ukuran = 38, this.milikSaya = false});

  final double ukuran;
  final bool milikSaya;

  @override
  Widget build(BuildContext context) {
    final List<Color> warna = milikSaya
        ? const [Color(0xFFFFB74D), Color(0xFFF57C00)]
        : const [Color(0xFF16A3E0), AppTheme.primaryColor];

    return Transform.rotate(
      angle: -0.785398,
      child: Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: warna,
          ),
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ukuran / 2),
            topRight: Radius.circular(ukuran / 2),
            bottomRight: Radius.circular(ukuran / 2),
            bottomLeft: const Radius.circular(5),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (milikSaya
                          ? const Color(0xFFF57C00)
                          : const Color(0xFF054582))
                      .withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: 0.785398,
          child: Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: ukuran * 0.47,
          ),
        ),
      ),
    );
  }
}

class _DaftarProvinsiSheet extends StatefulWidget {
  const _DaftarProvinsiSheet({required this.daftar, required this.angka});

  final List<PetaProvinsi> daftar;
  final NumberFormat angka;

  @override
  State<_DaftarProvinsiSheet> createState() => _DaftarProvinsiSheetState();
}

class _DaftarProvinsiSheetState extends State<_DaftarProvinsiSheet> {
  final TextEditingController _cari = TextEditingController();
  late final List<PetaProvinsi> _urut;
  late final int _maks;
  String _kata = '';

  @override
  void initState() {
    super.initState();
    // Peringkat tetap mengikuti jumlah, walau daftar sedang disaring.
    _urut = List<PetaProvinsi>.of(widget.daftar)
      ..sort((a, b) => b.total.compareTo(a.total));
    _maks = _urut.isEmpty || _urut.first.total <= 0 ? 1 : _urut.first.total;
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<int, PetaProvinsi>> tampil =
        <MapEntry<int, PetaProvinsi>>[
          for (int i = 0; i < _urut.length; i++)
            if (_kata.isEmpty || _urut[i].nama.toLowerCase().contains(_kata))
              MapEntry<int, PetaProvinsi>(i + 1, _urut[i]),
        ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) => Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.border(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _cari,
                onChanged: (v) =>
                    setState(() => _kata = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cari provinsi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _kata.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _cari.clear();
                            setState(() => _kata = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: tampil.isEmpty
                  ? Center(
                      child: Text(
                        'Provinsi tidak ditemukan.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: tampil.length,
                      itemBuilder: (context, i) {
                        final int peringkat = tampil[i].key;
                        final PetaProvinsi p = tampil[i].value;

                        return ListTile(
                          onTap: () => Navigator.of(context).pop(p),
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: AppTheme.tintBackground(
                              context,
                              AppTheme.primaryColor,
                              AppTheme.menuDashboardBg,
                            ),
                            child: Text(
                              '$peringkat',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            p.nama,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: p.total / _maks,
                                minHeight: 5,
                                backgroundColor: AppTheme.border(context),
                              ),
                            ),
                          ),
                          trailing: Text(
                            widget.angka.format(p.total),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
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
