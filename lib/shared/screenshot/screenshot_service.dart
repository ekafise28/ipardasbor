import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ipardasbor/app/app_navigator.dart';

class ScreenshotService {
  ScreenshotService._();

  static final GlobalKey rootKey = GlobalKey();

  static final List<GlobalKey> _pageKeys = [];
  static void register(GlobalKey k) => _pageKeys.add(k);
  static void unregister(GlobalKey k) => _pageKeys.remove(k);

  static bool capturing = false;

  /// Batas sisi terpanjang gambar (px). Naikkan ke 5000 kalau HP kuat,
  /// turunkan ke 3000 kalau masih macet.
  static const double _maxPx = 4096;
  static const double _maxRatio = 2.0; // sama seperti versi yang dulu berhasil

  static Future<void> capture() async {
    if (capturing) return;
    capturing = true;
    try {
      final ctx = AppNavigator.navigatorKey.currentContext;
      if (ctx != null) FocusScope.of(ctx).unfocus();
      await WidgetsBinding.instance.endOfFrame;

      final GlobalKey key = _pageKeys.isNotEmpty ? _pageKeys.last : rootKey;
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderRepaintBoundary) {
        throw Exception('Halaman tidak bisa di-capture.');
      }

      final double ratio = (_maxPx / box.size.height).clamp(0.5, _maxRatio);

      final ui.Image image = await box.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw Exception('Gagal membuat gambar.');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ss_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      final ctx = AppNavigator.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      capturing = false;
    }
  }
}

class FullPageCapture extends StatefulWidget {
  const FullPageCapture({super.key, required this.child});
  final Widget child;

  @override
  State<FullPageCapture> createState() => _FullPageCaptureState();
}

class _FullPageCaptureState extends State<FullPageCapture> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    ScreenshotService.register(_key);
  }

  @override
  void dispose() {
    ScreenshotService.unregister(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: _key,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: widget.child,
        ),
      );
}