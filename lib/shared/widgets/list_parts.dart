import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../utils/formatters.dart';

/// Baris keterangan di atas daftar: "Provinsi · N data · M belum
/// diverifikasi". Bagian opsional hanya tampil kalau diisi.
class ListSummaryLine extends StatelessWidget {
  const ListSummaryLine({
    super.key,
    this.provinsi,
    required this.total,
    required this.satuan,
    this.belum,
    this.akhiran,
    this.catatan,
  });

  /// Null = baris hanya menampilkan jumlah (mis. halaman yang tidak
  /// dibatasi provinsi).
  final String? provinsi;
  final int total;

  /// Kata benda setelah angka total, mis. "usaha" atau "data".
  final String satuan;

  /// Jumlah yang belum diverifikasi, disorot oranye. Null = disembunyikan
  /// (mis. saat daftar sudah disaring per status).
  final int? belum;

  /// Teks tambahan di ujung baris, mis. "terdekat dulu".
  final String? akhiran;

  /// Catatan di baris kedua berwarna kuning tua, mis. info lokasi tersimpan.
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text.rich(
              TextSpan(
                text: provinsi == null
                    ? '${formatNumber(total)} $satuan'
                    : '$provinsi · ${formatNumber(total)} $satuan',
                children: <InlineSpan>[
                  if (belum != null)
                    TextSpan(
                      text: ' · ${formatNumber(belum!)} belum diverifikasi',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (akhiran != null) TextSpan(text: ' · $akhiran'),
                ],
              ),
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
            if (catatan != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  catatan!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD08A00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DistanceBadge extends StatelessWidget {
  const DistanceBadge({super.key, required this.km});
  final double km;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.near_me_rounded, size: 12, color: warna),
          const SizedBox(width: 4),
          Text(
            formatJarak(km),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: warna),
          ),
        ],
      ),
    );
  }
}

/// Judul AppBar dua baris: judul tebal dan keterangan kecil di bawahnya.
class TwoLineTitle extends StatelessWidget {
  const TwoLineTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

/// Baris info berikon pada kartu daftar.
class ListInfoRow extends StatelessWidget {
  const ListInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 1,
    this.redup = false,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  /// true = baris sekunder, warna lebih muted.
  final bool redup;

  @override
  Widget build(BuildContext context) {
    final Color warna =
        redup ? AppTheme.textMuted : AppTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: warna),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.3, color: warna),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip pil berlatar tint (jenis, status, platform, dsb).
class TintChip extends StatelessWidget {
  const TintChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kerangka kartu daftar: strip warna 4px di kiri, lalu isi dengan padding
/// standar. Dipakai kartu Riwayat dan OSS supaya sudut, border, margin, dan
/// strip statusnya hanya ada di satu tempat.
///
/// [onTap] null = kartu tidak bisa ditekan. [background] mengganti warna
/// latar kartu (mis. untuk menyorot kartu yang baru selesai diverifikasi).
class StripCard extends StatelessWidget {
  const StripCard({
    super.key,
    required this.stripColor,
    required this.child,
    this.onTap,
    this.background,
  });

  final Color stripColor;
  final Widget child;
  final VoidCallback? onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: background ?? AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: stripColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris judul kartu daftar: nama (maks. 2 baris) dan chip status di kanan.
class CardTitleRow extends StatelessWidget {
  const CardTitleRow({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    this.statusIcon,
  });

  final String title;
  final String statusLabel;
  final Color statusColor;
  final IconData? statusIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: AppTheme.textColor(context),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Status: $statusLabel',
          excludeSemantics: true,
          child: TintChip(
            label: statusLabel,
            color: statusColor,
            icon: statusIcon,
          ),
        ),
      ],
    );
  }
}

/// Kotak berlatar muted dengan sudut membulat, untuk mengelompokkan
/// beberapa baris info di dalam kartu (identitas, NIB/NKU, dsb).
class MutedPanel extends StatelessWidget {
  const MutedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 8, 10, 8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}