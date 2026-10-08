import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ipardasbor/core/constants/bidang_usaha_constants.dart';
import 'package:ipardasbor/features/dashboard/models/dashboard_insight.dart';
import 'package:ipardasbor/shared/utils/count_up_text.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';
import 'package:ipardasbor/shared/utils/skeleton.dart';
import 'package:ipardasbor/shared/utils/staggered_entrance.dart';
import 'package:ipardasbor/shared/widgets/connection_error_state.dart';
import '../../core/api/api_exception.dart';
import '../../app/app_theme.dart';

import 'models/dashboard_data.dart';
import 'models/chart_series.dart';
import 'models/dashboard_map_model.dart';

import 'widget/dashboard_chart_table_card.dart';
import 'widget/dashboard_map_section.dart';
import 'widget/dashboard_filter_panel.dart';
import 'widget/dashboard_ranked_bar_chart.dart';

import 'services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final DashboardService _dashboardService = DashboardService();

  // Animasi masuk bertahap, dijalankan sekali saat data pertama tiba.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  String get _labelBidang =>
      BidangUsahaOpsi.namaDari(_filterValues.bidangUsaha) ?? 'Usaha Pariwisata';

  DashboardData? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedProvince = 'jawa-timur';

  DashboardFilterValues _filterValues = DashboardFilterValues.empty;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final DashboardData result = await _dashboardService
          .getDashboard(
            bidangUsaha: _filterValues.bidangUsaha,
            province: _selectedProvince,
            includeMap: true,
            startDate: _filterValues.startDateApiFormat,
            endDate: _filterValues.endDateApiFormat,
            districtId: _filterValues.districtId,
            dataSource: _filterValues.dataSource,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Server tidak memberikan respons dalam waktu 10 detik.',
              );
            },
          );

      if (!mounted) return;

      final bool isFirstData = _dashboard == null;

      setState(() {
        _dashboard = result;
        _selectedProvince = result.province.slug;
        _isLoading = false;
        _errorMessage = null;
      });

      if (isFirstData) _entrance.forward(from: 0);
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda, '
            'kemudian tekan tombol Coba Lagi.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message.isNotEmpty
            ? error.message
            : 'Server tidak dapat memproses permintaan dashboard.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Koneksi ke server gagal. Pastikan internet aktif dan server '
            'dapat diakses.';
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboard(showLoading: false);
  }

  Future<void> _changeProvince(String province) async {
    if (_selectedProvince == province) return;

    setState(() {
      _selectedProvince = province;
      _isLoading = true;
      _errorMessage = null;
    });

    await _loadDashboard(showLoading: false);
  }

  void _applyFilters(DashboardFilterValues values) {
    setState(() => _filterValues = values);
    _loadDashboard(); // showLoading: true (default)
  }

  void _resetFilters() {
    setState(() => _filterValues = DashboardFilterValues.empty);
    _loadDashboard(); // showLoading: true (default)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'Ringkasan Pengawasan Pariwisata',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading
                ? null
                : () async {
                    await _loadDashboard();
                  },
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            // Penanda tipis saat data sedang diperbarui (filter/muat ulang)
            // sementara data lama masih tampil.
            if (_isLoading && _dashboard != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading && _dashboard == null) {
      return const _DashboardSkeleton();
    }

    if (_errorMessage != null && _dashboard == null) {
      return ConnectionErrorState(
        title: 'Dashboard gagal dimuat',
        message: _errorMessage!,
        isRetrying: _isLoading,
        onRetry: () => _loadDashboard(showLoading: true),
      );
    }

    final DashboardData? dashboard = _dashboard;

    if (dashboard == null) {
      return ConnectionErrorState(
        title: 'Dashboard gagal dimuat',
        message: 'Data dashboard tidak tersedia.',
        isRetrying: _isLoading,
        onRetry: () => _loadDashboard(showLoading: true),
      );
    }

    final points = parseMapPoints(dashboard.map.points);
    final config = MapConfigData.fromJson(dashboard.map.configuration);
    final List<DashboardInsight> insights = buildDashboardInsights(dashboard);

    // Urutan animasi masuk: tiap blok mendapat indeks berikutnya.
    int order = 0;
    Widget staggered(Widget child) {
      return StaggeredEntrance(
        animation: _entrance,
        index: order++,
        step: 0.06,
        child: child,
      );
    }

    final ChartSeriesData districtChart = ChartSeriesData.fromDynamic(
      dashboard.charts.district,
      seriesConfig: const [
        MapEntry('total', AppTheme.categoryTotal),
        MapEntry('oss', AppTheme.categoryOss),
        MapEntry('non_oss', AppTheme.categoryNonOss),
      ],
      seriesLabelOverride: const {
        'total': 'Total Pengawasan',
        'oss': 'OSS',
        'non_oss': 'Non OSS',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        staggered(_buildKpiHeader(dashboard)),
        const SizedBox(height: 16),

        // Filter Dashboard (ringkas: chip filter aktif + bottom sheet)
        // =================================================
        staggered(
          DashboardFilterPanel(
            districtOptions: dashboard.filterOptions.districts,
            dataSourceOptions: dashboard.filterOptions.dataSources,
            initialValues: _filterValues,
            isLoading: _isLoading,
            onApply: _applyFilters,
            onReset: _resetFilters,
          ),
        ),

        if (insights.isNotEmpty) ...[
          const SizedBox(height: 22),
          staggered(_buildInsightsPanel(insights)),
        ],

        const SizedBox(height: 22),
        staggered(
          _buildSectionTitle(
            title: 'Ringkasan Pengawasan',
            subtitle: 'Statistik data pengawasan pada periode terpilih.',
          ),
        ),
        const SizedBox(height: 14),
        staggered(_buildSummaryRow(dashboard.summary)),
        const SizedBox(height: 24),
        staggered(_buildDataCompositionSection(dashboard.summary)),

        // SEBARAN PENGAWASAN PER KABUPATEN/KOTA (Top 10 | tabel lengkap)
        // ============================================================
        const SizedBox(height: 24),
        staggered(
          DashboardChartTableCard(
            title: 'Sebaran Pengawasan per Kabupaten/Kota',
            subtitle: 'Perbandingan data OSS, Non OSS, dan total pengawasan.',
            chartData: districtChart,
            chartBuilder: (context, showTable) => DashboardRankedBarChart(
              data: districtChart,
              rankSeriesIndex: 0,
              topN: 10,
              onShowAll: showTable,
            ),
            columns: const ['Kabupaten', 'OSS', 'Non OSS', 'Total'],
            columnColors: const [
              null,
              AppTheme.categoryOss,
              AppTheme.categoryNonOss,
              AppTheme.categoryTotal,
            ],
            rows: dashboard.districtRecap.map((row) {
              return [
                row['nama_kabupaten']?.toString() ?? '-',
                row['oss']?.toString() ?? '0',
                row['non_oss']?.toString() ?? '0',
                row['total']?.toString() ?? '0',
              ];
            }).toList(),
          ),
        ),

        // LEGALITAS NIB (grafik | tabel)
        // ============================================================
        const SizedBox(height: 16),
        staggered(
          DashboardChartTableCard(
            title: 'Legalitas NIB $_labelBidang',
            subtitle: 'Kepemilikan NIB berdasarkan Kabupaten/Kota.',
            chartData: ChartSeriesData.fromDynamic(
              dashboard
                  .charts
                  .district, // <-- sebelumnya: dashboard.charts.legalitasNib
              seriesConfig: const [
                MapEntry('nib_ya', AppTheme.answerYes),
                MapEntry('nib_tidak', AppTheme.answerNo),
                MapEntry('nib_tidak_tahu', AppTheme.answerUnknown),
              ],
              seriesLabelOverride: const {
                'nib_ya': 'Memiliki NIB',
                'nib_tidak': 'Tidak Memiliki',
                'nib_tidak_tahu': 'Tidak Tahu',
              },
            ),
            columns: const [
              'Kabupaten',
              'Memiliki NIB',
              'Tidak Memiliki',
              'Tidak Tahu',
              'Total',
            ],
            columnColors: const [
              null,
              AppTheme.answerYes,
              AppTheme.answerNo,
              AppTheme.answerUnknown,
              AppTheme.categoryTotal,
            ],
            rows: dashboard.districtRecap.map((row) {
              // <-- sebelumnya: dashboard.legalitasNibRecap
              return [
                row['nama_kabupaten']?.toString() ?? '-',
                row['nib_ya']?.toString() ?? '0',
                row['nib_tidak']?.toString() ?? '0',
                row['nib_tidak_tahu']?.toString() ?? '0',
                row['total']?.toString() ?? '0',
              ];
            }).toList(),
          ),
        ),

        // STATUS PENDAFTARAN PLATFORM OTA (grafik | tabel)
        // ============================================================
        const SizedBox(height: 16),
        staggered(
          DashboardChartTableCard(
            title: 'Status Pendaftaran Platform OTA',
            subtitle: 'Perbandingan usaha terdaftar dan tidak terdaftar OTA.',
            chartData: ChartSeriesData.fromDynamic(
              dashboard
                  .charts
                  .district, // <-- sebelumnya: dashboard.charts.statusOta
              seriesConfig: const [
                MapEntry('ota_ya', AppTheme.categoryOta),
                MapEntry('ota_tidak', AppTheme.answerNone),
              ],
              seriesLabelOverride: const {
                'ota_ya': 'Terdaftar OTA',
                'ota_tidak': 'Tidak Terdaftar',
              },
            ),
            columns: const [
              'Kabupaten',
              'Terdaftar OTA',
              'Tidak Terdaftar',
              'Total',
            ],
            columnColors: const [
              null,
              AppTheme.categoryOta,
              AppTheme.answerNone,
              AppTheme.categoryTotal,
            ],
            rows: dashboard.districtRecap.map((row) {
              return [
                row['nama_kabupaten']?.toString() ??
                    '-', // <-- perbaikan masalah 1
                row['ota_ya']?.toString() ?? '0',
                row['ota_tidak']?.toString() ?? '0',
                row['total']?.toString() ?? '0',
              ];
            }).toList(),
          ),
        ),

        // JENIS PRODUK (grafik | tabel)
        // ============================================================
        const SizedBox(height: 16),
        staggered(
          DashboardChartTableCard(
            title: 'Jenis Produk',
            subtitle: 'Komposisi jenis produk berdasarkan sumber data.',
            chartData: ChartSeriesData.fromDynamic(
              dashboard.charts.productType,
              seriesConfig: const [
                MapEntry('total', AppTheme.categoryTotal),
                MapEntry('oss', AppTheme.categoryOss),
                MapEntry('non_oss', AppTheme.categoryNonOss),
              ],
            ),
            columns: const ['Jenis Produk', 'OSS', 'Non OSS', 'Total'],
            columnColors: const [
              null,
              AppTheme.categoryOss,
              AppTheme.categoryNonOss,
              AppTheme.categoryTotal,
            ],
            rows: dashboard.productTypeRecap.map((row) {
              return [
                row['jenis_produk']?.toString() ?? '-',
                row['oss']?.toString() ?? '0',
                row['non_oss']?.toString() ?? '0',
                row['total']?.toString() ?? '0',
              ];
            }).toList(),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 18),
          _buildRefreshWarning(),
        ],
        if (dashboard.map.displayed && points.isNotEmpty)
          const SizedBox(height: 48),
        DashboardMapSection(points: points, config: config),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _refreshDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double contentWidth = constraints.maxWidth >= 1100
              ? 1080
              : constraints.maxWidth;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildDashboardContent()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header KPI: Total Pengawasan sebagai angka utama, cincin persentase
  /// verifikasi selesai, jumlah selesai/draft, periode, dan pilihan provinsi.
  Widget _buildKpiHeader(DashboardData dashboard) {
    final DashboardSummary summary = dashboard.summary;
    final List<ProvinceOption> provinces = dashboard.filterOptions.provinces;

    final bool provinceExists = provinces.any(
      (item) => item.slug == _selectedProvince,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261565C0),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: Colors.white.withValues(alpha: 0.86),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total Pengawasan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUpText(
                        value: summary.total,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dashboard.province.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RingGauge(percentage: summary.completedPercentage),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _KpiPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Selesai',
                  value: summary.completed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiPill(
                  icon: Icons.edit_note_rounded,
                  label: 'Draft',
                  value: summary.draft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    dashboard.period.label.isEmpty
                        ? 'Semua periode'
                        : dashboard.period.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (provinces.isNotEmpty) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: provinceExists ? _selectedProvince : null,
              isExpanded: true,
              dropdownColor: AppTheme.surface(context),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Pilih Provinsi',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.13),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              selectedItemBuilder: (context) {
                return provinces.map((item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList();
              },
              items: provinces.map((item) {
                return DropdownMenuItem<String>(
                  value: item.slug,
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        _changeProvince(value);
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(List<DashboardInsight> insights) {
    return _DashboardPanel(
      title: 'Sorotan',
      subtitle: 'Temuan otomatis dari data pada periode terpilih.',
      icon: Icons.insights_rounded,
      iconColor: AppTheme.primaryColor,
      child: Column(
        children: [
          for (int i = 0; i < insights.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: AppTheme.border(context)),
              const SizedBox(height: 14),
            ],
            _InsightTile(insight: insights[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Tiga kartu ringkas (OSS, Non-OSS, OTA). Total sudah jadi angka utama
  /// di header.
  Widget _buildSummaryRow(DashboardSummary summary) {
    final List<_StatisticData> statistics = [
      _StatisticData(
        title: 'Data OSS',
        value: summary.oss,
        icon: Icons.verified_outlined,
        color: AppTheme.categoryOss,
        backgroundColor: AppTheme.categoryOssBg,
      ),
      _StatisticData(
        title: 'Data Non-OSS',
        value: summary.nonOss,
        icon: Icons.domain_add_outlined,
        color: AppTheme.categoryNonOss,
        backgroundColor: AppTheme.categoryNonOssBg,
      ),
      _StatisticData(
        title: 'Terdaftar OTA',
        value: summary.ota,
        icon: Icons.travel_explore_rounded,
        color: AppTheme.categoryOta,
        backgroundColor: AppTheme.categoryOtaBg,
      ),
    ];

    return SizedBox(
      height: 128,
      child: Row(
        children: [
          for (int i = 0; i < statistics.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _StatisticCard(data: statistics[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildDataCompositionSection(DashboardSummary summary) {
    final double ossPercentage = _percentage(summary.oss, summary.total);

    final double nonOssPercentage = _percentage(summary.nonOss, summary.total);

    final double otaPercentage = _percentage(summary.ota, summary.total);

    return _DashboardPanel(
      title: 'Komposisi Data',
      subtitle: 'Distribusi berdasarkan sumber data pengawasan.',
      icon: Icons.donut_large_rounded,
      iconColor: AppTheme.categoryTotal,
      child: Column(
        children: [
          _CompositionRow(
            label: 'OSS',
            value: summary.oss,
            percentage: ossPercentage,
            color: AppTheme.categoryOss,
          ),
          const SizedBox(height: 17),
          _CompositionRow(
            label: 'Non-OSS',
            value: summary.nonOss,
            percentage: nonOssPercentage,
            color: AppTheme.categoryNonOss,
          ),
          const SizedBox(height: 17),
          _CompositionRow(
            label: 'Terdaftar OTA',
            value: summary.ota,
            percentage: otaPercentage,
            color: AppTheme.categoryOta,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Data terbaru gagal dimuat. Data sebelumnya masih ditampilkan.',
              style: const TextStyle(
                color: AppTheme.warning,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _percentage(int value, int total) {
    if (total <= 0) return 0;

    return (value / total * 100).clamp(0, 100).toDouble();
  }
}

// ======================================================================
// Header KPI
// ======================================================================

/// Cincin persentase verifikasi selesai di header.
class _RingGauge extends StatelessWidget {
  const _RingGauge({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Verifikasi selesai ${percentage.toStringAsFixed(1)} persen',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: (percentage / 100).clamp(0.0, 1.0),
          ),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: 94,
              height: 94,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(94, 94),
                    painter: _RingGaugePainter(value),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Selesai',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  _RingGaugePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 9;
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - stroke / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7CFFB2),
    );
  }

  @override
  bool shouldRepaint(_RingGaugePainter old) => old.progress != progress;
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CountUpText(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Sorotan
// ======================================================================

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final DashboardInsight insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: insight.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(insight.icon, color: insight.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                insight.body,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Kartu & panel
// ======================================================================

class _StatisticData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatisticData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

class _StatisticCard extends StatelessWidget {
  final _StatisticData data;

  const _StatisticCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.tintBackground(
                context,
                data.color,
                data.backgroundColor,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpText(
              value: data.value,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _CompositionRow extends StatelessWidget {
  final String label;
  final int value;
  final double percentage;
  final Color color;

  const _CompositionRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double safePercentage = percentage.clamp(0, 100).toDouble();

    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          formatNumber(value),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            '${safePercentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Skeleton (menggantikan spinner "Memuat dashboard...")
// ======================================================================

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat dashboard',
      child: ExcludeSemantics(
        child: SkeletonShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 250, radius: 22),
              const SizedBox(height: 16),
              const SkeletonBox(height: 56, radius: 16),
              const SizedBox(height: 22),
              const SkeletonBox(width: 170, height: 20, radius: 6),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                ],
              ),
              const SizedBox(height: 24),
              const SkeletonBox(height: 190, radius: 20),
              const SizedBox(height: 24),
              const SkeletonBox(height: 340, radius: 20),
            ],
          ),
        ),
      ),
    );
  }
}
