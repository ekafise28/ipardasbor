import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Kerangka kartu yang berdenyut selama data pertama dimuat. Bentuknya
/// meniru BaselineOtaCard supaya layout tidak "melompat" saat data tiba.
class BaselineOtaSkeletonList extends StatefulWidget {
  const BaselineOtaSkeletonList({super.key, this.jumlah = 4});
  final int jumlah;

  @override
  State<BaselineOtaSkeletonList> createState() => _BaselineOtaSkeletonListState();
}

class _BaselineOtaSkeletonListState extends State<BaselineOtaSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _opacity =
      Tween<double>(begin: 0.4, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: widget.jumlah,
        itemBuilder: (_, __) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Bar(height: 16, widthFactor: 0.65)),
              const SizedBox(width: 12),
              _Bar(height: 24, width: 80, radius: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Bar(height: 20, width: 70, radius: 20),
              const SizedBox(width: 8),
              _Bar(height: 12, width: 100),
            ],
          ),
          const SizedBox(height: 14),
          const _Bar(height: 12),
          const SizedBox(height: 8),
          const _Bar(height: 12, widthFactor: 0.5),
          const SizedBox(height: 16),
          Row(
            children: [
              _Bar(height: 40, width: 40, radius: 10),
              const SizedBox(width: 8),
              _Bar(height: 40, width: 40, radius: 10),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(flex: 5, child: _Bar(height: 44, radius: 11)),
              const SizedBox(width: 6),
              Expanded(flex: 4, child: _Bar(height: 44, radius: 11)),
              const SizedBox(width: 6),
              Expanded(flex: 4, child: _Bar(height: 44, radius: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    this.width,
    this.widthFactor,
    this.radius = 6,
  });

  final double height;
  final double? width;
  final double? widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget bar = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.border(context).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(widthFactor: widthFactor, child: bar),
      );
    }
    return bar;
  }
}