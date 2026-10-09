import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/utils/skeleton.dart';

/// Placeholder daftar usaha saat pertama kali memuat atau saat filter
/// berubah. Bentuknya meniru [OssProyekCard] supaya tidak ada lompatan tata
/// letak ketika data tiba.
class OssProyekSkeleton extends StatelessWidget {
  const OssProyekSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat daftar usaha',
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) =>
            const _SkeletonKartu(),
      ),
    );
  }
}

class _SkeletonKartu extends StatelessWidget {
  const _SkeletonKartu();

  @override
  Widget build(BuildContext context) {
    // Latar kartu sengaja di LUAR SkeletonShimmer: shimmer memakai
    // BlendMode.srcATop sehingga akan ikut mewarnai latar kalau ada di dalam.
    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: SkeletonShimmer(
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
        ),
      ),
    );
  }
}