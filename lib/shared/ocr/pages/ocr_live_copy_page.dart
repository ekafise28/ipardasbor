import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ipardasbor/shared/ocr/services/ocr_frame_converter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Buka kamera untuk menyalin teks langsung dari kamera (tanpa mengisi
/// field). Selesai saat pengguna menutup layar.
Future<void> showOcrLiveCopy(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const OcrLiveCopyPage(),
    ),
  );
}

enum _Phase { live, freezing, frozen }

class _LiveLine {
  const _LiveLine(this.text, this.box);

  final String text;

  /// Dalam piksel gambar tegak dari frame yang dibaca.
  final Rect box;
}

/// Kamera langsung untuk menyalin teks, mirip Google Lens.
///
/// - Saat live, kotak tipis menandai teks yang terbaca.
/// - Ketuk layar untuk membekukan. Pembekuan memakai frame berikutnya yang
///   dibaca setelah preview dijeda, supaya kotak sepadan dengan gambar yang
///   diam.
/// - Setelah beku, ketuk satu atau beberapa kotak (ketuk lagi untuk
///   mencabut): panel naik dari bawah menampilkan teks barisnya, digabung
///   per baris sesuai urutan baca. Teks di panel bisa diedit, lalu "Salin"
///   atau "Bagikan".
///   "Lanjutkan" membuka preview lagi.
///
/// Tidak ada parser dan tidak ada pembatasan: teks apa pun bisa disalin.
class OcrLiveCopyPage extends StatefulWidget {
  const OcrLiveCopyPage({super.key});

  @override
  State<OcrLiveCopyPage> createState() => _OcrLiveCopyPageState();
}

class _OcrLiveCopyPageState extends State<OcrLiveCopyPage>
    with WidgetsBindingObserver {
  /// Resolusi preview dan stream. Tidak ada foto di layar ini, jadi yang
  /// menentukan hanya ketajaman teks kecil dan beban pemrosesan frame.
  static const ResolutionPreset _preset = ResolutionPreset.veryHigh;

  /// Jeda minimal antar frame yang diproses saat live (sekitar 3 FPS).
  static const Duration _interval = Duration(milliseconds: 350);

  /// Kalau tidak ada frame baru setelah preview dijeda, pakai hasil live
  /// terakhir supaya layar tidak menggantung.
  static const Duration _freezeTimeout = Duration(milliseconds: 1500);

  static const int _maxUnusableFrames = 5;

  /// Batas zoom. Zoom digital yang terlalu besar membuat teks pecah, dan
  /// OCR justru memburuk.
  static const double _zoomCap = 5;

  static const Color _accent = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFF59E0B);

  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  CameraController? _controller;
  bool _initializing = false;
  bool _disposed = false;
  String? _error;
  bool _permissionIssue = false;

  bool _processing = false;
  int _unusableFrames = 0;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  _Phase _phase = _Phase.live;
  bool _acceptNextFrame = false;
  Timer? _freezeTimer;

  List<_LiveLine> _lines = const [];
  Size? _frameSize;

  /// Indeks baris yang dipilih (setelah beku). Tidak kosong berarti panel
  /// pratinjau terbuka. Urutan indeks sama dengan urutan baca.
  final Set<int> _selected = <int>{};
  final TextEditingController _panelCtrl = TextEditingController();
  bool _justCopied = false;
  Timer? _copiedTimer;

  bool _torch = false;

  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double _zoomAtStart = 1;
  bool _zooming = false;
  Timer? _zoomLabelTimer;

  /// Titik ketuk terakhir untuk fokus, ditampilkan sebentar sebagai cincin.
  Offset? _focusRing;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    _disposed = true;
    _freezeTimer?.cancel();
    _zoomLabelTimer?.cancel();
    _focusTimer?.cancel();
    _copiedTimer?.cancel();
    _panelCtrl.dispose();
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
        _resetState();
        if (mounted) setState(() {});
        unawaited(c.dispose());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && _error == null) unawaited(_init());
    }
  }

  void _resetState() {
    _freezeTimer?.cancel();
    _acceptNextFrame = false;
    _phase = _Phase.live;
    _lines = const [];
    _frameSize = null;
    _selected.clear();
    _justCopied = false;
    _torch = false;
    _focusRing = null;
    _zooming = false;
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
      double minZ = 1;
      double maxZ = 1;
      try {
        minZ = await c.getMinZoomLevel();
        maxZ = await c.getMaxZoomLevel();
      } on CameraException catch (e) {
        debugPrint('OCR zoom tidak tersedia: ${e.code} ${e.description}');
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _minZoom = minZ;
        _maxZoom = maxZ < _zoomCap ? maxZ : _zoomCap;
        _zoom = minZ;
        _torch = false;
      });
      unawaited(_startStream(c));
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
  // Stream dan pembacaan frame

  Future<void> _startStream(CameraController c) async {
    if (c.value.isStreamingImages) return;
    try {
      await c.startImageStream(_onFrame);
    } on CameraException catch (e) {
      debugPrint('OCR stream gagal dimulai: ${e.code} ${e.description}');
      _fail('Pembacaan langsung tidak bisa dimulai. Gunakan Galeri.');
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
    if (_disposed || _processing) return;

    bool finalFrame = false;
    if (_phase == _Phase.frozen) return;
    if (_phase == _Phase.freezing) {
      // Frame pertama setelah preview dijeda menjadi frame beku.
      if (!_acceptNextFrame) return;
      _acceptNextFrame = false;
      finalFrame = true;
    } else {
      final DateTime now = DateTime.now();
      if (now.difference(_lastRun) < _interval) return;
      _lastRun = now;
    }

    final CameraController? c = _controller;
    if (c == null) return;

    _processing = true;
    try {
      final InputImage? input = OcrFrameConverter.convert(
        image,
        c.description,
        c.value.deviceOrientation,
      );
      final Size? size = input == null ? null : _uprightSize(input);
      if (input == null || size == null) {
        if (++_unusableFrames >= _maxUnusableFrames) {
          _fail(
            'Pembacaan langsung tidak didukung di perangkat ini. '
            'Gunakan Galeri.',
          );
        }
        return;
      }
      _unusableFrames = 0;

      final RecognizedText text = await _recognizer.processImage(input);
      if (_disposed || !mounted) return;
      final List<_LiveLine> lines = _toLines(text);

      if (finalFrame) {
        if (_phase != _Phase.freezing) return; // sudah diselesaikan timer
        setState(() {
          _lines = lines;
          _frameSize = size;
        });
        _finishFreeze();
      } else if (_phase == _Phase.live) {
        setState(() {
          _lines = lines;
          _frameSize = size;
        });
      }
    } catch (e) {
      debugPrint('OCR frame gagal diproses: $e');
    } finally {
      _processing = false;
    }
  }

  /// Ukuran gambar setelah rotasi diterapkan, sama dengan ruang koordinat
  /// kotak dari ML Kit dan dengan apa yang tampil di preview.
  Size? _uprightSize(InputImage input) {
    final InputImageMetadata? m = input.metadata;
    if (m == null) return null;
    final bool swap =
        m.rotation == InputImageRotation.rotation90deg ||
        m.rotation == InputImageRotation.rotation270deg;
    return swap ? Size(m.size.height, m.size.width) : m.size;
  }

  List<_LiveLine> _toLines(RecognizedText text) {
    final List<_LiveLine> out = [
      for (final block in text.blocks)
        for (final line in block.lines)
          if (line.text.trim().isNotEmpty)
            _LiveLine(line.text.trim(), line.boundingBox),
    ];
    out.sort((a, b) {
      final int c = a.box.top.compareTo(b.box.top);
      return c != 0 ? c : a.box.left.compareTo(b.box.left);
    });
    return out;
  }

  // ---------------------------------------------------------------------
  // Bekukan, lanjutkan, salin

  Future<void> _freeze() async {
    final CameraController? c = _controller;
    if (c == null || _phase != _Phase.live) return;
    setState(() {
      _phase = _Phase.freezing;
      _selected.clear();
    });

    try {
      await c.pausePreview();
    } on CameraException catch (e) {
      debugPrint('OCR preview gagal dijeda: ${e.code} ${e.description}');
      if (!mounted) return;
      setState(() => _phase = _Phase.live);
      _snack('Tidak dapat membekukan layar.');
      return;
    }
    if (!mounted || _phase != _Phase.freezing) return;

    _acceptNextFrame = true;
    _freezeTimer?.cancel();
    _freezeTimer = Timer(_freezeTimeout, _finishFreeze);
  }

  void _finishFreeze() {
    _freezeTimer?.cancel();
    _acceptNextFrame = false;
    if (!mounted || _phase != _Phase.freezing) return;
    setState(() => _phase = _Phase.frozen);
    final CameraController? c = _controller;
    if (c != null) unawaited(_stopStream(c));
  }

  Future<void> _resume() async {
    final CameraController? c = _controller;
    if (c == null || _phase != _Phase.frozen) return;
    try {
      await c.resumePreview();
    } on CameraException catch (e) {
      debugPrint('OCR preview gagal dilanjutkan: ${e.code} ${e.description}');
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.live;
      _lines = const [];
      _frameSize = null;
      _selected.clear();
      _justCopied = false;
    });
    await _startStream(c);
  }

  /// Ketuk baris untuk menambah atau mencabut dari pilihan. Isi panel
  /// disusun ulang dari semua baris terpilih (suntingan sebelumnya hilang).
  void _toggleLine(int index) {
    HapticFeedback.selectionClick();
    _copiedTimer?.cancel();
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
      _justCopied = false;
      _panelCtrl.text = _selectedText();
    });
  }

  String _selectedText() {
    final List<int> idx = _selected.toList()..sort();
    return idx.map((i) => _lines[i].text).join('\n');
  }

  void _clearSelection() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selected.isEmpty) return;
    setState(() {
      _selected.clear();
      _panelCtrl.clear();
    });
  }

  /// Salin isi panel (bukan teks asli baris), supaya hasil suntingan
  /// pengguna yang tersalin.
  Future<void> _copyPanel() async {
    final String text = _panelCtrl.text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _justCopied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  /// Buka lembar bagikan sistem dengan isi panel (teks setelah diedit).
  Future<void> _sharePanel() async {
    final String text = _panelCtrl.text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      debugPrint('OCR bagikan gagal: $e');
      if (mounted) _snack('Tidak dapat membuka menu bagikan.');
    }
  }

  Future<void> _copyAll() async {
    if (_lines.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: _lines.map((l) => l.text).join('\n')),
    );
    HapticFeedback.selectionClick();
    if (!mounted) return;
    _snack('Semua teks tersalin.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // Senter, zoom, fokus

  Future<void> _toggleTorch() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final bool next = !_torch;
    try {
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torch = next);
    } on CameraException catch (e) {
      debugPrint('OCR senter gagal: ${e.code} ${e.description}');
      _snack('Senter tidak tersedia.');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtStart = _zoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final CameraController? c = _controller;
    // Satu jari bukan zoom; itu ketukan atau geseran biasa.
    if (c == null || _phase != _Phase.live || details.pointerCount < 2) return;

    final double z = (_zoomAtStart * details.scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    if ((z - _zoom).abs() < 0.02) return;

    setState(() {
      _zoom = z;
      _zooming = true;
    });
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _zooming = false);
    });
    try {
      await c.setZoomLevel(z);
    } on CameraException catch (e) {
      debugPrint('OCR zoom gagal: ${e.code} ${e.description}');
    }
  }

  /// Ketukan saat live: di atas kotak teks berarti membekukan, di area
  /// kosong berarti fokus ke titik itu.
  void _onLiveTap(TapUpDetails details, Rect preview, List<Rect> rects) {
    if (_phase != _Phase.live) return;
    final Offset p = details.localPosition;
    final bool onText = rects.any((r) => r.inflate(6).contains(p));
    if (onText) {
      unawaited(_freeze());
    } else {
      unawaited(_focusAt(p, preview));
    }
  }

  Future<void> _focusAt(Offset p, Rect preview) async {
    final CameraController? c = _controller;
    if (c == null || !preview.contains(p)) return;

    setState(() => _focusRing = p);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusRing = null);
    });

    // Koordinat titik fokus ternormalisasi (0..1) terhadap preview.
    final Offset n = Offset(
      (p.dx - preview.left) / preview.width,
      (p.dy - preview.top) / preview.height,
    );
    // Fokus dan eksposur dicoba terpisah: sebagian perangkat hanya
    // mendukung salah satunya.
    try {
      await c.setFocusPoint(n);
    } on CameraException catch (e) {
      debugPrint('OCR fokus gagal: ${e.code} ${e.description}');
    }
    try {
      await c.setExposurePoint(n);
    } on CameraException catch (e) {
      debugPrint('OCR eksposur gagal: ${e.code} ${e.description}');
    }
  }

  Widget _focusRingWidget(Offset p) {
    return Positioned(
      left: p.dx - 28,
      top: p.dy - 28,
      child: IgnorePointer(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _zoomChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${_zoom.toStringAsFixed(1)}x',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tampilan

  /// Area preview di layar. Preview selalu menampilkan seluruh gambar
  /// tegak, jadi kotak ML Kit cukup diskalakan ke area ini.
  Rect _previewRect(Size size, double previewAspect) {
    final double pw;
    final double ph;
    if (size.width / size.height > previewAspect) {
      ph = size.height;
      pw = ph * previewAspect;
    } else {
      pw = size.width;
      ph = pw / previewAspect;
    }
    return Rect.fromLTWH((size.width - pw) / 2, (size.height - ph) / 2, pw, ph);
  }

  List<Rect> _screenRects(Rect preview) {
    final Size? fs = _frameSize;
    if (fs == null) return const [];
    final double sx = preview.width / fs.width;
    final double sy = preview.height / fs.height;
    return [
      for (final l in _lines)
        Rect.fromLTRB(
          preview.left + l.box.left * sx,
          preview.top + l.box.top * sy,
          preview.left + l.box.right * sx,
          preview.top + l.box.bottom * sy,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Keyboard saat mengedit teks di panel tidak boleh menyusutkan
      // preview, karena itu menggeser kotak. Panel menggeser dirinya sendiri.
      resizeToAvoidBottomInset: false,
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
            final Rect preview = _previewRect(
              constraints.biggest,
              previewAspect,
            );
            final List<Rect> rects = _screenRects(preview);
            if (_phase == _Phase.frozen) return _frozenLayer(rects);
            return Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BoxesPainter(rects),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onLiveTap(d, preview, rects),
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                  ),
                ),
                if (_focusRing case final Offset ring) _focusRingWidget(ring),
              ],
            );
          },
        ),
        _topBar(),
        if (_zooming)
          Align(alignment: const Alignment(0, -0.7), child: _zoomChip()),
        // Panel pratinjau menggantikan bar bawah selama ada baris terpilih.
        if (!(_phase == _Phase.frozen && _selected.isNotEmpty)) _bottomBar(),
        _selectionPanel(),
      ],
    );
  }

  Widget _frozenLayer(List<Rect> rects) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ketuk area kosong menutup panel dan keyboard.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _clearSelection,
          ),
        ),
        for (int i = 0; i < rects.length; i++)
          Positioned.fromRect(
            rect: rects[i].inflate(2),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleLine(i),
              child: Container(
                decoration: BoxDecoration(
                  color: (_selected.contains(i) ? _accent : Colors.white).withValues(
                    alpha: _selected.contains(i) ? 0.35 : 0.12,
                  ),
                  border: Border.all(
                    color: _selected.contains(i) ? _accent : Colors.white,
                    width: _selected.contains(i) ? 2.5 : 1.2,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _topBar() {
    return SafeArea(
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
              if (_phase == _Phase.frozen && _lines.isNotEmpty)
                IconButton(
                  onPressed: _copyAll,
                  icon: const Icon(Icons.copy_all_outlined, color: Colors.white),
                  tooltip: 'Salin semua teks',
                ),
              if (_phase == _Phase.live)
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _torch ? Icons.flash_on : Icons.flash_off,
                    color: _torch ? _amber : Colors.white70,
                  ),
                  tooltip: _torch ? 'Matikan senter' : 'Nyalakan senter',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final Widget content;
    switch (_phase) {
      case _Phase.live:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hint(
              'Ketuk kotak teks untuk membekukan. '
              'Ketuk area kosong untuk fokus, cubit untuk zoom.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _freeze,
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Bekukan'),
            ),
          ],
        );
      case _Phase.freezing:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _hint('Membekukan...'),
          ],
        );
      case _Phase.frozen:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hint(
              _lines.isEmpty
                  ? 'Tidak ada teks terbaca. Lanjutkan dan coba lagi.'
                  : 'Ketuk satu atau beberapa baris untuk menyalin atau membagikan teksnya.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _resume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lanjutkan'),
            ),
          ],
        );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: content,
        ),
      ),
    );
  }

  /// Panel yang naik dari bawah berisi teks baris terpilih, seperti Google
  /// Lens. Selalu ada di tree supaya bisa dianimasikan masuk dan keluar;
  /// saat tidak terlihat ia turun ke luar layar dan tidak menerima sentuhan.
  Widget _selectionPanel() {
    final bool visible = _phase == _Phase.frozen && _selected.isNotEmpty;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bool canCopy = _panelCtrl.text.trim().isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Padding(
            // Panel naik di atas keyboard, bukan seluruh layar.
            padding: EdgeInsets.only(bottom: keyboard),
            child: GestureDetector(
              // Mencegah ketukan di ruang kosong panel tembus ke layar
              // beku dan menutup panel.
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                color: cs.surface,
                elevation: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SafeArea(
                  top: false,
                  bottom: keyboard == 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _selected.length > 1
                                  ? '${_selected.length} baris terpilih'
                                  : 'Teks terpilih',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.close),
                              tooltip: 'Tutup',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _panelCtrl,
                          minLines: 1,
                          maxLines: 5,
                          onChanged: (_) => setState(() => _justCopied = false),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            helperText: 'Bisa diedit sebelum disalin.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: canCopy ? _sharePanel : null,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Bagikan'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: canCopy ? _copyPanel : null,
                                icon: Icon(
                                  _justCopied
                                      ? Icons.check
                                      : Icons.copy_outlined,
                                ),
                                label: Text(_justCopied ? 'Tersalin' : 'Salin'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13),
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

/// Kotak tipis di atas teks yang terbaca saat live. Tidak bisa disentuh;
/// ketukan pada layar membekukan, dan baru setelah itu kotak bisa dipilih.
class _BoxesPainter extends CustomPainter {
  const _BoxesPainter(this.rects);

  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.85);
    for (final Rect r in rects) {
      final RRect rr = RRect.fromRectAndRadius(
        r.inflate(2),
        const Radius.circular(3),
      );
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, stroke);
    }
  }

  @override
  bool shouldRepaint(_BoxesPainter old) => true;
}