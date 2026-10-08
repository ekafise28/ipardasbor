import 'package:flutter/material.dart';
import 'screenshot_service.dart';

class ScreenshotOverlay extends StatefulWidget {
  const ScreenshotOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });
  final Widget child;
  final bool enabled;

  @override
  State<ScreenshotOverlay> createState() => _ScreenshotOverlayState();
}

class _ScreenshotOverlayState extends State<ScreenshotOverlay> {
  static const double _s = 48; // ukuran tombol
  static const double _margin = 12; // jarak dari tepi saat menempel

  Offset? _pos;
  bool _busy = false;
  bool _dragging = false; // animasi mati saat digeser, hidup saat snap

  Future<void> _tap() async {
    setState(() => _busy = true);
    await ScreenshotService.capture();
    if (mounted) setState(() => _busy = false);
  }

  void _onPanUpdate(DragUpdateDetails d, Size size, EdgeInsets safe) {
    setState(() {
      _dragging = true;
      _pos = Offset(
        (_pos!.dx + d.delta.dx).clamp(0.0, size.width - _s),
        (_pos!.dy + d.delta.dy).clamp(safe.top, size.height - _s - safe.bottom),
      );
    });
  }

  void _onPanEnd(Size size) {
    // tempel ke sisi kiri atau kanan, mana yang lebih dekat
    final bool keKiri = (_pos!.dx + _s / 2) < size.width / 2;
    setState(() {
      _dragging = false;
      _pos = Offset(keKiri ? _margin : size.width - _s - _margin, _pos!.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final safe = mq.padding;

    _pos ??= Offset(size.width - _s - _margin, size.height * 0.6);

    return Stack(
      children: [
        RepaintBoundary(key: ScreenshotService.rootKey, child: widget.child),
        if (widget.enabled)
          AnimatedPositioned(
            duration: _dragging
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: _pos!.dx,
            top: _pos!.dy,
            child: GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, size, safe),
              onPanEnd: (_) => _onPanEnd(size),
              onPanCancel: () => _onPanEnd(size),
              child: Material(
                color: Colors.black.withOpacity(0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _busy ? null : _tap,
                  child: SizedBox(
                    width: _s,
                    height: _s,
                    child: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.screenshot_rounded,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
