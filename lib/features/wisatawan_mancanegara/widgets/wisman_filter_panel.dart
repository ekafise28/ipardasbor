// Panel filter dashboard Wisman: Tahun, Bulan, Provinsi/Lokasi, Jenis Pintu,
// Nama Pintu. Tiap kolom membuka lembar pilihan ganda (bisa dicari).

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/wisman_filter.dart';
import '../wisman_format.dart';

class WismanFilterPanel extends StatelessWidget {
  const WismanFilterPanel({
    super.key,
    required this.filter,
    required this.options,
    required this.loading,
    required this.onChanged,
    required this.onApply,
    required this.onReset,
  });

  final WismanFilter filter;
  final WismanFilterOptions options;
  final bool loading;
  final ValueChanged<WismanFilter> onChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  static List<WismanOption> _opsi(List<String> values) =>
      values.map((String v) => WismanOption(v, v)).toList();

  @override
  Widget build(BuildContext context) {
    final List<WismanOption> opsiBulan = <WismanOption>[
      for (int i = 0; i < wismanBulan.length; i++)
        WismanOption('${i + 1}', wismanBulan[i]),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Filter Dashboard',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seluruh kartu, grafik, dan tabel mengikuti filter aktif.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: loading ? null : onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double lebar = (c.maxWidth - 10) / 2;
              Widget kolom(Widget child) =>
                  SizedBox(width: lebar, child: child);

              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: <Widget>[
                  kolom(
                    _FilterField(
                      label: 'Tahun',
                      options: _opsi(options.tahun),
                      selected: filter.tahun,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(tahun: v)),
                    ),
                  ),
                  kolom(
                    _FilterField(
                      label: 'Bulan',
                      options: opsiBulan,
                      selected: filter.bulan,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(bulan: v)),
                    ),
                  ),
                  kolom(
                    _FilterField(
                      label: 'Provinsi/Lokasi',
                      options: _opsi(options.provinsi),
                      selected: filter.provinsi,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(provinsi: v)),
                    ),
                  ),
                  kolom(
                    _FilterField(
                      label: 'Jenis Pintu',
                      options: _opsi(options.pintuMasuk),
                      selected: filter.pintuMasuk,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(pintuMasuk: v)),
                    ),
                  ),
                  SizedBox(
                    width: c.maxWidth,
                    child: _FilterField(
                      label: 'Nama Pintu',
                      options: _opsi(options.namaPintu),
                      selected: filter.namaPintu,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(namaPintu: v)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.filter_alt_rounded, size: 18),
              label: Text(loading ? 'Memuat...' : 'Terapkan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<WismanOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  String get _ringkasan {
    if (selected.isEmpty) return 'Semua';
    final Map<String, String> peta = <String, String>{
      for (final WismanOption o in options) o.value: o.label,
    };
    if (selected.length <= 2) {
      return selected.map((String v) => peta[v] ?? v).join(', ');
    }
    return '${selected.length} dipilih';
  }

  Future<void> _buka(BuildContext context) async {
    final List<String>? hasil = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext _) =>
          _MultiSelectSheet(title: label, options: options, selected: selected),
    );
    if (hasil != null) onChanged(hasil);
  }

  @override
  Widget build(BuildContext context) {
    final bool aktif = selected.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => _buka(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: aktif ? AppTheme.primaryColor : AppTheme.border(context),
              ),
              color: aktif
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _ringkasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: aktif
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary(context),
                      fontSize: 12,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppTheme.textSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<WismanOption> options;
  final List<String> selected;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _dipilih;
  String _cari = '';

  @override
  void initState() {
    super.initState();
    _dipilih = widget.selected.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final double tinggi = MediaQuery.of(context).size.height * 0.75;
    final List<WismanOption> tampil = widget.options
        .where(
          (WismanOption o) =>
              o.label.toLowerCase().contains(_cari.trim().toLowerCase()),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: tinggi),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dipilih.isEmpty ? 'Semua' : '${_dipilih.length} dipilih',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11.5,
                  ),
                ),
                if (widget.options.length > 8) ...<Widget>[
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (String v) => setState(() => _cari = v),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Flexible(
                  child: tampil.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              widget.options.isEmpty
                                  ? 'Opsi belum tersedia.'
                                  : 'Tidak ditemukan.',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: tampil.length,
                          itemBuilder: (BuildContext _, int i) {
                            final WismanOption o = tampil[i];
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppTheme.primaryColor,
                              value: _dipilih.contains(o.value),
                              title: Text(
                                o.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onChanged: (bool? v) => setState(() {
                                if (v == true) {
                                  _dipilih.add(o.value);
                                } else {
                                  _dipilih.remove(o.value);
                                }
                              }),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(_dipilih.clear),
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(
                          widget.options
                              .where(
                                (WismanOption o) => _dipilih.contains(o.value),
                              )
                              .map((WismanOption o) => o.value)
                              .toList(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pilih'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
