import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

Color _skeletonBase(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6EAF0);
}

Color _skeletonHighlight(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF6F8FB);
}

// ======================================================================
// Mekanisme dasar
// ======================================================================

/// Membungkus sekumpulan [SkeletonBox] dengan kilau (shimmer) yang bergerak
/// dari kiri ke kanan. Kalau pengguna mematikan animasi, kilau diam.
///
/// [baseColor] dan [highlightColor] opsional, untuk latar yang bukan
/// permukaan biasa (mis. header gradien di profil).
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.baseColor ?? _skeletonBase(context);
    final Color highlight =
        widget.highlightColor ?? _skeletonHighlight(context);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(_controller.value * 3 - 1),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}

/// Kotak placeholder. Gunakan di dalam [SkeletonShimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
    this.color,
  });

  final double width;
  final double height;
  final double radius;

  /// Warna dasar kotak. Kosong = warna skeleton standar.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? _skeletonBase(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Kotak dengan lebar sebagian dari lebar induk (rata kiri).
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    required this.widthFactor,
    required this.height,
    this.radius = 6,
  });

  final double widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: SkeletonBox(height: height, radius: radius),
    );
  }
}

// ======================================================================
// Komposit
// ======================================================================

/// Kartu skeleton. Latar kartu sengaja di LUAR [SkeletonShimmer]: shimmer
/// memakai BlendMode.srcATop sehingga akan ikut mewarnai latar kalau ada
/// di dalamnya. Aturan itu dikunci di sini supaya tidak bisa terlewat.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: SkeletonShimmer(child: child),
    );
  }
}

/// Daftar skeleton non-scroll dengan label aksesibilitas.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.semanticsLabel,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.only(top: 4, bottom: 24),
  });

  final String semanticsLabel;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

// ======================================================================
// Layout per halaman
// Setiap skeleton meniru kartu aslinya. Kalau kartunya berubah, ubah juga
// skeleton-nya di sini.
// ======================================================================

/// Meniru OssProyekCard (features/oss/widgets/oss_proyek_card.dart).
class OssProyekSkeleton extends StatelessWidget {
  const OssProyekSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonList(
      semanticsLabel: 'Memuat daftar usaha',
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const _OssProyekCardSkeleton(),
    );
  }
}

class _OssProyekCardSkeleton extends StatelessWidget {
  const _OssProyekCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Nama usaha + chip status
          Row(
            children: <Widget>[
              Expanded(child: SkeletonBox(height: 16, radius: 6)),
              SizedBox(width: 12),
              SkeletonBox(width: 96, height: 24, radius: 20),
            ],
          ),
          SizedBox(height: 10),
          // Blok NIB / NKU
          SkeletonBox(height: 58, radius: 10),
          SizedBox(height: 12),
          // Baris info (modal, lokasi, alamat)
          SkeletonBox(width: 180, height: 12, radius: 6),
          SizedBox(height: 8),
          SkeletonBox(width: 240, height: 12, radius: 6),
          SizedBox(height: 8),
          SkeletonBox(height: 12, radius: 6),
          SizedBox(height: 14),
          // Tombol aksi
          SkeletonBox(height: 40, radius: 20),
        ],
      ),
    );
  }
}

/// Meniru ProfilePage (features/profile/profile_page.dart): header gradien,
/// kartu "Informasi Akun" (4 baris) dan "Informasi Tugas" (3 baris).
///
/// Header sengaja di luar shimmer: kilau memakai BlendMode.srcATop, dan
/// hanya mengganti warna (alpha tetap milik bone). Bone putih transparan
/// di atas gradien tidak akan terlihat bergerak, jadi dibiarkan diam.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat profil',
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 52),
                decoration: const BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: const Column(
                  children: <Widget>[
                    SkeletonBox(
                      width: 82,
                      height: 82,
                      radius: 41,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 16),
                    SkeletonBox(
                      width: 160,
                      height: 18,
                      radius: 6,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 8),
                    SkeletonBox(
                      width: 110,
                      height: 12,
                      radius: 6,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 14),
                    SkeletonBox(
                      width: 200,
                      height: 22,
                      radius: 6,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      _ProfileInfoCardSkeleton(rows: 4),
                      SizedBox(height: 14),
                      _ProfileInfoCardSkeleton(rows: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCardSkeleton extends StatelessWidget {
  const _ProfileInfoCardSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonBox(width: 110, height: 14, radius: 6),
          const SizedBox(height: 16),
          for (int i = 0; i < rows; i++) ...<Widget>[
            const Row(
              children: <Widget>[
                SkeletonBox(width: 19, height: 19, radius: 6),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SkeletonBox(width: 70, height: 10, radius: 6),
                      SizedBox(height: 6),
                      SkeletonBox(width: 150, height: 13, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
            if (i != rows - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

/// Meniru DashboardPage (features/dashboard/dashboard_page.dart): header
/// KPI, filter, judul seksi, tiga kartu ringkas, panel, dan grafik.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat dashboard',
      child: ExcludeSemantics(
        child: SkeletonShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              SkeletonBox(height: 250, radius: 22),
              SizedBox(height: 16),
              SkeletonBox(height: 56, radius: 16),
              SizedBox(height: 22),
              SkeletonBox(width: 170, height: 20, radius: 6),
              SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 128, radius: 18)),
                ],
              ),
              SizedBox(height: 24),
              SkeletonBox(height: 190, radius: 20),
              SizedBox(height: 24),
              SkeletonBox(height: 340, radius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Meniru BaselineOtaCard (features/ota/widgets/baseline_ota_card.dart).
class BaselineOtaSkeleton extends StatelessWidget {
  const BaselineOtaSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonList(
      semanticsLabel: 'Memuat daftar listing OTA',
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const _BaselineOtaCardSkeleton(),
    );
  }
}

class _BaselineOtaCardSkeleton extends StatelessWidget {
  const _BaselineOtaCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      radius: 16,
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Nama listing + badge status
          Row(
            children: <Widget>[
              Expanded(child: SkeletonBar(widthFactor: 0.65, height: 16)),
              SizedBox(width: 12),
              SkeletonBox(width: 80, height: 24, radius: 20),
            ],
          ),
          SizedBox(height: 12),
          // Chip platform + info
          Row(
            children: <Widget>[
              SkeletonBox(width: 70, height: 20, radius: 20),
              SizedBox(width: 8),
              SkeletonBox(width: 100, height: 12, radius: 6),
            ],
          ),
          SizedBox(height: 14),
          // Alamat + wilayah
          SkeletonBox(height: 12, radius: 6),
          SizedBox(height: 8),
          SkeletonBar(widthFactor: 0.5, height: 12),
          SizedBox(height: 16),
          // Tombol tautan
          Row(
            children: <Widget>[
              SkeletonBox(width: 40, height: 40, radius: 10),
              SizedBox(width: 8),
              SkeletonBox(width: 40, height: 40, radius: 10),
            ],
          ),
          SizedBox(height: 14),
          // Tombol verifikasi
          Row(
            children: <Widget>[
              Expanded(flex: 5, child: SkeletonBox(height: 44, radius: 11)),
              SizedBox(width: 6),
              Expanded(flex: 4, child: SkeletonBox(height: 44, radius: 11)),
              SizedBox(width: 6),
              Expanded(flex: 4, child: SkeletonBox(height: 44, radius: 11)),
            ],
          ),
        ],
      ),
    );
  }
}