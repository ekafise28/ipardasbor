import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/constants/kbli_constants.dart';

import 'ocr_field_type.dart';
import 'ocr_result.dart';

/// Keluaran bottom sheet.
/// - [values]: nilai yang dicentang pengguna (kosong kalau [retry]).
/// - [retry]: pengguna minta memilih/scan gambar lagi.
class OcrSheetResult {
  const OcrSheetResult({this.values = const {}, this.retry = false});

  final Map<OcrFieldType, String> values;
  final bool retry;
}

/// Tampilkan hasil OCR untuk dikonfirmasi. Mengembalikan null kalau ditutup
/// tanpa memilih.
///
/// [results] memuat kunci untuk setiap jenis yang dicari (daftar kosong =
/// tidak ditemukan). [currentValues] adalah isi field di form saat ini,
/// supaya nilai yang sudah ada tidak ditimpa diam-diam.
Future<OcrSheetResult?> showOcrResultSheet(
  BuildContext context, {
  required Map<OcrFieldType, List<OcrResult>> results,
  Map<OcrFieldType, String> currentValues = const {},
  bool allowRetry = true,
  String bidang = 'akomodasi',
}) {
  return showModalBottomSheet<OcrSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _OcrResultSheet(
      results: results,
      currentValues: currentValues,
      allowRetry: allowRetry,
      bidang: bidang,
    ),
  );
}

class _OcrResultSheet extends StatefulWidget {
  const _OcrResultSheet({
    required this.results,
    required this.currentValues,
    required this.allowRetry,
    required this.bidang,
  });

  final Map<OcrFieldType, List<OcrResult>> results;
  final Map<OcrFieldType, String> currentValues;
  final bool allowRetry;
  final String bidang;

  @override
  State<_OcrResultSheet> createState() => _OcrResultSheetState();
}

class _OcrResultSheetState extends State<_OcrResultSheet> {
  late final List<OcrFieldType> _types;
  final Map<OcrFieldType, TextEditingController> _ctrls = {};
  final Map<OcrFieldType, int> _picked = {};
  final Map<OcrFieldType, bool> _checked = {};

  @override
  void initState() {
    super.initState();
    _types = OcrFieldType.values.where(widget.results.containsKey).toList();

    for (final t in _types) {
      final List<OcrResult> cands = widget.results[t] ?? const [];
      if (cands.isEmpty) continue;

      final TextEditingController c = TextEditingController(
        text: cands.first.value,
      );
      c.addListener(() {
        if (mounted) setState(() {});
      });
      _ctrls[t] = c;
      _picked[t] = 0;
      // Tercentang otomatis hanya kalau: kandidat tunggal, tanpa peringatan,
      // dan field di form masih kosong.
      _checked[t] =
          cands.length == 1 && cands.first.isClean && _current(t).isEmpty;
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _current(OcrFieldType t) => (widget.currentValues[t] ?? '').trim();

  bool _isApplicable(OcrFieldType t) =>
      _checked[t] == true && (_ctrls[t]?.text.isNotEmpty ?? false);

  void _apply() {
    final Map<OcrFieldType, String> values = {
      for (final t in _types)
        if (_isApplicable(t)) t: _ctrls[t]!.text.trim(),
    };
    Navigator.of(context).pop(OcrSheetResult(values: values));
  }

  void _retry() => Navigator.of(context).pop(const OcrSheetResult(retry: true));

  /// Peringatan dihitung ulang dari teks yang sedang tampil, jadi ikut
  /// berubah saat pengguna mengedit.
  List<OcrWarning> _liveWarnings(
    OcrFieldType t,
    String text, {
    required bool noLabel,
  }) {
    final List<OcrWarning> w = [];
    if (text.isNotEmpty && text.length != t.expectedLength) {
      w.add(OcrWarning.unusualLength);
    }
    if (t == OcrFieldType.kbli &&
        text.length == 5 &&
        !KbliConstants.isDiizinkan(text, bidang: widget.bidang)) {
      w.add(OcrWarning.notInAllowedList);
    }
    if (noLabel) w.add(OcrWarning.noLabel);
    return w;
  }

  static String _group(String s) {
    if (s.length <= 6) return s;
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAny = _ctrls.isNotEmpty;
    final int count = _types.where(_isApplicable).length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasil scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cocokkan angka dengan sumbernya sebelum dipakai.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: hasAny
                    ? [for (final t in _types) _fieldCard(t)]
                    : [_emptyState()],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: hasAny
                ? Row(
                    children: [
                      if (widget.allowRetry) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retry,
                            child: const Text('Scan ulang'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: count > 0 ? _apply : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: Text(count > 0 ? 'Pakai ($count)' : 'Pakai'),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      icon: const Icon(Icons.image_search_outlined),
                      label: const Text('Pilih gambar lagi'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Tidak ada angka yang terbaca.',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba gambar yang lebih jelas, atau potong ke area angka saja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFoundCard(OcrFieldType t) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            size: 20,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.displayName}: tidak ditemukan di gambar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Isi form tidak diubah, isi manual kalau perlu.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard(OcrFieldType t) {
    final List<OcrResult> cands = widget.results[t] ?? const [];
    if (cands.isEmpty) return _notFoundCard(t);

    final TextEditingController ctrl = _ctrls[t]!;
    final String text = ctrl.text;
    final OcrResult picked = cands[_picked[t]!];
    final bool untouched = text == picked.value;
    final OcrResult live = OcrResult(
      type: t,
      value: text,
      foundByLabel: untouched ? picked.foundByLabel : true,
      warnings: _liveWarnings(
        t,
        text,
        noLabel: untouched && !picked.foundByLabel,
      ),
    );
    final String current = _current(t);
    final bool lengthOff = text.isNotEmpty && text.length != t.expectedLength;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: live.hasWarning
              ? const Color(0xFFF59E0B)
              : AppTheme.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _checked[t],
                onChanged: (v) => setState(() => _checked[t] = v ?? false),
              ),
              Text(
                t.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
              const Spacer(),
              Text(
                '${text.length} digit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: lengthOff
                      ? const Color(0xFFB45309)
                      : AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      current == text
                          ? 'Sama dengan isi form saat ini.'
                          : 'Isi form saat ini: ${_group(current)}. '
                                'Centang untuk menimpa.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                if (cands.length > 1) ...[
                  Text(
                    'Ditemukan ${cands.length} kandidat, pilih satu:',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < cands.length; i++)
                        ChoiceChip(
                          label: Text(cands[i].value),
                          avatar: cands[i].hasWarning
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFB45309),
                                )
                              : null,
                          selected: _picked[t] == i,
                          onSelected: (_) => setState(() {
                            _picked[t] = i;
                            ctrl.text = cands[i].value;
                            _checked[t] = true;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  text.isEmpty ? '-' : _group(text),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _checked[t] = true),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Ubah jika perlu',
                    border: OutlineInputBorder(),
                  ),
                ),
                for (final String msg in live.warningMessages)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
