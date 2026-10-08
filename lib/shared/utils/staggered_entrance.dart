import 'package:flutter/material.dart';

/// Fade + geser sedikit ke atas, tertunda sesuai [index]. Semua item memakai
/// satu AnimationController yang sama supaya bergerak berurutan dari atas ke
/// bawah. Dilewati jika pengguna mematikan animasi di pengaturan perangkat.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
    this.step = 0.07,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  /// Selisih awal animasi antar item (fraksi dari total durasi controller).
  final double step;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final double start = (index * step).clamp(0.0, 0.55);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final Animation<double> eased = animation.drive(
      CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );

    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(
          Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}