// dashboard_filter_panel.dart
import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';

/// Nilai filter yang dipilih user, sebelum ditekan "Tampilkan".
/// Dipisah dari filter yang sedang aktif di [DashboardService] supaya user
/// bisa ubah-ubah filter dulu tanpa langsung memicu request ke server.
class DashboardFilterValues {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? districtId;
  final String? dataSource;

  const DashboardFilterValues({
    this.startDate,
    this.endDate,
    this.districtId,
    this.dataSource,
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
  }) {
    return DashboardFilterValues(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      districtId: clearDistrictId ? null : (districtId ?? this.districtId),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
    );
  }

  static const empty = DashboardFilterValues();

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

/// Panel filter dashboard: rentang tanggal, kabupaten/kota, sumber data,
/// tombol Tampilkan & Reset. Meniru struktur filter yang ada di versi web.
class DashboardFilterPanel extends StatefulWidget {
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

  @override
  State<DashboardFilterPanel> createState() => _DashboardFilterPanelState();
}

class _DashboardFilterPanelState extends State<DashboardFilterPanel> {
  late DashboardFilterValues _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValues;
  }

  @override
  void didUpdateWidget(covariant DashboardFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkronkan draft kalau parent mereset filter dari luar (misal setelah
    // tombol "Coba Lagi" atau navigasi ulang).
    if (oldWidget.initialValues != widget.initialValues) {
      _draft = widget.initialValues;
    }
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

  void _handleReset() {
    setState(() => _draft = DashboardFilterValues.empty);
    widget.onReset();
  }

  void _handleApply() {
    widget.onApply(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  color: Color(0xFF1565C0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Dashboard',
                      style: TextStyle(
                        color: Color(0xFF17243A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sesuaikan data dashboard berdasarkan periode dan wilayah.',
                      style: TextStyle(
                        color: Color(0xFF7A879A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE7EBF2)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 640;

              final List<Widget> fields = [
                _buildDateField(
                  label: 'Tanggal Mulai',
                  value: _draft.startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
                _buildDateField(
                  label: 'Tanggal Sampai',
                  value: _draft.endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
                _buildDistrictDropdown(),
                _buildDataSourceDropdown(),
              ];

              if (!isWide) {
                return Column(
                  children: fields
                      .map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: field,
                          ))
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields
                    .map((field) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: field,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: widget.isLoading ? null : _handleReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5E6B7E),
                  side: const BorderSide(color: Color(0xFFE0E4EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: widget.isLoading ? null : _handleApply,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: const Text('Tampilkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final String display = value == null
        ? 'mm/dd/yyyy'
        : '${value.month.toString().padLeft(2, '0')}/'
            '${value.day.toString().padLeft(2, '0')}/${value.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF344156),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE0E4EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: value == null
                          ? const Color(0xFF9AA5B5)
                          : const Color(0xFF17243A),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Color(0xFF9AA5B5),
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
        const Text(
          'Kabupaten/Kota',
          style: TextStyle(
            color: Color(0xFF344156),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
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
                child: Text(
                  district.name,
                  overflow: TextOverflow.ellipsis,
                ),
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
        const Text(
          'Sumber Data',
          style: TextStyle(
            color: Color(0xFF344156),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
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
              (source) => DropdownMenuItem<String?>(
                value: source,
                child: Text(source),
              ),
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
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE0E4EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF1565C0)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
      ),
    );
  }
}