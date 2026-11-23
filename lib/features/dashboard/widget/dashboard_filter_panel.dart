// dashboard_filter_panel.dart
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/app_sheet.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';

import '../../../core/constants/bidang_usaha_constants.dart';
import '../models/dashboard_data.dart';

/// Nilai filter yang dipilih user, sebelum ditekan "Tampilkan".
/// Dipisah dari filter yang sedang aktif di [DashboardService] supaya user
/// bisa ubah-ubah filter dulu tanpa langsung memicu request ke server.
class DashboardFilterValues {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? districtId;
  final String? dataSource;
  final String? bidangUsaha;

  const DashboardFilterValues({
    this.startDate,
    this.endDate,
    this.districtId,
    this.dataSource,
    this.bidangUsaha,
  });

  DashboardFilterValues copyWith({
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    int? districtId,
    bool clearDistrictId = false,
    String? dataSource,
    bool clearDataSource = false,
    String? bidangUsaha,
    bool clearBidangUsaha = false,
  }) {
    return DashboardFilterValues(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      districtId: clearDistrictId ? null : (districtId ?? this.districtId),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      bidangUsaha: clearBidangUsaha ? null : (bidangUsaha ?? this.bidangUsaha),
    );
  }

  static const empty = DashboardFilterValues();

  /// Jumlah filter yang sedang aktif. Rentang tanggal dihitung satu.
  int get activeCount {
    int count = 0;
    if (bidangUsaha != null) count++;
    if (startDate != null || endDate != null) count++;
    if (districtId != null) count++;
    if (dataSource != null) count++;
    return count;
  }

  /// Format tanggal siap dikirim ke DashboardService (YYYY-MM-DD),
  /// null kalau belum dipilih.
  String? get startDateApiFormat => formatTanggalApiOrNull(startDate);
  String? get endDateApiFormat => formatTanggalApiOrNull(endDate);
}

/// Baris filter ringkas di halaman dashboard.
///
/// Menampilkan filter yang sedang aktif sebagai chip (bisa dihapus satu per
/// satu dengan ikon silang) dan tombol "Filter" yang membuka bottom sheet
/// untuk mengubah semua filter sekaligus. Nama kelas dan parameternya
/// sengaja dipertahankan supaya pemanggil di halaman dashboard tidak perlu
/// diubah.
class DashboardFilterPanel extends StatelessWidget {
  final List<DistrictOption> districtOptions;
  final List<String> dataSourceOptions;
  final DashboardFilterValues initialValues;
  final bool isLoading;
  final ValueChanged<DashboardFilterValues> onApply;
  final VoidCallback onReset;

  const DashboardFilterPanel({
    super.key,
    required this.districtOptions,
    required this.dataSourceOptions,
    required this.onApply,
    required this.onReset,
    this.initialValues = DashboardFilterValues.empty,
    this.isLoading = false,
  });

  Future<void> _openSheet(BuildContext context) {
    return showAppSheet<void>(
      context,
      transparan: true,
      builder: (BuildContext sheetContext) {
        return _FilterSheet(
          districtOptions: districtOptions,
          dataSourceOptions: dataSourceOptions,
          initialValues: initialValues,
          onApply: (DashboardFilterValues values) {
            Navigator.of(sheetContext).pop();
            onApply(values);
          },
          onReset: () {
            Navigator.of(sheetContext).pop();
            onReset();
          },
        );
      },
    );
  }

  String? _districtName(int? id) {
    if (id == null) return null;
    for (final DistrictOption option in districtOptions) {
      if (option.id == id) return option.name;
    }
    return null;
  }

  List<FilterChipData> _buildChips() {
    final DashboardFilterValues v = initialValues;
    final List<FilterChipData> chips = [];

    if (v.bidangUsaha != null) {
      chips.add(
        FilterChipData(
          icon: Icons.business_center_outlined,
          label: BidangUsahaOpsi.namaDari(v.bidangUsaha) ?? v.bidangUsaha!,
          onRemove: () => onApply(v.copyWith(clearBidangUsaha: true)),
        ),
      );
    }

    if (v.startDate != null || v.endDate != null) {
      chips.add(
        FilterChipData(
          icon: Icons.calendar_month_rounded,
          label: formatRentangTanggal(v.startDate, v.endDate),
          onRemove: () =>
              onApply(v.copyWith(clearStartDate: true, clearEndDate: true)),
        ),
      );
    }

    if (v.districtId != null) {
      chips.add(
        FilterChipData(
          icon: Icons.location_city_rounded,
          label: _districtName(v.districtId) ?? 'Kabupaten/Kota',
          onRemove: () => onApply(v.copyWith(clearDistrictId: true)),
        ),
      );
    }

    if (v.dataSource != null) {
      chips.add(
        FilterChipData(
          icon: Icons.storage_rounded,
          label: v.dataSource!,
          onRemove: () => onApply(v.copyWith(clearDataSource: true)),
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final List<FilterChipData> chips = _buildChips();
    final int activeCount = initialValues.activeCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 9, 9, 9),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: chips.isEmpty
                ? Text(
                    'Semua data • tanpa filter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : ActiveFilterChips(
                    chips: chips,
                    enabled: !isLoading,
                    padding: EdgeInsets.zero,
                    onResetAll: onReset,
                  ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: isLoading ? null : () => _openSheet(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(activeCount > 0 ? 'Filter ($activeCount)' : 'Filter'),
          ),
        ],
      ),
    );
  }
}

/// Isi bottom sheet: semua isian filter + tombol Reset / Tampilkan.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.districtOptions,
    required this.dataSourceOptions,
    required this.initialValues,
    required this.onApply,
    required this.onReset,
  });

  final List<DistrictOption> districtOptions;
  final List<String> dataSourceOptions;
  final DashboardFilterValues initialValues;
  final ValueChanged<DashboardFilterValues> onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DashboardFilterValues _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValues;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _draft.startDate : _draft.endDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _draft = isStart
          ? _draft.copyWith(startDate: picked)
          : _draft.copyWith(endDate: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: 'Filter Dashboard',
      subtitle: 'Sesuaikan data berdasarkan periode dan wilayah.',
      icon: Icons.filter_alt_rounded,
      activeCount: _draft.activeCount,
      onReset: widget.onReset,
      onApply: () => widget.onApply(_draft),
      children: <Widget>[
        FilterDropdown<String>(
          label: 'Bidang Usaha',
          value: _draft.bidangUsaha,
          semuaLabel: 'Semua Bidang',
          options: <(String, String)>[
            for (final b in BidangUsahaOpsi.daftar) (b.slug, b.nama),
          ],
          onChanged: (String? v) => setState(() {
            _draft = v == null
                ? _draft.copyWith(clearBidangUsaha: true)
                : _draft.copyWith(bidangUsaha: v);
          }),
        ),
        FilterSection(
          label: 'Periode',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: FilterDateField(
                  label: 'Mulai',
                  placeholder: 'dd/mm/yyyy',
                  text: _draft.startDate == null
                      ? null
                      : formatTanggalAngka(_draft.startDate!),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterDateField(
                  label: 'Sampai',
                  placeholder: 'dd/mm/yyyy',
                  text: _draft.endDate == null
                      ? null
                      : formatTanggalAngka(_draft.endDate!),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
        ),
        FilterDropdown<int>(
          label: 'Kabupaten/Kota',
          value: _draft.districtId,
          semuaLabel: 'Semua Kabupaten/Kota',
          options: <(int, String)>[
            for (final DistrictOption d in widget.districtOptions)
              (d.id, d.name),
          ],
          onChanged: (int? v) => setState(() {
            _draft = v == null
                ? _draft.copyWith(clearDistrictId: true)
                : _draft.copyWith(districtId: v);
          }),
        ),
        FilterDropdown<String>(
          label: 'Sumber Data',
          value: _draft.dataSource,
          semuaLabel: 'Semua Sumber',
          options: <(String, String)>[
            for (final String s in widget.dataSourceOptions) (s, s),
          ],
          onChanged: (String? v) => setState(() {
            _draft = v == null
                ? _draft.copyWith(clearDataSource: true)
                : _draft.copyWith(dataSource: v);
          }),
        ),
      ],
    );
  }
}
