import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../../core/storage/secure_storage.dart';

/// Splash "Verifikasi Usaha Pariwisata" - versi bersih.
///
/// Alur animasi (satu timeline 3.6 detik):
///  1. Radar memindai area, titik-titik cahaya melayang di latar.
///  2. Pin lokasi jatuh & memantul ke lencana.
///  3. Cincin verifikasi berputar penuh (proses "memeriksa").
///  4. Pin berubah jadi centang hijau yang tergambar sendiri + percikan + haptic.
///  5. Judul muncul huruf per huruf, status berganti: memindai -> memverifikasi -> terverifikasi.
///  6. Exit zoom + fade, lalu navigasi sesuai sesi.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 3600);
  static const String _title = 'I-PAR MOBILE';

  // Timeline utama (0..1).
  late final AnimationController _controller;
  // Loop kontinu: radar, ring pulse, titik latar.
  late final AnimationController _loop;
  // Exit zoom + fade.
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  late final List<_Dot> _dots;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();

    final rnd = math.Random(11);
    _dots = List.generate(
      26,
      (_) => _Dot(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        r: 1.2 + rnd.nextDouble() * 2.4,
        speed: 0.15 + rnd.nextDouble() * 0.35,
        phase: rnd.nextDouble() * math.pi * 2,
      ),
    );

    _controller = AnimationController(vsync: this, duration: _introDuration)
      ..addListener(_onTick);

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkSession();
  }

  void _onTick() {
    // Getaran halus tepat saat centang mulai tergambar.
    if (!_hapticFired && _controller.value >= 0.58) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _checkSession() async {
    final Future<bool> sessionFuture = SecureStorage.hasAccessToken();
    // Tunggu sampai animasi "terverifikasi" selesai + jeda singkat.
    final Future<void> delayFuture = Future<void>.delayed(
      _introDuration + const Duration(milliseconds: 350),
    );

    final List<dynamic> results = await Future.wait([
      sessionFuture,
      delayFuture,
    ]);

    if (!mounted) return;
    final bool hasToken = results.first as bool;

    unawaited(_exitController.forward());
    await Future.delayed(const Duration(milliseconds: 260));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, hasToken ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _loop.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // Helper: nilai 0..1 dari segmen [a, b] pada timeline t.
  static double _iv(double t, double a, double b, [Curve c = Curves.linear]) {
    return c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  String _statusText(double t) {
    if (t < 0.35) return 'Memindai lokasi usaha...';
    if (t < 0.58) return 'Memverifikasi legalitas & izin...';
    return 'Usaha terverifikasi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              Color(0xFF00A6A6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Titik cahaya melayang di latar.
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) => CustomPaint(
                    painter: _DotsPainter(_dots, _loop.value),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _exitFade,
                child: ScaleTransition(
                  scale: _exitScale,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_controller, _loop]),
                      builder: (context, _) => _buildContent(_controller.value),
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

  Widget _buildContent(double t) {
    // --- Nilai animasi turunan ---
    final badgeScale = _iv(t, 0.0, 0.15, Curves.easeOutBack) *
        (1 + 0.12 * math.sin(math.pi * _iv(t, 0.58, 0.74)));
    final dropProgress = _iv(t, 0.10, 0.40, Curves.bounceOut);
    final pinDropY = -190.0 * (1 - dropProgress);
    final pinOpacity = _iv(t, 0.10, 0.18);
    final pinScale = 1 - _iv(t, 0.52, 0.62, Curves.easeIn);
    final ringProgress = _iv(t, 0.38, 0.60, Curves.easeInOut);
    final ringOpacity = 1 - _iv(t, 0.66, 0.80);
    final checkProgress = _iv(t, 0.56, 0.74, Curves.easeOutCubic);
    final glow = _iv(t, 0.60, 0.78);
    final sparkle = _iv(t, 0.62, 1.0, Curves.easeOut);
    final radarFade = _iv(t, 0.0, 0.1) * (1 - _iv(t, 0.64, 0.86));
    final subtitleFade = _iv(t, 0.78, 0.95, Curves.easeOut);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ================= HERO =================
        RepaintBoundary(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar + ring pulse
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarPainter(
                      loop: _loop.value,
                      opacity: radarFade,
                    ),
                  ),
                ),
                // Lencana putih
                Transform.scale(
                  scale: badgeScale,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(0xFF3DDC84)
                              .withValues(alpha: 0.55 * glow),
                          blurRadius: 40 * glow,
                          spreadRadius: 6 * glow,
                        ),
                      ],
                    ),
                  ),
                ),
                // Cincin proses verifikasi
                Opacity(
                  opacity: ringOpacity,
                  child: CustomPaint(
                    size: const Size(146, 146),
                    painter: _RingPainter(ringProgress),
                  ),
                ),
                // Pin jatuh
                Opacity(
                  opacity: pinOpacity,
                  child: Transform.translate(
                    offset: Offset(0, pinDropY),
                    child: Transform.scale(
                      scale: pinScale,
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 68,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                // Centang tergambar
                CustomPaint(
                  size: const Size(112, 112),
                  painter: _CheckPainter(checkProgress),
                ),
                // Percikan
                Positioned.fill(
                  child: CustomPaint(painter: _SparklePainter(sparkle)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ================= JUDUL huruf per huruf =================
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_title.length, (i) {
            final start = 0.60 + i * 0.016;
            final v = _iv(t, start, start + 0.12, Curves.easeOutCubic);
            return Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, (1 - v) * 14),
                child: Text(
                  _title[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: subtitleFade,
          child: Transform.translate(
            offset: Offset(0, (1 - subtitleFade) * 10),
            child: const Text(
              'Sistem Pengawasan Pariwisata',
              style: TextStyle(color: Color(0xFFE3F2FD), fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // ================= STATUS + PROGRESS =================
        SizedBox(
          height: 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(_statusText(t)),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (t >= 0.58)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 17,
                      color: Color(0xFF7CFFB2),
                    ),
                  ),
                Text(
                  _statusText(t),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 150,
            height: 4,
            child: LinearProgressIndicator(
              value: t,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(Colors.white, const Color(0xFF7CFFB2), glow)!,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Painters
// ======================================================================

class _Dot {
  final double x, y, r, speed, phase;
  const _Dot({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.dots, this.loop);
  final List<_Dot> dots;
  final double loop;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final d in dots) {
      final y = (d.y - loop * d.speed) % 1.0;
      final x = d.x + math.sin(loop * math.pi * 2 + d.phase) * 0.012;
      final twinkle = 0.5 + 0.5 * math.sin(loop * math.pi * 2 + d.phase);
      paint.color = Colors.white.withValues(alpha: 0.06 + 0.16 * twinkle);
      canvas.drawCircle(Offset(x * size.width, y * size.height), d.r, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.loop != loop;
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.loop, required this.opacity});
  final double loop;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = size.center(Offset.zero);

    // Ring pulse yang memancar keluar.
    for (int i = 0; i < 3; i++) {
      final phase = (loop + i / 3) % 1.0;
      final radius = 62 + phase * 88;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: (1 - phase) * 0.35 * opacity);
      canvas.drawCircle(c, radius, paint);
    }

    // Garis panduan radar (tipis).
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.12 * opacity);
    canvas.drawCircle(c, 100, guide);
    canvas.drawCircle(c, 140, guide);

    // Sapuan radar berputar.
    final rect = Rect.fromCircle(center: c, radius: 140);
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.38 * opacity),
        ],
        stops: const [0.0, 0.72, 1.0],
        transform: GradientRotation(loop * math.pi * 2),
      ).createShader(rect);
    canvas.drawCircle(c, 140, sweep);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.loop != loop || old.opacity != opacity;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE08A);
    canvas.drawArc(
      rect.deflate(2),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.53)
      ..lineTo(size.width * 0.44, size.height * 0.69)
      ..lineTo(size.width * 0.74, size.height * 0.35);

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF16B364);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    if (p <= 0 || p >= 1) return;
    final c = size.center(Offset.zero);
    const count = 18;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + 0.2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final reach = i.isEven ? 1.0 : 0.7;
      final dist = 64 + 80 * p * reach;
      final alpha = (1 - p).clamp(0.0, 1.0);
      final color = i % 3 == 0
          ? const Color(0xFFFFE08A)
          : (i % 3 == 1 ? Colors.white : const Color(0xFF7CFFB2));
      paint.color = color.withValues(alpha: alpha);

      if (i.isEven) {
        // Garis percikan
        paint.strokeWidth = 3;
        canvas.drawLine(
          c + dir * dist,
          c + dir * (dist + 12 * (1 - p)),
          paint,
        );
      } else {
        // Titik percikan
        canvas.drawCircle(c + dir * dist, 1.5 + 3 * (1 - p), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.p != p;
}