// dashboard_filter_panel.dart
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

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
  String? get startDateApiFormat => _formatDate(startDate);
  String? get endDateApiFormat => _formatDate(endDate);

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Tampilan tanggal untuk pengguna: dd/mm/yyyy.
String _displayDate(DateTime date) {
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface(context),
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _FilterSheet(
          districtOptions: districtOptions,
          dataSourceOptions: dataSourceOptions,
          initialValues: initialValues,
          onApply: (values) {
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

  String _periodLabel(DashboardFilterValues v) {
    final DateTime? start = v.startDate;
    final DateTime? end = v.endDate;
    if (start != null && end != null) {
      return '${_displayDate(start)} – ${_displayDate(end)}';
    }
    if (start != null) return 'Mulai ${_displayDate(start)}';
    return 'Sampai ${_displayDate(end!)}';
  }

  List<_ActiveChipData> _buildChips() {
    final DashboardFilterValues v = initialValues;
    final List<_ActiveChipData> chips = [];

    if (v.bidangUsaha != null) {
      chips.add(
        _ActiveChipData(
          icon: Icons.business_center_outlined,
          label: BidangUsahaOpsi.namaDari(v.bidangUsaha) ?? v.bidangUsaha!,
          onRemove: () => onApply(v.copyWith(clearBidangUsaha: true)),
        ),
      );
    }

    if (v.startDate != null || v.endDate != null) {
      chips.add(
        _ActiveChipData(
          icon: Icons.calendar_month_rounded,
          label: _periodLabel(v),
          onRemove: () =>
              onApply(v.copyWith(clearStartDate: true, clearEndDate: true)),
        ),
      );
    }

    if (v.districtId != null) {
      chips.add(
        _ActiveChipData(
          icon: Icons.location_city_rounded,
          label: _districtName(v.districtId) ?? 'Kabupaten/Kota',
          onRemove: () => onApply(v.copyWith(clearDistrictId: true)),
        ),
      );
    }

    if (v.dataSource != null) {
      chips.add(
        _ActiveChipData(
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
    final List<_ActiveChipData> chips = _buildChips();
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
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final _ActiveChipData chip in chips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ActiveChip(
                              data: chip,
                              enabled: !isLoading,
                            ),
                          ),
                      ],
                    ),
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

class _ActiveChipData {
  const _ActiveChipData({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.data, required this.enabled});

  final _ActiveChipData data;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            data.label,
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: enabled ? data.onRemove : null,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: accent),
            ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.menuDashboardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.filter_alt_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Dashboard',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesuaikan data berdasarkan periode dan wilayah.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppTheme.border(context)),
            const SizedBox(height: 16),
            _buildBidangDropdown(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Tanggal Mulai',
                    value: _draft.startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'Tanggal Sampai',
                    value: _draft.endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDistrictDropdown(),
            const SizedBox(height: 14),
            _buildDataSourceDropdown(),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => widget.onApply(_draft),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Tampilkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBidangDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Bidang Usaha'),
        DropdownButtonFormField<String?>(
          initialValue: _draft.bidangUsaha,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          decoration: _dropdownDecoration(),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua Bidang'),
            ),
            ...BidangUsahaOpsi.daftar.map(
              (b) => DropdownMenuItem<String?>(
                value: b.slug,
                child: Text(b.nama, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _draft = value == null
                  ? _draft.copyWith(clearBidangUsaha: true)
                  : _draft.copyWith(bidangUsaha: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final String display = value == null ? 'dd/mm/yyyy' : _displayDate(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldColorDynamic(context),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: value == null
                          ? AppTheme.textMuted
                          : AppTheme.textColor(context),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Kabupaten/Kota'),
        DropdownButtonFormField<int?>(
          initialValue: _draft.districtId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          decoration: _dropdownDecoration(),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Semua Kabupaten/Kota'),
            ),
            ...widget.districtOptions.map(
              (district) => DropdownMenuItem<int?>(
                value: district.id,
                child: Text(district.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _draft = value == null
                  ? _draft.copyWith(clearDistrictId: true)
                  : _draft.copyWith(districtId: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDataSourceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Sumber Data'),
        DropdownButtonFormField<String?>(
          initialValue: _draft.dataSource,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          decoration: _dropdownDecoration(),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua Sumber'),
            ),
            ...widget.dataSourceOptions.map(
              (source) =>
                  DropdownMenuItem<String?>(value: source, child: Text(source)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _draft = value == null
                  ? _draft.copyWith(clearDataSource: true)
                  : _draft.copyWith(dataSource: value);
            });
          },
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppTheme.scaffoldColorDynamic(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppTheme.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
    );
  }
}