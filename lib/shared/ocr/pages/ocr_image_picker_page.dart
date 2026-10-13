import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_recognition.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_result.dart';
import 'package:ipardasbor/shared/ocr/parsing/ocr_line_cleaner.dart';

/// Keluaran layar pilih manual: jenis field yang dipilih dan kandidat
/// hasil pembersihan baris yang di-tap.
class OcrManualPick {
  const OcrManualPick({required this.type, required this.results});

  final OcrFieldType type;
  final List<OcrResult> results;
}

/// Buka layar pilih manual. Null kalau pengguna kembali tanpa memilih.
///
/// [targets] null/kosong berarti semua jenis. Kalau hanya ada satu jenis,
/// pilihan jenis disembunyikan.
Future<OcrManualPick?> showOcrImagePicker(
  BuildContext context, {
  required OcrRecognition recognition,
  Set<OcrFieldType>? targets,
  OcrFieldType? initialType,
  String bidang = 'akomodasi',
}) {
  return Navigator.of(context).push<OcrManualPick>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OcrImagePickerPage(
        recognition: recognition,
        targets: targets,
        initialType: initialType,
        bidang: bidang,
      ),
    ),
  );
}

/// Gambar diam dengan kotak di atas tiap baris teks. Pengguna memilih satu
/// baris per field; tap baris lain menggantinya.
class OcrImagePickerPage extends StatefulWidget {
  const OcrImagePickerPage({
    super.key,
    required this.recognition,
    this.targets,
    this.initialType,
    this.bidang = 'akomodasi',
  });

  final OcrRecognition recognition;
  final Set<OcrFieldType>? targets;
  final OcrFieldType? initialType;
  final String bidang;

  @override
  State<OcrImagePickerPage> createState() => _OcrImagePickerPageState();
}

class _OcrImagePickerPageState extends State<OcrImagePickerPage> {
  static const Color _green = Color(0xFF16A34A);
  static const Color _amber = Color(0xFFB45309);

  late final List<OcrFieldType> _types;
  late OcrFieldType _type;
  late List<bool> _recognized;
  int? _selected;
  List<OcrResult> _cands = const [];

  List<OcrTextLine> get _lines => widget.recognition.lines;

  @override
  void initState() {
    super.initState();
    final Set<OcrFieldType>? t = widget.targets;
    _types = OcrFieldType.values
        .where((e) => t == null || t.isEmpty || t.contains(e))
        .toList();
    _type = (widget.initialType != null && _types.contains(widget.initialType))
        ? widget.initialType!
        : _types.first;
    _recognized = _computeRecognized();
  }

  List<bool> _computeRecognized() => [
    for (final l in _lines)
      OcrLineCleaner.isRecognized(l.text, _type, bidang: widget.bidang),
  ];

  void _changeType(OcrFieldType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _recognized = _computeRecognized();
      if (_selected != null) {
        _cands = OcrLineCleaner.clean(
          _lines[_selected!].text,
          _type,
          bidang: widget.bidang,
        );
        if (_cands.isEmpty) _selected = null;
      }
    });
  }

  void _pick(int index) {
    final List<OcrResult> cands = OcrLineCleaner.clean(
      _lines[index].text,
      _type,
      bidang: widget.bidang,
    );
    if (cands.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tidak ada angka di baris ini.')),
        );
      return;
    }
    setState(() {
      _selected = index;
      _cands = cands;
    });
  }

  void _confirm() {
    if (_selected == null || _cands.isEmpty) return;
    Navigator.of(context).pop(OcrManualPick(type: _type, results: _cands));
  }

  /// Salin teks mentah (tanpa dibersihkan), supaya baris berisi label atau
  /// kalimat biasa juga bisa disalin untuk dipakai di aplikasi lain.
  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Teks tersalin.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih dari gambar'),
        actions: [
          IconButton(
            tooltip: 'Salin semua teks',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _lines.isEmpty
                ? null
                : () => _copy(_lines.map((l) => l.text).join('\n')),
          ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          Expanded(child: _imageArea()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_types.length > 1)
            Wrap(
              spacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t.displayName),
                    selected: _type == t,
                    onSelected: (_) => _changeType(t),
                  ),
              ],
            ),
          if (_types.length > 1) const SizedBox(height: 6),
          Text(
            'Ketuk baris yang berisi ${_type.displayName}. '
            'Kotak hijau adalah tebakan otomatis. '
            'Tekan lama untuk menyalin teks baris.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageArea() {
    final Size imageSize = widget.recognition.imageSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = (constraints.maxWidth / imageSize.width)
            .clamp(0.0, constraints.maxHeight / imageSize.height);
        final double w = imageSize.width * scale;
        final double h = imageSize.height * scale;

        return ClipRect(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: Center(
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(widget.recognition.imagePath),
                        fit: BoxFit.fill,
                      ),
                    ),
                    for (int i = 0; i < _lines.length; i++)
                      _box(i, scale, Size(w, h)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _box(int i, double scale, Size bounds) {
    final Rect r = _lines[i].box;
    final Rect rect = Rect.fromLTRB(
      r.left * scale,
      r.top * scale,
      r.right * scale,
      r.bottom * scale,
    ).inflate(2).intersect(Offset.zero & bounds);

    final bool selected = _selected == i;
    final bool guess = _recognized[i];
    final Color color = selected
        ? AppTheme.primaryColor
        : guess
        ? _green
        : Colors.grey;

    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pick(i),
        onLongPress: () => _copy(_lines[i].text),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: selected
                  ? 0.30
                  : guess
                  ? 0.22
                  : 0.08,
            ),
            border: Border.all(
              color: color.withValues(alpha: selected || guess ? 1 : 0.5),
              width: selected ? 2.5 : 1.2,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final OcrResult? first = _cands.isEmpty ? null : _cands.first;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: first == null
                    ? Text(
                        'Belum ada baris dipilih.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cands.length > 1
                                ? '${_cands.length} angka ditemukan di baris ini'
                                : first.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cands.length > 1
                                ? 'Pilih salah satu di langkah berikutnya.'
                                : first.hasWarning
                                ? first.warningMessages.first
                                : '${first.digitCount} digit',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: first.hasWarning && _cands.length == 1
                                  ? _amber
                                  : AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_selected != null)
                IconButton(
                  tooltip: 'Salin teks baris',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copy(_lines[_selected!].text),
                ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: first == null ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Gunakan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}