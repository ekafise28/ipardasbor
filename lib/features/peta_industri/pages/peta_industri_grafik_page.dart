// lib/features/peta_industri/pages/peta_industri_grafik_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../../../core/api/api_exception.dart';
import '../models/peta_grafik_model.dart';
import '../services/peta_industri_service.dart';
import '../widgets/risiko_warna.dart';

/// Distribusi risiko proyek per KBLI untuk satu provinsi
/// (padanan tombol "Grafik" di web).
class PetaIndustriGrafikPage extends StatefulWidget {
  const PetaIndustriGrafikPage({super.key, required this.provinsi});

  final String provinsi;

  @override
  State<PetaIndustriGrafikPage> createState() => _PetaIndustriGrafikPageState();
}

class _PetaIndustriGrafikPageState extends State<PetaIndustriGrafikPage> {
  final PetaIndustriService _service = PetaIndustriService();
  final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');

  PetaGrafikData? _data;
  String? _error;
  bool _loading = true;

  /// null = semua kategori.
  String? _kategoriTerpilih;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final PetaGrafikData data = await _service.ambilGrafik(widget.provinsi);
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
          fallback: 'Grafik gagal dimuat. Silakan coba lagi.',
        );
        _loading = false;
      });
    }
  }

  /// Daftar datar (header kategori + kartu KBLI) agar ListView.builder
  /// hanya membangun chart yang terlihat.
  List<Object> _susunEntri(PetaGrafikData data) {
    final List<Object> hasil = <Object>[];
    for (final KategoriGrafik k in data.kategori) {
      if (_kategoriTerpilih != null && k.nama != _kategoriTerpilih) continue;
      hasil.add(k);
      hasil.addAll(k.kbli);
    }
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Risiko Proyek',
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _PesanState(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.danger,
        message: _error!,
        onRetry: _muat,
      );
    }

    final PetaGrafikData data = _data!;

    if (data.kategori.isEmpty) {
      return const _PesanState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'Belum ada data grafik untuk provinsi ini.',
      );
    }

    final List<Object> entri = _susunEntri(data);

    return Column(
      children: [
        _buildRingkasan(data),
        _buildFilterKategori(data),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: entri.length,
            itemBuilder: (context, i) {
              final Object item = entri[i];
              if (item is KategoriGrafik) {
                return _KategoriHeader(kategori: item, angka: _angka);
              }
              return _KbliCard(kbli: item as KbliGrafik, angka: _angka);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasan(PetaGrafikData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.tintBackground(
            context,
            AppTheme.primaryColor,
            AppTheme.menuDashboardBg,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.business_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Proyek pada kategori pariwisata',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              _angka.format(data.total),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterKategori(PetaGrafikData data) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua'),
              selected: _kategoriTerpilih == null,
              onSelected: (_) => setState(() => _kategoriTerpilih = null),
            ),
          ),
          for (final KategoriGrafik k in data.kategori)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(k.nama),
                selected: _kategoriTerpilih == k.nama,
                onSelected: (_) => setState(() => _kategoriTerpilih = k.nama),
              ),
            ),
        ],
      ),
    );
  }
}

class _KategoriHeader extends StatelessWidget {
  const _KategoriHeader({required this.kategori, required this.angka});

  final KategoriGrafik kategori;
  final NumberFormat angka;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.border(context), width: 2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                kategori.nama,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              angka.format(kategori.total),
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KbliCard extends StatelessWidget {
  const _KbliCard({required this.kbli, required this.angka});

  final KbliGrafik kbli;
  final NumberFormat angka;

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = kbli.risiko
        .where((r) => r.jumlah > 0)
        .map(
          (r) => PieChartSectionData(
            value: r.jumlah.toDouble(),
            color: warnaRisiko(r.label),
            radius: 20,
            showTitle: false,
          ),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kbli.kbli} - ${kbli.nama}',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                    Text(
                      angka.format(kbli.total),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final RisikoJumlah r in kbli.risiko)
                      _LegendaRow(risiko: r, total: kbli.total, angka: angka),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendaRow extends StatelessWidget {
  const _LegendaRow({
    required this.risiko,
    required this.total,
    required this.angka,
  });

  final RisikoJumlah risiko;
  final int total;
  final NumberFormat angka;

  @override
  Widget build(BuildContext context) {
    final double persen = total == 0 ? 0 : risiko.jumlah * 100 / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: warnaRisiko(risiko.label),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              risiko.label,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            angka.format(risiko.jumlah),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${persen.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11,
              ),
            ),
          ),
        ],
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