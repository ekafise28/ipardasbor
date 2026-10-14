import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart';

// ======================================================================
// Dasar kartu
// ======================================================================

/// Kerangka kartu yang dipakai semua kartu di halaman detail, supaya gaya
/// (sudut, border, padding) hanya ada di satu tempat.
class DetailCard extends StatelessWidget {
  const DetailCard({
    super.key,
    required this.child,
    this.icon,
    this.title,
    this.count,
  });

  final Widget child;
  final IconData? icon;
  final String? title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: AppTheme.menuDashboard),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  if (count != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      '($count)',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

bool _terisi(String? s) => s != null && s.trim().isNotEmpty;

// ======================================================================
// SectionCard: kartu label-nilai per kategori field
// ======================================================================

/// Satu pasangan label-nilai yang dirender oleh [SectionCard].
///
/// Baris dengan nilai null/kosong otomatis disembunyikan supaya section
/// tidak penuh tanda "-" untuk field yang memang tidak diisi.
class Baris {
  const Baris(this.label, this.value, {this.url});

  final String label;
  final String? value;

  /// Kalau diisi, baris ini dirender sebagai tautan yang bisa ditekan
  /// untuk membuka [url] (bukan sekadar teks biasa).
  final String? url;

  bool get adaIsi => _terisi(value);
  bool get bisaDibuka => _terisi(url);
}

/// Kartu section untuk satu kategori field, dengan header ikon + judul.
///
/// Dipakai bersama oleh halaman detail Riwayat (data server) dan halaman
/// detail Ajuan/Sinkronisasi (data lokal offline) supaya tampilan kedua
/// halaman konsisten.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<Baris> rows;

  @override
  Widget build(BuildContext context) {
    final List<Baris> terisi = rows.where((Baris r) => r.adaIsi).toList();
    if (terisi.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: icon,
      title: title,
      child: Column(
        children: <Widget>[
          for (final Baris baris in terisi) _BarisTile(baris: baris),
        ],
      ),
    );
  }
}

class _BarisTile extends StatelessWidget {
  const _BarisTile({required this.baris});

  final Baris baris;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              baris.label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: baris.bisaDibuka
                ? _LinkValue(text: baris.value!, url: baris.url!)
                : Text(
                    baris.value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LinkValue extends StatelessWidget {
  const _LinkValue({required this.text, required this.url});

  final String text;
  final String url;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color warna = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return InkWell(
      onTap: () => bukaTautan(context, url),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: warna,
                decoration: TextDecoration.underline,
                decorationColor: warna,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.open_in_new_rounded, size: 13, color: warna),
        ],
      ),
    );
  }
}

// ======================================================================
// StatusHeaderCard: ringkasan di bagian atas halaman detail
// ======================================================================

/// Satu badge kecil pada header (jenis, status, dsb).
class StatusBadge {
  const StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;
}

/// Kartu header ringkasan di paling atas halaman detail: judul (nama
/// usaha/ajuan), badge-badge (jenis, status), subjudul opsional (mis.
/// tanggal dibuat), dan pesan error opsional (mis. alasan sync gagal).
///
/// Dipakai bersama oleh halaman detail Riwayat dan halaman detail
/// Ajuan/Sinkronisasi supaya tampilan kedua halaman konsisten, walau
/// makna badge-nya berbeda di masing-masing konteks.
class StatusHeaderCard extends StatelessWidget {
  const StatusHeaderCard({
    super.key,
    required this.title,
    required this.badges,
    this.subtitle,
    this.errorMessage,
  });

  final String title;
  final List<StatusBadge> badges;
  final String? subtitle;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final StatusBadge b in badges) _BadgeChip(badge: b),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          if (_terisi(subtitle)) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
          if (_terisi(errorMessage)) ...<Widget>[
            const SizedBox(height: 10),
            _ErrorNote(message: errorMessage!),
          ],
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const Color warna = AppTheme.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 15, color: warna),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: warna,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final StatusBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badge.color,
        ),
      ),
    );
  }
}

/// Tombol tautan kecil bergaris tepi (mis. "Buka Listing", "Lihat Peta").
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.menuDashboard,
        side: BorderSide(color: AppTheme.menuDashboard.withValues(alpha: 0.4)),
      ),
    );
  }
}
