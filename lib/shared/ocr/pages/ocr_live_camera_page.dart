import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_result.dart';
import 'package:ipardasbor/shared/ocr/parsing/ocr_parser.dart';
import 'package:ipardasbor/shared/ocr/parsing/ocr_stability_tracker.dart';
import 'package:ipardasbor/shared/ocr/services/ocr_frame_converter.dart';
import 'package:ipardasbor/shared/ocr/services/ocr_visual_rows.dart';
import 'package:permission_handler/permission_handler.dart';

/// Buka kamera langsung dengan bingkai pemandu dan deteksi otomatis.
/// Mengembalikan path foto yang diambil, atau null kalau pengguna menutup
/// layar tanpa mengambil foto.
///
/// [targets] dan [bidang] sama artinya dengan di `runOcrScan`.
Future<String?> showOcrLiveCamera(
  BuildContext context, {
  Set<OcrFieldType>? targets,
  String bidang = 'akomodasi',
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OcrLiveCameraPage(targets: targets, bidang: bidang),
    ),
  );
}

/// Preview kamera + bingkai pemandu + deteksi live + tombol ambil foto.
///
/// Frame stream dibaca ML Kit beberapa kali per detik, hanya teks yang
/// berada di dalam bingkai yang dipakai, lalu hasilnya dilewatkan parser
/// yang sama dengan scan foto. Nilai yang bertahan di beberapa frame
/// berturut-turut ditampilkan sebagai "terbaca". Itu hanya umpan balik:
/// hasil akhir tetap dari foto penuh yang diambil pengguna, lalu diproses
/// alur OCR biasa. Tombol ambil foto selalu berfungsi, dengan atau tanpa
/// deteksi.
class OcrLiveCameraPage extends StatefulWidget {
  const OcrLiveCameraPage({
    super.key,
    this.targets,
    this.bidang = 'akomodasi',
  });

  final Set<OcrFieldType>? targets;
  final String bidang;

  @override
  State<OcrLiveCameraPage> createState() => _OcrLiveCameraPageState();
}

class _OcrLiveCameraPageState extends State<OcrLiveCameraPage>
    with WidgetsBindingObserver {
  /// Resolusi preview, foto, dan stream. Stream ikut resolusi ini, jadi
  /// ultraHigh (4K) membuat setiap frame sangat besar. veryHigh (sekitar
  /// 1080p) adalah kompromi antara ketajaman foto dan beban deteksi.
  static const ResolutionPreset _preset = ResolutionPreset.veryHigh;

  /// Jeda minimal antar frame yang diproses (sekitar 3 FPS).
  static const Duration _interval = Duration(milliseconds: 350);

  /// Berapa frame tak terpakai berturut-turut sebelum deteksi dianggap
  /// tidak didukung di perangkat ini.
  static const int _maxUnusableFrames = 5;

  /// Hanya baca teks di dalam bingkai. Kalau di suatu perangkat deteksi
  /// tidak pernah menemukan apa pun padahal teks jelas, ubah ke false untuk
  /// memastikan pemetaan koordinat bingkai penyebabnya.
  static const bool _filterToFrame = true;

  /// Jeda dari nilai stabil sampai foto otomatis diambil.
  static const Duration _autoDelay = Duration(milliseconds: 700);

  static const Color _green = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFF59E0B);

  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final OcrStabilityTracker _tracker = OcrStabilityTracker();

  CameraController? _controller;
  bool _initializing = false;
  bool _capturing = false;
  bool _disposed = false;
  String? _error;
  bool _permissionIssue = false;

  bool _detectEnabled = true;
  bool _detectUnavailable = false;
  bool _processing = false;
  int _unusableFrames = 0;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  bool _torch = false;
  bool _autoCapture = false;
  Timer? _autoTimer;

  /// Bingkai dalam koordinat ternormalisasi (0..1) terhadap area preview.
  /// Diperbarui saat build, dibaca saat memproses frame.
  Rect? _holeNorm;

  Map<OcrFieldType, List<OcrResult>> _stable = const {};
  String _stableSignature = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    _disposed = true;
    _autoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    unawaited(_recognizer.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null) {
        _controller = null;
        _torch = false;
        _clearDetection();
        if (mounted) setState(() {});
        unawaited(c.dispose());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && _error == null) unawaited(_init());
    }
  }

  Future<void> _init() async {
    if (_initializing) return;
    _initializing = true;
    if (mounted) {
      setState(() {
        _error = null;
        _permissionIssue = false;
      });
    }

    try {
      final List<CameraDescription> cams = await availableCameras();
      if (cams.isEmpty) {
        _fail('Perangkat ini tidak memiliki kamera.');
        return;
      }
      final CameraDescription cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final CameraController c = CameraController(
        cam,
        _preset,
        enableAudio: false,
        imageFormatGroup: OcrFrameConverter.streamFormat,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _torch = false;
      });
      if (_detectEnabled && !_detectUnavailable) unawaited(_startStream(c));
    } on CameraException catch (e) {
      debugPrint('OCR kamera gagal dibuka: ${e.code} ${e.description}');
      final bool permission = e.code.startsWith('CameraAccess');
      _fail(
        permission
            ? 'Izin kamera belum diberikan.'
            : 'Kamera tidak dapat dibuka.',
        permission: permission,
      );
    } catch (e) {
      debugPrint('OCR kamera gagal dibuka: $e');
      _fail('Kamera tidak dapat dibuka.');
    } finally {
      _initializing = false;
    }
  }

  void _fail(String message, {bool permission = false}) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _permissionIssue = permission;
    });
  }

  // ---------------------------------------------------------------------
  // Deteksi live

  Future<void> _startStream(CameraController c) async {
    if (c.value.isStreamingImages) return;
    try {
      await c.startImageStream(_onFrame);
    } on CameraException catch (e) {
      debugPrint('OCR stream gagal dimulai: ${e.code} ${e.description}');
      _markDetectionUnavailable();
    }
  }

  Future<void> _stopStream(CameraController c) async {
    if (!c.value.isStreamingImages) return;
    try {
      await c.stopImageStream();
    } on CameraException catch (e) {
      debugPrint('OCR stream gagal dihentikan: ${e.code} ${e.description}');
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_disposed || !_detectEnabled || _processing || _capturing) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastRun) < _interval) return;
    final CameraController? c = _controller;
    if (c == null) return;

    _processing = true;
    _lastRun = now;
    try {
      final InputImage? input = OcrFrameConverter.convert(
        image,
        c.description,
        c.value.deviceOrientation,
      );
      if (input == null) {
        if (++_unusableFrames >= _maxUnusableFrames) {
          _markDetectionUnavailable();
        }
        return;
      }
      _unusableFrames = 0;

      final RecognizedText text = await _recognizer.processImage(input);
      if (_disposed || !mounted || !_detectEnabled) return;

      final List<String> rows = ocrVisualRowsFromLines(
        _linesInFrame(text, input),
      );
      final Map<OcrFieldType, List<OcrResult>> parsed = OcrParser.parse(
        rows,
        targets: widget.targets,
        bidang: widget.bidang,
      );
      _publish(_tracker.update(parsed));
    } catch (e) {
      debugPrint('OCR frame gagal diproses: $e');
    } finally {
      _processing = false;
    }
  }

  /// Baris teks yang pusatnya berada di dalam bingkai pemandu.
  ///
  /// Koordinat ML Kit mengikuti gambar yang sudah ditegakkan (rotasi
  /// diterapkan), sama dengan yang tampil di preview, jadi bingkai cukup
  /// dikalikan dengan ukuran gambar tegak itu.
  List<TextLine> _linesInFrame(RecognizedText text, InputImage input) {
    final List<TextLine> all = [
      for (final block in text.blocks) ...block.lines,
    ];
    final Rect? hole = _holeNorm;
    final InputImageMetadata? meta = input.metadata;
    if (!_filterToFrame || hole == null || meta == null) return all;

    final bool swap =
        meta.rotation == InputImageRotation.rotation90deg ||
        meta.rotation == InputImageRotation.rotation270deg;
    final double w = swap ? meta.size.height : meta.size.width;
    final double h = swap ? meta.size.width : meta.size.height;

    // Sedikit longgar supaya teks yang menempel di tepi bingkai tidak
    // terpotong oleh goyangan tangan.
    final Rect area = Rect.fromLTRB(
      hole.left * w,
      hole.top * h,
      hole.right * w,
      hole.bottom * h,
    ).inflate(h * 0.02);

    return all.where((l) => area.contains(l.boundingBox.center)).toList();
  }

  void _publish(Map<OcrFieldType, List<OcrResult>> stable) {
    final String signature = [
      for (final e in stable.entries)
        for (final r in e.value) '${e.key.name}:${r.value}',
    ].join('|');
    if (signature == _stableSignature || !mounted) return;
    setState(() {
      _stable = stable;
      _stableSignature = signature;
    });
    if (stable.isNotEmpty) HapticFeedback.lightImpact();
    _scheduleAutoCapture();
  }

  void _clearDetection() {
    _autoTimer?.cancel();
    _tracker.reset();
    _stable = const {};
    _stableSignature = '';
  }

  /// Deteksi tidak bisa jalan di perangkat ini. Kamera dan tombol foto
  /// tetap normal; hanya umpan balik live yang dimatikan.
  void _markDetectionUnavailable() {
    if (_disposed) return;
    final CameraController? c = _controller;
    if (c != null) unawaited(_stopStream(c));
    if (!mounted) return;
    setState(() {
      _detectUnavailable = true;
      _detectEnabled = false;
      _autoCapture = false;
      _clearDetection();
    });
  }

  Future<void> _toggleDetect() async {
    final CameraController? c = _controller;
    if (c == null) return;
    final bool next = !_detectEnabled;
    setState(() {
      _detectEnabled = next;
      if (!next) _clearDetection();
    });
    if (next) {
      await _startStream(c);
    } else {
      await _stopStream(c);
    }
  }

  // ---------------------------------------------------------------------
  // Senter dan foto otomatis

  Future<void> _toggleTorch() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final bool next = !_torch;
    try {
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torch = next);
    } on CameraException catch (e) {
      debugPrint('OCR senter gagal: ${e.code} ${e.description}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Senter tidak tersedia.')));
    }
  }

  void _toggleAutoCapture() {
    setState(() => _autoCapture = !_autoCapture);
    if (_autoCapture) {
      _scheduleAutoCapture();
    } else {
      _autoTimer?.cancel();
    }
  }

  /// Ambil foto otomatis setelah nilai stabil bertahan sebentar. Hanya
  /// jalan kalau pengguna menyalakannya.
  void _scheduleAutoCapture() {
    _autoTimer?.cancel();
    if (!_autoCapture || _stable.isEmpty || _capturing) return;
    _autoTimer = Timer(_autoDelay, () {
      if (!mounted || !_autoCapture || _stable.isEmpty) return;
      unawaited(_capture());
    });
  }

  // ---------------------------------------------------------------------

  Future<void> _capture() async {
    final CameraController? c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        _capturing ||
        c.value.isTakingPicture) {
      return;
    }
    _autoTimer?.cancel();
    setState(() => _capturing = true);
    try {
      final XFile file = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } on CameraException catch (e) {
      debugPrint('OCR gagal mengambil foto: ${e.code} ${e.description}');
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Gagal mengambil foto.')));
    }
  }

  // ---------------------------------------------------------------------
  // Tampilan

  /// Posisi bingkai dan area preview untuk ukuran layar tertentu. Dipakai
  /// untuk menggambar sekaligus untuk menyaring teks, supaya keduanya
  /// selalu sama.
  ({RRect hole, Rect preview}) _layout(Size size, double previewAspect) {
    final double pw;
    final double ph;
    if (size.width / size.height > previewAspect) {
      ph = size.height;
      pw = ph * previewAspect;
    } else {
      pw = size.width;
      ph = pw / previewAspect;
    }
    final Rect preview = Rect.fromLTWH(
      (size.width - pw) / 2,
      (size.height - ph) / 2,
      pw,
      ph,
    );

    final double w = size.width * 0.9;
    final double h = (size.height * 0.2).clamp(110.0, 200.0);
    final RRect hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: w,
        height: h,
      ),
      const Radius.circular(12),
    );
    return (hole: hole, preview: preview);
  }

  Rect _normalize(Rect r, Rect preview) => Rect.fromLTRB(
    ((r.left - preview.left) / preview.width).clamp(0.0, 1.0),
    ((r.top - preview.top) / preview.height).clamp(0.0, 1.0),
    ((r.right - preview.left) / preview.width).clamp(0.0, 1.0),
    ((r.bottom - preview.top) / preview.height).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null ? _errorView() : _cameraView(),
    );
  }

  Widget _cameraView() {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final bool portrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final double ar = c.value.aspectRatio;
    final double previewAspect = portrait ? 1 / ar : ar;
    final bool hasStable = _stable.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: previewAspect,
            child: CameraPreview(c),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = _layout(constraints.biggest, previewAspect);
            // Disimpan tanpa setState: hanya dibaca saat memproses frame.
            _holeNorm = _normalize(layout.hole.outerRect, layout.preview);
            return IgnorePointer(
              child: CustomPaint(
                painter: _FramePainter(
                  layout.hole,
                  color: hasStable ? _green : Colors.white,
                ),
              ),
            );
          },
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Tutup',
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleTorch,
                        icon: Icon(
                          _torch ? Icons.flash_on : Icons.flash_off,
                          color: _torch ? _amber : Colors.white70,
                        ),
                        tooltip: _torch ? 'Matikan senter' : 'Nyalakan senter',
                      ),
                      if (!_detectUnavailable) ...[
                        IconButton(
                          onPressed: _detectEnabled ? _toggleAutoCapture : null,
                          icon: Icon(
                            _autoCapture
                                ? Icons.motion_photos_auto
                                : Icons.motion_photos_auto_outlined,
                            color: _autoCapture ? _green : Colors.white70,
                          ),
                          tooltip: _autoCapture
                              ? 'Foto otomatis: aktif'
                              : 'Foto otomatis: mati',
                        ),
                        IconButton(
                          onPressed: _toggleDetect,
                          icon: Icon(
                            _detectEnabled
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            color: _detectEnabled ? _green : Colors.white70,
                          ),
                          tooltip: _detectEnabled
                              ? 'Deteksi otomatis: aktif'
                              : 'Deteksi otomatis: mati',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detectedChips(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _hint(hasStable),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _shutter(ready: hasStable),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _hint(bool hasStable) {
    final bool auto = _autoCapture && _detectEnabled;
    if (hasStable) {
      return auto
          ? 'Terbaca. Memotret otomatis...'
          : 'Terbaca. Ambil foto untuk memastikan hasilnya.';
    }
    return auto
        ? 'Arahkan angka ke dalam bingkai, foto diambil otomatis.'
        : 'Arahkan angka ke dalam bingkai, lalu ambil foto.';
  }

  /// Nilai yang sudah stabil, paling banyak 2 per jenis dan 4 seluruhnya.
  Widget _detectedChips() {
    final List<Widget> chips = [];
    for (final MapEntry<OcrFieldType, List<OcrResult>> e in _stable.entries) {
      for (final OcrResult r in e.value.take(2)) {
        if (chips.length >= 4) break;
        chips.add(_chip(e.key, r));
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }

  Widget _chip(OcrFieldType type, OcrResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.hasWarning ? _amber : _green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.displayName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            r.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            r.hasWarning ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 16,
            color: r.hasWarning ? _amber : _green,
          ),
        ],
      ),
    );
  }

  Widget _shutter({required bool ready}) {
    return Semantics(
      button: true,
      label: 'Ambil foto',
      child: GestureDetector(
        onTap: _capture,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ready ? _green : Colors.white, width: 4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _capturing ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 44,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),
              if (_permissionIssue)
                FilledButton(
                  onPressed: openAppSettings,
                  child: const Text('Buka pengaturan'),
                )
              else
                FilledButton(
                  onPressed: _init,
                  child: const Text('Coba lagi'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menggelapkan seluruh layar kecuali lubang bingkai, lalu menggambar
/// garis tepinya.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.hole, {required this.color});

  final RRect hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(scrim, Paint()..color = Colors.black54);
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.hole != hole || old.color != color;
}