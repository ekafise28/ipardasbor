import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/ocr/ocr_result_sheet.dart';

import 'ocr_field_type.dart';
import 'ocr_result.dart';
import 'ocr_service.dart';

/// Halaman uji SEMENTARA untuk Batch 2. Hapus setelah UI asli (Batch 3-4)
/// terpasang.
class OcrDebugPage extends StatefulWidget {
  const OcrDebugPage({super.key});

  @override
  State<OcrDebugPage> createState() => _OcrDebugPageState();
}

class _OcrDebugPageState extends State<OcrDebugPage> {
  final OcrService _service = OcrService();

  bool _loading = false;
  String? _error;
  OcrScanResult? _scan;
  String? _sheetOutput;

  Future<void> _openSheet(
    Map<OcrFieldType, List<OcrResult>> results, {
    Map<OcrFieldType, String> current = const {},
  }) async {
    final OcrSheetResult? r = await showOcrResultSheet(
      context,
      results: results,
      currentValues: current,
    );
    if (!mounted) return;
    setState(() {
      if (r == null) {
        _sheetOutput = 'Sheet ditutup tanpa memilih.';
      } else if (r.retry) {
        _sheetOutput = 'Pengguna minta scan ulang.';
      } else {
        _sheetOutput = 'Nilai dipakai: '
            '${r.values.map((k, v) => MapEntry(k.displayName, v))}';
      }
    });
  }

  static const Map<OcrFieldType, List<OcrResult>> _fakeResults = {
    OcrFieldType.nib: [
      OcrResult(
        type: OcrFieldType.nib,
        value: '1305220047596',
        foundByLabel: true,
      ),
    ],
    OcrFieldType.nku: [
      OcrResult(
        type: OcrFieldType.nku,
        value: '20240930112551990420',
        foundByLabel: true,
        warnings: [OcrWarning.unusualLength],
      ),
    ],
    OcrFieldType.kbli: [
      OcrResult(type: OcrFieldType.kbli, value: '55101', foundByLabel: true),
      OcrResult(
        type: OcrFieldType.kbli,
        value: '55102',
        foundByLabel: false,
        warnings: [OcrWarning.noLabel],
      ),
      OcrResult(
        type: OcrFieldType.kbli,
        value: '56101',
        foundByLabel: true,
        warnings: [OcrWarning.notInAllowedList],
      ),
    ],
  };

  static const Map<OcrFieldType, List<OcrResult>> _emptyResults = {
    OcrFieldType.nib: [],
    OcrFieldType.nku: [],
    OcrFieldType.kbli: [],
  };

  Future<void> _run(OcrImageSource source) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Stopwatch sw = Stopwatch()..start();
    try {
      final OcrScanResult? r = await _service.scan(source);
      if (!mounted) return;
      setState(() {
        if (r != null) _scan = r;
        _loading = false;
      });
      if (r != null) {
        debugPrint('OCR selesai dalam ${sw.elapsedMilliseconds} ms');
      }
    } on OcrException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final OcrScanResult? scan = _scan;

    return Scaffold(
      appBar: AppBar(title: const Text('Uji OCR (sementara)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _run(OcrImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _run(OcrImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _openSheet(
                  _fakeResults,
                  current: const {OcrFieldType.nku: '202409301125519904207'},
                ),
                child: const Text('Sheet: data palsu'),
              ),
              OutlinedButton(
                onPressed: () => _openSheet(_emptyResults),
                child: const Text('Sheet: kosong'),
              ),
              OutlinedButton(
                onPressed: scan == null ? null : () => _openSheet(scan.results),
                child: const Text('Sheet: hasil scan'),
              ),
            ],
          ),
          if (_sheetOutput != null) ...[
            const SizedBox(height: 8),
            Text('Keluaran sheet: $_sheetOutput'),
          ],
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (scan != null) ...[
            const Text('Teks mentah', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            SelectableText(
              scan.lines.isEmpty
                  ? '(tidak ada teks terbaca)'
                  : scan.lines
                      .asMap()
                      .entries
                      .map((e) => '${e.key + 1}. ${e.value}')
                      .join('\n'),
            ),
            const SizedBox(height: 16),
            const Text('Hasil parser', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final OcrFieldType t in OcrFieldType.values)
              _typeBlock(t, scan.results[t] ?? const []),
          ],
        ],
      ),
    );
  }

  Widget _typeBlock(OcrFieldType type, List<OcrResult> list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (list.isEmpty)
            const Text('tidak ditemukan')
          else
            for (final OcrResult r in list)
              SelectableText(
                '${r.value}  (${r.digitCount} digit, '
                '${r.foundByLabel ? "berlabel" : "tanpa label"})'
                '${r.hasWarning ? "\n  ! ${r.warningMessages.join(" ")}" : ""}',
              ),
        ],
      ),
    );
  }
}