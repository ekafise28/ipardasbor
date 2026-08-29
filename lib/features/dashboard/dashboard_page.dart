import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

import '../non_oss/offline/non_oss_local_data.dart';
import '../non_oss/offline/offline_database.dart';
import '../non_oss/offline/sync_service.dart';
import '../non_oss/services/non_oss_service.dart';

import 'models/dashboard_data.dart';

import 'models/chart_series.dart';
import 'models/dashboard_map_model.dart';

import 'widget/dashboard_bar_chart.dart';
import 'widget/dashboard_data_table.dart';
import 'widget/dashboard_map_section.dart';
import 'widget/dashboard_horizontal_bar_chart.dart';
import 'widget/dashboard_filter_panel.dart';

import 'services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  late final ApiClient _syncApi;
  late final NonOssSyncService _syncService;
  final OfflineDatabase _offlineDatabase = OfflineDatabase.instance;

  DashboardData? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  List<NonOssLocalData> _waitingData = <NonOssLocalData>[];
  final Set<String> _syncingIds = <String>{};
  bool _isLoadingQueue = true;
  bool _isSyncingAll = false;

  String _selectedProvince = 'jawa-timur';

  DashboardFilterValues _filterValues = DashboardFilterValues.empty;

  @override
  void initState() {
    super.initState();
    _syncApi = ApiClient();
    _syncService = NonOssSyncService(remote: NonOssService(_syncApi));
    _loadDashboard();
    _loadWaitingData();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    _syncApi.close();
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

      setState(() {
        _dashboard = result;
        _selectedProvince = result.province.slug;
        _isLoading = false;
        _errorMessage = null;
      });
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
    await Future.wait<void>(<Future<void>>[
      _loadDashboard(showLoading: false),
      _loadWaitingData(),
    ]);
  }

  Future<void> _loadWaitingData() async {
    try {
      await _offlineDatabase.restoreInterruptedSyncs();
      final List<NonOssLocalData> result = await _offlineDatabase.getWaiting(
        limit: 500,
      );
      if (!mounted) return;
      setState(() {
        _waitingData = result;
        _isLoadingQueue = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingQueue = false);
    }
  }

  Future<void> _syncOne(NonOssLocalData data) async {
    if (_syncingIds.contains(data.clientUuid)) return;

    setState(() => _syncingIds.add(data.clientUuid));

    bool success = false;

    try {
      success = await _syncService
          .syncOne(data)
          .timeout(const Duration(seconds: 30));

      await _loadWaitingData();

      if (success) {
        await _loadDashboard(showLoading: false);
      }
    } on TimeoutException {
      success = false;
    } catch (_) {
      success = false;
    } finally {
      if (mounted) {
        setState(() => _syncingIds.remove(data.clientUuid));
      }
    }

    if (!mounted) return;

    _showSyncMessage(
      success
          ? '${data.displayName} berhasil disinkronkan. Dashboard diperbarui.'
          : 'Sinkronisasi gagal. Periksa internet atau server lalu coba lagi.',
      success: success,
    );
  }

  Future<void> _syncAll() async {
    if (_isSyncingAll || _waitingData.isEmpty) return;
    setState(() => _isSyncingAll = true);

    final int before = _waitingData.length;

    int synced = 0;

    try {
      await _syncService
          .syncWaiting(limit: 500)
          .timeout(const Duration(seconds: 60));

      await _loadWaitingData();
      synced = before - _waitingData.length;

      if (synced > 0) {
        await _loadDashboard(showLoading: false);
      }
    } on TimeoutException {
      synced = 0;
    } catch (_) {
      synced = 0;
    } finally {
      if (mounted) {
        setState(() => _isSyncingAll = false);
      }
    }

    if (!mounted) return;

    _showSyncMessage(
      synced > 0
          ? '$synced data berhasil disinkronkan. Dashboard diperbarui.'
          : 'Belum ada data yang terkirim. Periksa internet/server.',
      success: synced > 0,
    );
  }

  void _showSyncMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? const Color(0xFF238636)
              : const Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF17243A)),
        ),
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFF17243A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Ringkasan Pengawasan Pariwisata',
              style: TextStyle(
                color: Color(0xFF7A879A),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
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
                    await _loadWaitingData();
                  },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5E6B7E)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return const _DashboardLoading();
    }

    if (_errorMessage != null && _dashboard == null) {
      return _DashboardError(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final DashboardData? dashboard = _dashboard;

    if (dashboard == null) {
      return _DashboardError(
        message: 'Data dashboard tidak tersedia.',
        onRetry: _loadDashboard,
      );
    }

    final points = parseMapPoints(dashboard.map.points);
    final config = MapConfigData.fromJson(dashboard.map.configuration);

    return RefreshIndicator(
      color: const Color(0xFF1565C0),
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
                  children: [
                    _buildDashboardHeader(dashboard),

                    const SizedBox(height: 18),

                    // Filter Dashboard
                    // =================================================
                    DashboardFilterPanel(
                      districtOptions: dashboard.filterOptions.districts,
                      dataSourceOptions: dashboard.filterOptions.dataSources,
                      initialValues: _filterValues,
                      isLoading: _isLoading,
                      onApply: (values) {
                        setState(() => _filterValues = values);
                        _loadDashboard(showLoading: false);
                      },
                      onReset: () {
                        setState(
                          () => _filterValues = DashboardFilterValues.empty,
                        );
                        _loadDashboard(showLoading: false);
                      },
                    ),
                    // Filter Dashboard
                    // =================================================

                    // if (dashboard.map.displayed && points.isNotEmpty)
                    //   DashboardMapSection(points: points, config: config),
                    const SizedBox(height: 18),
                    _buildOfflineQueueSection(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      title: 'Ringkasan Pengawasan',
                      subtitle:
                          'Statistik data pengawasan pada periode terpilih.',
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryGrid(context, dashboard.summary),
                    const SizedBox(height: 24),
                    _buildVerificationSection(dashboard.summary),
                    const SizedBox(height: 24),
                    _buildDataCompositionSection(dashboard.summary),
                    const SizedBox(height: 24),
                    _buildRecapSection(dashboard),

                    // Start SEBARAN PENGAWASAN PER KABUPATEN/KOTA
                    // ============================================================
                    const SizedBox(height: 24),
                    DashboardBarChart(
                      title: 'Sebaran Pengawasan per Kabupaten/Kota',
                      subtitle:
                          'Perbandingan data OSS, Non OSS, dan total pengawasan.',
                      data: ChartSeriesData.fromDynamic(
                        dashboard.charts.district,
                        seriesConfig: const [
                          MapEntry('total', Color(0xFF0878F9)),
                          MapEntry('oss', Color(0xFF16A66A)),
                          MapEntry('non_oss', Color(0xFF7857E6)),
                        ],
                        seriesLabelOverride: const {
                          'total': 'Total Pengawasan',
                          'oss': 'OSS',
                          'non_oss': 'Non OSS',
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End SEBARAN PENGAWASAN PER KABUPATEN/KOTA
                    // ============================================================

                    // Start Tabel SEBARAN PENGAWASAN PER KABUPATEN/KOTA
                    // ============================================================
                    DashboardDataTable(
                      title: 'Rekap Kabupaten/Kota',
                      columns: const ['Kabupaten', 'Total', 'OSS', 'Non OSS'],
                      rows: dashboard.districtRecap.map((row) {
                        return [
                          row['nama_kabupaten']?.toString() ??
                              '-', // <-- perbaikan masalah 1
                          row['total']?.toString() ?? '0',
                          row['oss']?.toString() ?? '0',
                          row['non_oss']?.toString() ?? '0',
                        ];
                      }).toList(),
                    ),
                    // End Tabel SEBARAN PENGAWASAN PER KABUPATEN/KOTA
                    // ============================================================

                    // Start LEGALITAS NIB USAHA AKOMODASI
                    // ============================================================
                    const SizedBox(height: 48),
                    DashboardBarChart(
                      title: 'Legalitas NIB Usaha Akomodasi',
                      subtitle: 'Kepemilikan NIB berdasarkan Kabupaten/Kota.',
                      data: ChartSeriesData.fromDynamic(
                        dashboard
                            .charts
                            .district, // <-- sebelumnya: dashboard.charts.legalitasNib
                        seriesConfig: const [
                          MapEntry('nib_ya', Color(0xFF16A66A)),
                          MapEntry('nib_tidak', Color(0xFFE05C6E)),
                          MapEntry('nib_tidak_tahu', Color(0xFFF2A93B)),
                        ],
                        seriesLabelOverride: const {
                          'nib_ya': 'Memiliki NIB',
                          'nib_tidak': 'Tidak Memiliki',
                          'nib_tidak_tahu': 'Tidak Tahu',
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End LEGALITAS NIB USAHA AKOMODASI
                    // ============================================================

                    // Start Tabel LEGALITAS NIB USAHA AKOMODASI
                    // ============================================================
                    DashboardDataTable(
                      title: 'Tabel Legalitas NIB',
                      columns: const [
                        'Kabupaten',
                        'Memiliki NIB',
                        'Tidak Memiliki',
                        'Tidak Tahu',
                        'Total',
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
                    // End Tabel LEGALITAS NIB USAHA AKOMODASI
                    // ============================================================

                    // Start STATUS PENDAFTARAN PLATFORM OTA
                    // ============================================================
                    const SizedBox(height: 48),
                    DashboardBarChart(
                      title: 'Status Pendaftaran Platform OTA',
                      subtitle:
                          'Perbandingan usaha terdaftar dan tidak terdaftar OTA.',
                      data: ChartSeriesData.fromDynamic(
                        dashboard
                            .charts
                            .district, // <-- sebelumnya: dashboard.charts.statusOta
                        seriesConfig: const [
                          MapEntry('ota_ya', Color(0xFF2F86EB)),
                          MapEntry('ota_tidak', Color(0xFFB6BEC9)),
                        ],
                        seriesLabelOverride: const {
                          'ota_ya': 'Terdaftar OTA',
                          'ota_tidak': 'Tidak Terdaftar',
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End STATUS PENDAFTARAN PLATFORM OTA
                    // ============================================================

                    // Start Tabel STATUS PENDAFTARAN PLATFORM OTA
                    // ============================================================
                    DashboardDataTable(
                      title: 'Tabel Status Pendaftaran OTA',
                      columns: const [
                        'Kabupaten',
                        'Terdaftar OTA',
                        'Tidak Terdaftar',
                        'Total',
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

                    // End Tabel STATUS PENDAFTARAN PLATFORM OTA
                    // ============================================================

                    // ============================================================
                    // Start JENIS PRODUK AKOMODASI (versi horizontal + tabel)
                    // ============================================================
                    // const SizedBox(height: 24),
                    // DashboardHorizontalBarChart(
                    //   title: 'Jenis Produk Akomodasi',
                    //   subtitle:
                    //       'Komposisi jenis produk berdasarkan sumber data.',
                    //   data: ChartSeriesData.fromDynamic(
                    //     dashboard.charts.productType,
                    //     seriesConfig: const [
                    //       MapEntry('total', Color(0xFF0878F9)),
                    //       MapEntry('oss', Color(0xFF16A66A)),
                    //       MapEntry('non_oss', Color(0xFF7857E6)),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    DashboardBarChart(
                      title: 'Jenis Produk Akomodasi',
                      subtitle:
                          'Komposisi jenis produk berdasarkan sumber data.',
                      data: ChartSeriesData.fromDynamic(
                        dashboard.charts.productType,
                        seriesConfig: const [
                          MapEntry('total', Color(0xFF0878F9)),
                          MapEntry('oss', Color(0xFF16A66A)),
                          MapEntry('non_oss', Color(0xFF7857E6)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DashboardDataTable(
                      title: 'Tabel Jenis Produk Akomodasi',
                      columns: const [
                        'Jenis Produk',
                        'OSS',
                        'Non OSS',
                        'Total',
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

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 18),
                      _buildRefreshWarning(),
                    ],
                    if (dashboard.map.displayed && points.isNotEmpty)
                      const SizedBox(height: 48),
                    DashboardMapSection(points: points, config: config),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineQueueSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1218273D),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFF9F0A), Color(0xFFFF6B00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Menunggu Sinkronisasi',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_waitingData.length} data tersimpan aman di perangkat',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _waitingData.isEmpty || _isSyncingAll
                    ? null
                    : _syncAll,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: _isSyncingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_isSyncingAll ? 'Proses' : 'Sync Semua'),
              ),
            ],
          ),
          if (_isLoadingQueue) ...<Widget>[
            const SizedBox(height: 20),
            const LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF007AFF),
              backgroundColor: Color(0xFFEFF3F8),
            ),
          ] else if (_waitingData.isEmpty) ...<Widget>[
            const SizedBox(height: 18),
            const _QueueEmptyState(),
          ] else ...<Widget>[
            const SizedBox(height: 16),
            ..._waitingData.map(
              (NonOssLocalData data) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PendingDataTile(
                  data: data,
                  syncing: _syncingIds.contains(data.clientUuid),
                  onSync: () => _syncOne(data),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(DashboardData dashboard) {
    final List<ProvinceOption> provinces = dashboard.filterOptions.provinces;

    final bool provinceExists = provinces.any(
      (item) => item.slug == _selectedProvince,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Pengawasan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dashboard.province.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              dropdownColor: Colors.white,
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
                    style: const TextStyle(
                      color: Color(0xFF17243A),
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

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF17243A),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF7A879A),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, DashboardSummary summary) {
    final List<_StatisticData> statistics = [
      _StatisticData(
        title: 'Total Pengawasan',
        value: summary.total,
        icon: Icons.assessment_rounded,
        color: const Color(0xFF7B1FA2),
        backgroundColor: const Color(0xFFF3E5F5),
      ),
      _StatisticData(
        title: 'Data OSS',
        value: summary.oss,
        icon: Icons.verified_outlined,
        color: const Color(0xFF1565C0),
        backgroundColor: const Color(0xFFE8F1FD),
      ),
      _StatisticData(
        title: 'Data Non-OSS',
        value: summary.nonOss,
        icon: Icons.domain_add_outlined,
        color: const Color(0xFF00897B),
        backgroundColor: const Color(0xFFE2F5F1),
      ),
      _StatisticData(
        title: 'Terdaftar OTA',
        value: summary.ota,
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFFD84315),
        backgroundColor: const Color(0xFFFBE9E7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double childAspectRatio = 1.04;

        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.55;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.15;
        } else if (constraints.maxWidth < 370) {
          childAspectRatio = 0.88;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _StatisticCard(data: statistics[index]);
          },
        );
      },
    );
  }

  Widget _buildVerificationSection(DashboardSummary summary) {
    return _DashboardPanel(
      title: 'Progres Verifikasi',
      subtitle: 'Perbandingan data selesai dan masih draft.',
      icon: Icons.fact_check_outlined,
      iconColor: const Color(0xFF1565C0),
      child: Column(
        children: [
          _ProgressItem(
            label: 'Verifikasi Selesai',
            value: summary.completed,
            percentage: summary.completedPercentage,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 22),
          _ProgressItem(
            label: 'Masih Draft',
            value: summary.draft,
            percentage: summary.draftPercentage,
            color: const Color(0xFFEF6C00),
          ),
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
      iconColor: const Color(0xFF7B1FA2),
      child: Column(
        children: [
          _CompositionRow(
            label: 'OSS',
            value: summary.oss,
            percentage: ossPercentage,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 17),
          _CompositionRow(
            label: 'Non-OSS',
            value: summary.nonOss,
            percentage: nonOssPercentage,
            color: const Color(0xFF00897B),
          ),
          const SizedBox(height: 17),
          _CompositionRow(
            label: 'Terdaftar OTA',
            value: summary.ota,
            percentage: otaPercentage,
            color: const Color(0xFFD84315),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapSection(DashboardData dashboard) {
    return _DashboardPanel(
      title: 'Data Pendukung',
      subtitle: 'Jumlah kategori pada hasil rekapitulasi.',
      icon: Icons.table_chart_outlined,
      iconColor: const Color(0xFF455A64),
      child: Column(
        children: [
          _RecapTile(
            icon: Icons.location_city_rounded,
            title: 'Kabupaten/Kota',
            value: dashboard
                .districtRecap
                .length, // sebelumnya: dashboard.totalDistrict
            color: const Color(0xFF1565C0),
          ),
          const Divider(height: 25),
          _RecapTile(
            icon: Icons.travel_explore_rounded,
            title: 'Platform OTA',
            value: dashboard
                .platformRecap
                .length, // sebelumnya: dashboard.totalPlatform
            color: const Color(0xFFD84315),
          ),
          const Divider(height: 25),
          _RecapTile(
            icon: Icons.hotel_rounded,
            title: 'Jenis Produk',
            value: dashboard
                .productTypeRecap
                .length, // sebelumnya: dashboard.totalProductType
            color: const Color(0xFF7B1FA2),
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
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Data terbaru gagal dimuat. Data sebelumnya masih ditampilkan.',
              style: const TextStyle(
                color: Color(0xFF8A4B08),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF2)),
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
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 23),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatNumber(data.value),
              style: const TextStyle(
                color: Color(0xFF17243A),
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6F7C90),
              fontSize: 12,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF2)),
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
                      style: const TextStyle(
                        color: Color(0xFF17243A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A879A),
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

class _ProgressItem extends StatelessWidget {
  final String label;
  final int value;
  final double percentage;
  final Color color;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double safePercentage = percentage.clamp(0, 100).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF344156),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _formatNumber(value),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${safePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: safePercentage / 100,
            minHeight: 9,
            backgroundColor: const Color(0xFFEDF0F5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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
            style: const TextStyle(
              color: Color(0xFF344156),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: Color(0xFF17243A),
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

class _RecapTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final Color color;

  const _RecapTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF344156),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Memuat dashboard...',
              style: TextStyle(
                color: Color(0xFF5E6B7E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function({bool showLoading}) onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFC62828),
                size: 39,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dashboard gagal dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF17243A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF748197),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                onRetry(showLoading: true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingDataTile extends StatelessWidget {
  const _PendingDataTile({
    required this.data,
    required this.syncing,
    required this.onSync,
  });

  final NonOssLocalData data;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final bool failed = data.isFailed;
    final Color statusColor = failed
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFF9500);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              failed ? Icons.error_outline_rounded : Icons.schedule_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        failed ? 'GAGAL' : 'PENDING',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(data.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF7C8798),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (failed && data.lastError != null) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    data.lastError!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: failed ? 'Coba lagi' : 'Sinkronkan',
            onPressed: syncing ? null : onSync,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEAF3FF),
              foregroundColor: const Color(0xFF007AFF),
              disabledBackgroundColor: const Color(0xFFE5E7EB),
            ),
            icon: syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF007AFF),
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _QueueEmptyState extends StatelessWidget {
  const _QueueEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF4),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: Color(0xFF24A148)),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Semua data sudah tersinkronisasi.',
              style: TextStyle(
                color: Color(0xFF176B36),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatNumber(int value) {
  final String source = value.toString();
  final StringBuffer result = StringBuffer();

  for (int index = 0; index < source.length; index++) {
    final int remaining = source.length - index;

    result.write(source[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      result.write('.');
    }
  }

  return result.toString();
}
