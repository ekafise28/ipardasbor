import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_exception.dart';

import '../models/proyek_data_option.dart';
import '../services/proyek_data_service.dart';

/// Mengembalikan nilai yang dipilih (daftar kosong = "hapus pilihan"),
/// atau null kalau sheet ditutup tanpa memilih.
Future<List<String>?> showProyekDataOptionPicker(
  BuildContext context, {
  required String title,
  required ProyekDataOptionType tipe,
  required ProyekDataService service,
  required List<String> selected,
  bool single = false,
  String? provinsi,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _Picker(
      title: title,
      tipe: tipe,
      service: service,
      selected: selected,
      single: single,
      provinsi: provinsi,
    ),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({
    required this.title,
    required this.tipe,
    required this.service,
    required this.selected,
    required this.single,
    required this.provinsi,
  });

  final String title;
  final ProyekDataOptionType tipe;
  final ProyekDataService service;
  final List<String> selected;
  final bool single;
  final String? provinsi;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  static const String _petunjukKbli =
      'Ketik minimal 2 karakter kode atau nama KBLI.';

  late final Set<String> _dipilih = <String>{...widget.selected};
  Timer? _debounce;
  int _req = 0;

  String _q = '';
  List<ProyekDataOption> _opsi = const <ProyekDataOption>[];
  String? _pesan;
  String? _error;
  bool _loading = false;

  bool get _kbli => widget.tipe == ProyekDataOptionType.kbli;

  @override
  void initState() {
    super.initState();
    if (_kbli) {
      _pesan = _petunjukKbli; // KBLI baru dicari setelah ada ketikan.
    } else {
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
    _debounce?.cancel();

    if (_kbli && value.trim().length < 2) {
      _req++; // batalkan respons yang masih berjalan
      setState(() {
        _opsi = const <ProyekDataOption>[];
        _pesan = _petunjukKbli;
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
      final ProyekDataOptionResult r = await widget.service.fetchOptions(
        tipe: widget.tipe,
        q: _q,
        provinsi: widget.provinsi,
      );
      if (!mounted || id != _req) return;
      setState(() {
        _opsi = r.options;
        _pesan = r.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _req) return;
      setState(() {
        _opsi = const <ProyekDataOption>[];
        _error = pesanErrorRamah(e);
        _loading = false;
      });
    }
  }

  void _toggle(ProyekDataOption o, bool? centang) {
    setState(() {
      if (centang == true) {
        _dipilih.add(o.value);
      } else {
        _dipilih.remove(o.value);
      }
    });
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

    if (_opsi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _pesan ?? 'Tidak ada pilihan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _opsi.length,
      itemBuilder: (BuildContext context, int i) {
        final ProyekDataOption o = _opsi[i];
        final bool aktif = _dipilih.contains(o.value);
        final Key kunci = ValueKey<String>('${o.value}-${o.versi}');

        if (widget.single) {
          return ListTile(
            key: kunci,
            dense: true,
            title: Text(o.labelTampil, style: const TextStyle(fontSize: 13)),
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
          value: aktif,
          title: Text(o.labelTampil, style: const TextStyle(fontSize: 13)),
          onChanged: (bool? c) => _toggle(o, c),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    onPressed: widget.single
                        ? (widget.selected.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(<String>[]))
                        : (_dipilih.isEmpty
                              ? null
                              : () => setState(_dipilih.clear)),
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
                  hintText: _kbli ? 'Kode atau nama KBLI...' : 'Cari...',
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
                      onPressed: () =>
                          Navigator.of(context).pop(_dipilih.toList()),
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