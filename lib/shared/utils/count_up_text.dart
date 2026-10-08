import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';

/// Menampilkan angka yang menghitung naik dari 0 (saat pertama muncul) atau
/// dari nilai sebelumnya ke nilai baru (saat [value] berubah, mis. setelah
/// filter diterapkan). Dilewati jika pengguna mematikan animasi di perangkat.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final Duration effective = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : duration;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: effective,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) {
        return Text(
          formatNumber(current.round()),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}