// Kerangka bottom sheet bersama:
//   - showAppSheet / showDraggableSheet / showTitledSheet / showInfoSheet
//   - showOptionSheet (pilih satu, 2-4 opsi) dan showConfirmSheet (ya/tidak)
//   - showMultiSelectSheet + MultiSelectField + OpsiPilihan/HasilOpsi
//     (shared/ tidak boleh mengimpor model fitur, jadi tiap fitur mengubah
//     modelnya ke OpsiPilihan)
//   - FilterSheetFrame dan kolom filter (FilterDropdown, FilterChoiceGroup,
//     FilterDateField, FilterSection, FilterLabel)
//   - PemuatOpsi / IsiPilihan untuk isi sheet yang dimuat async

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_exception.dart';

// ======================================================================
// Dasar
// ======================================================================

/// Membuka bottom sheet dengan pengaturan standar proyek: isScrollControlled
/// selalu aktif supaya tinggi sheet tidak dibatasi setengah layar.
/// [transparan] true = latar transparan, untuk sheet yang menggambar
/// kerangkanya sendiri (mis. FilterSheetFrame).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool transparan = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: transparan
        ? Colors.transparent
        : AppTheme.surface(context),
    shape: transparan
        ? null
        : const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
    builder: builder,
  );
}

/// Sheet detail yang tingginya bisa ditarik; isinya biasanya ListView yang
/// memakai [controller] dari builder.
Future<T?> showDraggableSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController controller)
  builder,
  double initialSize = 0.8,
  double minSize = 0.4,
  double maxSize = 0.95,
}) {
  return showAppSheet<T>(
    context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext _) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: builder,
    ),
  );
}

/// Sheet info/aksi singkat: pegangan bawaan, lalu [builder] mengembalikan
/// isi yang disusun dalam kolom (mis. detail titik peta, pratinjau bagikan).
Future<T?> showInfoSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) builder,
}) {
  return showAppSheet<T>(
    context,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: builder(sheet),
        ),
      ),
    ),
  );
}

/// Satu baris pada [showOptionSheet].
class OpsiSheet<T> {
  const OpsiSheet({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Sheet pilih-satu untuk 2-4 opsi (mis. sumber gambar). Ketuk baris
/// langsung menutup sheet dengan nilainya; null bila ditutup tanpa memilih.
/// Untuk daftar panjang pakai [showMultiSelectSheet] dengan single: true.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required List<OpsiSheet<T>> opsi,
  String? title,
  T? selected,
}) {
  return showAppSheet<T>(
    context,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(sheet),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          for (final OpsiSheet<T> o in opsi)
            ListTile(
              leading: o.icon == null ? null : Icon(o.icon),
              title: Text(o.label),
              subtitle: o.subtitle == null ? null : Text(o.subtitle!),
              trailing: o.value == selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryColor,
                    )
                  : null,
              onTap: () => Navigator.of(sheet).pop(o.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Sheet konfirmasi ya/tidak. Mengembalikan true hanya bila [confirmLabel]
/// ditekan; ditutup tanpa memilih dihitung false. [message] boleh berisi
/// bagian tebal lewat Text.rich; gayanya diwarisi (13, warna sekunder).
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required Widget message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  IconData icon = Icons.warning_amber_rounded,
  Color color = AppTheme.errorStrong,
}) async {
  final bool? hasil = await showAppSheet<bool>(
    context,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor(sheet),
                        ),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textSecondary(sheet),
                        ),
                        child: message,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.surfaceMuted(sheet),
                      foregroundColor: AppTheme.textColor(sheet),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheet).pop(false),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return hasil == true;
}

/// Sheet berjudul: pegangan, judul, tombol X, lalu isi yang bisa digulir.
/// Dipakai untuk tampilan "perbesar grafik" dan sejenisnya.
Future<T?> showTitledSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showAppSheet<T>(
    context,
    builder: (BuildContext sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(sheet),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(sheet),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(child: SingleChildScrollView(child: builder(sheet))),
          ],
        ),
      ),
    ),
  );
}

// ======================================================================
// Pilih beberapa / pilih satu
// ======================================================================

/// Satu pilihan: [value] dikirim ke pemanggil, [label] ditampilkan.
class OpsiPilihan {
  const OpsiPilihan(this.value, this.label);

  final String value;
  final String label;
}

/// Hasil memuat opsi dari server: daftar pilihan + pesan opsional
/// (mis. "Pilih provinsi terlebih dahulu.") yang tampil saat daftar kosong.
class HasilOpsi {
  const HasilOpsi({required this.opsi, this.pesan});

  final List<OpsiPilihan> opsi;
  final String? pesan;
}

/// Pemuat opsi dari server untuk kata kunci [query].
typedef MuatOpsi = Future<HasilOpsi> Function(String query);

/// Membuka sheet pilih-beberapa dengan kolom pencarian.
///
/// Mengembalikan daftar nilai terpilih (kosong = "hapus pilihan"), atau null
/// kalau sheet ditutup tanpa memilih.
///
/// - Opsi statis: isi [opsi]; pencarian menyaring di perangkat.
/// - Opsi dari server: isi [muat]; pencarian memanggil server (tunda 400 ms).
///   Kalau [minKarakter] > 0, server baru dipanggil setelah ketikan sepanjang
///   itu, dan sebelumnya tampil [petunjukAwal].
/// - [single] true = ketuk satu baris langsung menutup sheet dengan satu
///   nilai (tanpa tombol Pilih).
Future<List<String>?> showMultiSelectSheet(
  BuildContext context, {
  required String title,
  required List<String> selected,
  List<OpsiPilihan> opsi = const <OpsiPilihan>[],
  MuatOpsi? muat,
  bool single = false,
  int minKarakter = 0,
  String? petunjukAwal,
  String hintCari = 'Cari...',
}) {
  return showAppSheet<List<String>>(
    context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext _) => _MultiSelectSheet(
      title: title,
      selected: selected,
      opsi: opsi,
      muat: muat,
      single: single,
      minKarakter: minKarakter,
      petunjukAwal: petunjukAwal,
      hintCari: hintCari,
    ),
  );
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.selected,
    required this.opsi,
    required this.muat,
    required this.single,
    required this.minKarakter,
    required this.petunjukAwal,
    required this.hintCari,
  });

  final String title;
  final List<String> selected;
  final List<OpsiPilihan> opsi;
  final MuatOpsi? muat;
  final bool single;
  final int minKarakter;
  final String? petunjukAwal;
  final String hintCari;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _dipilih = <String>{...widget.selected};
  Timer? _debounce;
  int _req = 0;

  String _q = '';
  List<OpsiPilihan> _opsiServer = const <OpsiPilihan>[];
  String? _pesan;
  String? _error;
  bool _loading = false;

  bool get _server => widget.muat != null;
  bool get _perluKetik => _server && widget.minKarakter > 0;

  @override
  void initState() {
    super.initState();
    if (_perluKetik) {
      _pesan = widget.petunjukAwal; // server baru dicari setelah ada ketikan
    } else if (_server) {
      _muat();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String value) {
    _q = value;

    if (!_server) {
      setState(() {}); // saring lokal
      return;
    }

    _debounce?.cancel();

    if (_perluKetik && value.trim().length < widget.minKarakter) {
      _req++; // batalkan respons yang masih berjalan
      setState(() {
        _opsiServer = const <OpsiPilihan>[];
        _pesan = widget.petunjukAwal;
        _error = null;
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), _muat);
  }

  Future<void> _muat() async {
    final int id = ++_req;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final HasilOpsi r = await widget.muat!(_q);
      if (!mounted || id != _req) return;
      setState(() {
        _opsiServer = r.opsi;
        _pesan = r.pesan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _req) return;
      setState(() {
        _opsiServer = const <OpsiPilihan>[];
        _error = pesanErrorRamah(e);
        _loading = false;
      });
    }
  }

  List<OpsiPilihan> get _daftar {
    if (_server) return _opsiServer;
    final String q = _q.trim().toLowerCase();
    if (q.isEmpty) return widget.opsi;
    return widget.opsi
        .where((OpsiPilihan o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  /// Statis: urutan mengikuti daftar opsi. Server: urutan pilih.
  List<String> _hasil() {
    if (_server) return _dipilih.toList();
    return <String>[
      for (final OpsiPilihan o in widget.opsi)
        if (_dipilih.contains(o.value)) o.value,
    ];
  }

  void _toggle(OpsiPilihan o, bool? centang) {
    setState(() {
      if (centang == true) {
        _dipilih.add(o.value);
      } else {
        _dipilih.remove(o.value);
      }
    });
  }

  VoidCallback? _aksiHapus(BuildContext context) {
    if (widget.single) {
      return widget.selected.isEmpty
          ? null
          : () => Navigator.of(context).pop(<String>[]);
    }
    return _dipilih.isEmpty ? null : () => setState(_dipilih.clear);
  }

  Widget _pesanTengah(BuildContext context, String teks) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          teks,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
      ),
    );
  }

  Widget _isi(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _muat,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final List<OpsiPilihan> daftar = _daftar;

    if (daftar.isEmpty) {
      final String teks = _server
          ? (_pesan ?? 'Tidak ada pilihan.')
          : (widget.opsi.isEmpty ? 'Opsi belum tersedia.' : 'Tidak ditemukan.');
      return _pesanTengah(context, teks);
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: daftar.length,
      itemBuilder: (BuildContext context, int i) {
        final OpsiPilihan o = daftar[i];
        final bool aktif = _dipilih.contains(o.value);
        final Key kunci = ValueKey<String>('${o.value}|${o.label}');

        if (widget.single) {
          return ListTile(
            key: kunci,
            dense: true,
            title: Text(o.label, style: const TextStyle(fontSize: 13)),
            trailing: aktif
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                : null,
            onTap: () => Navigator.of(context).pop(<String>[o.value]),
          );
        }

        return CheckboxListTile(
          key: kunci,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
          value: aktif,
          title: Text(o.label, style: const TextStyle(fontSize: 13)),
          onChanged: (bool? c) => _toggle(o, c),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Naikkan isi sheet saat keyboard muncul agar kolom cari tidak tertutup.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _aksiHapus(context),
                    child: const Text('Hapus pilihan'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: _onQuery,
                decoration: InputDecoration(
                  hintText: widget.hintCari,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(child: _isi(context)),
            if (!widget.single)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_hasil()),
                      child: Text(
                        _dipilih.isEmpty
                            ? 'Tampilkan semua data'
                            : 'Pilih (${_dipilih.length})',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Kolom pemicu
// ======================================================================

/// Kolom filter: label kecil di atas, kotak ringkasan pilihan ("Semua",
/// "A, B", "N dipilih") yang membuka [showMultiSelectSheet] saat diketuk.
class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<OpsiPilihan> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  String get _ringkasan {
    if (selected.isEmpty) return 'Semua';
    final Map<String, String> peta = <String, String>{
      for (final OpsiPilihan o in options) o.value: o.label,
    };
    if (selected.length <= 2) {
      return selected.map((String v) => peta[v] ?? v).join(', ');
    }
    return '${selected.length} dipilih';
  }

  Future<void> _buka(BuildContext context) async {
    final List<String>? hasil = await showMultiSelectSheet(
      context,
      title: label,
      opsi: options,
      selected: selected,
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

/// Label kecil huruf kapital di atas kolom filter, dengan petunjuk opsional
/// di kanan (mis. "Jawa Timur", "Siap Dipilih").
class FilterLabel extends StatelessWidget {
  const FilterLabel(this.text, {super.key, this.hint, this.hintColor});

  final String text;
  final String? hint;
  final Color? hintColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: hintColor ?? AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Satu bagian filter: [FilterLabel] + isi + jarak bawah standar.
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.hintColor,
  });

  final String label;
  final String? hint;
  final Color? hintColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilterLabel(label, hint: hint, hintColor: hintColor),
          child,
        ],
      ),
    );
  }
}

/// Kerangka bottom sheet filter: handle, header (ikon, judul, badge Aktif,
/// subjudul, tombol X), isi yang bisa di-scroll, dan footer tetap
/// (Reset + Terapkan). Pakai dengan showModalBottomSheet yang
/// isScrollControlled: true dan backgroundColor: Colors.transparent.
class FilterSheetFrame extends StatelessWidget {
  const FilterSheetFrame({
    super.key,
    required this.title,
    required this.children,
    required this.onReset,
    required this.onApply,
    this.subtitle,
    this.icon,
    this.activeCount = 0,
    this.trailing,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Badge "N Aktif" di samping judul; disembunyikan saat 0.
  final int activeCount;

  /// Widget kecil opsional di samping badge (mis. chip "98 Riwayat").
  final Widget? trailing;

  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  /// Null = menutup sheet tanpa hasil.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double maxTinggi = (mq.size.height - mq.viewInsets.bottom) * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxTinggi),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.border(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                _header(context),
                Divider(height: 1, color: AppTheme.border(context)),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount Aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ?trailing,
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton.filledTonal(
              tooltip: 'Tutup',
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Terapkan'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown filter berlabel. [options] berupa pasangan (nilai, label).
/// [semuaLabel] diisi = ada pilihan "semua" bernilai null.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.semuaLabel,
    this.enabled = true,
    this.loading = false,
    this.helper,
    this.icon,
    this.hint,
  });

  final IconData? icon;

  /// Petunjuk di kanan label (mis. "Siap Dipilih").
  final String? hint;
  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;
  final String? semuaLabel;
  final bool enabled;
  final bool loading;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    // Nilai hanya dipakai kalau ada di daftar (hindari assertion Flutter
    // saat daftar belum selesai dimuat).
    final T? nilai = options.any(((T, String) o) => o.$1 == value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilterLabel(label, hint: hint),
          DropdownButtonFormField<T?>(
            // Key ikut berubah: initialValue hanya dibaca sekali.
            key: ValueKey<String>('$label-$nilai-${options.length}-$enabled'),
            initialValue: nilai,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border(context)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 19, color: AppTheme.primaryColor),
              helperText: helper,
              helperMaxLines: 2,
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            hint: Text(semuaLabel ?? 'Pilih'),
            items: <DropdownMenuItem<T?>>[
              if (semuaLabel != null)
                DropdownMenuItem<T?>(value: null, child: Text(semuaLabel!)),
              for (final (T, String) o in options)
                DropdownMenuItem<T?>(
                  value: o.$1,
                  child: Text(o.$2, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

/// Satu pilihan pada [FilterChoiceGroup]. [color] diisi = gaya berwarna
/// (titik warna + tint saat dipilih); null = gaya netral (biru + centang).
class FilterChoice {
  const FilterChoice({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;
}

/// Pilihan berbentuk chip. [multi] false = satu pilihan, true = banyak.
/// [columns] diisi = grid lebar sama (mis. 3 untuk Semua/PMDN/PMA);
/// null = wrap mengikuti lebar teks.
class FilterChoiceGroup extends StatelessWidget {
  const FilterChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multi = false,
    this.semuaLabel = 'Semua',
    this.columns,
  });

  final List<FilterChoice> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool multi;

  /// Null = tanpa chip "Semua".
  final String? semuaLabel;
  final int? columns;

  void _tekan(String value) {
    if (selected.contains(value)) {
      onChanged(selected.where((String e) => e != value).toList());
    } else if (multi) {
      onChanged(<String>[...selected, value]);
    } else {
      onChanged(<String>[value]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      if (semuaLabel != null)
        _ChoiceChip(
          label: semuaLabel!,
          aktif: selected.isEmpty,
          onTap: () => onChanged(<String>[]),
        ),
      for (final FilterChoice o in options)
        _ChoiceChip(
          label: o.label,
          color: o.color,
          aktif: selected.contains(o.value),
          onTap: () => _tekan(o.value),
        ),
    ];

    const double jarak = 8;

    if (columns == null) {
      return Wrap(spacing: jarak, runSpacing: jarak, children: chips);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double lebar = (c.maxWidth - jarak * (columns! - 1)) / columns!;
        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: <Widget>[
            for (final Widget w in chips) SizedBox(width: lebar, child: w),
          ],
        );
      },
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.aktif,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color? w = color;
    final Color latar;
    final Color garis;
    final Color teks;

    if (w == null) {
      latar = aktif ? AppTheme.primaryColor : AppTheme.surface(context);
      garis = aktif ? AppTheme.primaryColor : AppTheme.border(context);
      teks = aktif ? Colors.white : AppTheme.textColor(context);
    } else {
      latar = aktif ? w.withValues(alpha: 0.12) : AppTheme.surface(context);
      garis = aktif ? w : AppTheme.border(context);
      teks = aktif ? w : AppTheme.textColor(context);
    }

    return Material(
      color: latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: garis, width: aktif ? 1.4 : 1),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (w == null && aktif) ...<Widget>[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 5),
              ] else if (w != null) ...<Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: w, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: teks,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolom tanggal: label kecil di atas, nilai di dalam kotak berikon.
class FilterDateField extends StatelessWidget {
  const FilterDateField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.text,
  });

  final String label;
  final String placeholder;

  /// Tanggal yang sudah diformat; null = tampilkan [placeholder].
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool kosong = text == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: kosong ? FontWeight.w400 : FontWeight.w600,
                      color: kosong
                          ? AppTheme.textSecondary(context)
                          : AppTheme.textColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Pemuat opsi async: spinner / gagal + "Coba lagi" / isi
// ======================================================================

/// Memuat data async untuk isi sheet. Dibuat di initState milik sheet dan
/// di-dispose di dispose-nya. Memuat langsung saat dibuat.
class PemuatOpsi<T> extends ChangeNotifier {
  PemuatOpsi(this._ambil) {
    muat();
  }

  final Future<T> Function() _ambil;
  bool _disposed = false;

  T? data;
  bool gagal = false;

  Future<void> muat() async {
    gagal = false;
    notifyListeners();
    try {
      final T hasil = await _ambil();
      if (_disposed) return;
      data = hasil;
    } catch (_) {
      if (_disposed) return;
      gagal = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Menampilkan keadaan [pemuat]: gagal = teks + "Coba lagi", belum ada data =
/// spinner kecil, sukses = isi dari [bangun].
class IsiPilihan<T> extends StatelessWidget {
  const IsiPilihan({super.key, required this.pemuat, required this.bangun});

  final PemuatOpsi<T> pemuat;
  final Widget Function(T data) bangun;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: pemuat,
      builder: (BuildContext context, Widget? _) {
        if (pemuat.gagal) {
          return Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Pilihan gagal dimuat.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: pemuat.muat,
                child: const Text('Coba lagi'),
              ),
            ],
          );
        }

        final T? data = pemuat.data;
        if (data == null) {
          return const SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return bangun(data);
      },
    );
  }
}
