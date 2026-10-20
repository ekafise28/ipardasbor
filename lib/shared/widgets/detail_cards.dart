import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
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
    this.countSuffix = '',
    this.aksen = AppTheme.menuDashboard,
    this.aksenBg = AppTheme.menuDashboardBg,
  });

  final Widget child;
  final IconData? icon;
  final String? title;
  final int? count;

  /// Mis. ' foto' -> "(3 foto)".
  final String countSuffix;

  /// Warna ikon header dan latar kotaknya (pastel di mode terang).
  final Color aksen;
  final Color aksenBg;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.tintBackground(context, aksen, aksenBg),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: aksen),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                  if (count != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      '($count$countSuffix)',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppTheme.border(context)),
              const SizedBox(height: 2),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Teks pada latar tipis: digelapkan (mode terang) / diterangkan (mode
/// gelap) dari warna dasarnya supaya kontrasnya terbaca.
Color _teksDariWarna(BuildContext context, Color warna) {
  final bool gelap = Theme.of(context).brightness == Brightness.dark;
  return Color.lerp(warna, gelap ? Colors.white : Colors.black, 0.35)!;
}

bool _terisi(String? s) => s != null && s.trim().isNotEmpty;

// ======================================================================
// SectionCard: kartu label-nilai per kategori field
// ======================================================================

/// Satu tombol ikon kecil di ujung [Baris] (mis. buka Maps, WhatsApp,
/// telepon). Dirender oleh [BarisTile] sebelum tombol salin.
class BarisAksi {
  const BarisAksi({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.warna,
  });

  final IconData icon;
  final String tooltip;
  final void Function(BuildContext context) onTap;

  /// Kalau diisi, aksi tampil sebagai tombol berlabel di bawah nilai
  /// (pil, atau tombol lebar untuk peta), bukan ikon di ujung baris.
  final String? label;

  /// Warna pil berlabel. Null = netral.
  final Color? warna;
}

/// Bentuk tampilan khusus sebuah [Baris].
/// - netral / peringatan: label di atas, nilai di dalam kotak (teks panjang)
/// - peta: kotak koordinat dengan tombol buka Maps
enum KotakBaris { tidak, netral, peringatan, peta }

/// Satu pasangan label-nilai yang dirender oleh [SectionCard].
///
/// Nilai null/kosong tampil sebagai "-" (diredupkan) supaya terlihat field
/// mana yang belum terisi.
///
/// Tiga jenis baris:
/// - teks biasa: tekan lama untuk menyalin;
/// - tautan ([url], mis. website): garis bawah + ikon buka-luar;
/// - baris dengan [aksi] (koordinat, nomor HP): nilai teks biasa, aksi
///   berupa tombol ikon di ujung baris.
class Baris {
  const Baris(
    this.label,
    this.value, {
    this.url,
    this.salin = false,
    this.aksi = const <BarisAksi>[],
    this.chips = const <String>[],
    this.sorot = false,
    this.kode = false,
    this.kotak = KotakBaris.tidak,
    this.warnaLencana,
  });

  /// Nilai ditampilkan monospace di dalam chip (KBLI, NIB, NKU, dsb).
  /// Kalau [salin] true, tombol salin ada di dalam chip.
  final bool kode;

  final KotakBaris kotak;

  /// Nilai ditampilkan sebagai lencana kecil berwarna (mis. status).
  final Color? warnaLencana;

  /// Baris koordinat: nilai "lat, lng" sebagai teks biasa, dengan tombol
  /// peta (buka Google Maps) dan tombol salin. Kalau salah satu koordinat
  /// kosong, nilainya "-" dan tombol tidak tampil.
  factory Baris.koordinat(
    Object? lat,
    Object? lng, {
    String label = 'Titik Koordinat Geografis',
  }) {
    final String? la = lat?.toString().trim();
    final String? lo = lng?.toString().trim();
    final bool ada = _terisi(la) && _terisi(lo);
    final String? tautan = ada ? mapsUrl(la, lo) : null;

    return Baris(
      label,
      ada ? '$la, $lo' : null,
      salin: ada,
      kotak: ada ? KotakBaris.peta : KotakBaris.tidak,
      aksi: <BarisAksi>[
        if (tautan != null)
          BarisAksi(
            icon: Icons.map_outlined,
            tooltip: 'Buka di Google Maps',
            label: 'Buka di Google Maps',
            onTap: (BuildContext c) => bukaTautan(c, tautan),
          ),
      ],
    );
  }

  /// Baris nomor telepon. Nomor seluler mendapat tombol WhatsApp dan
  /// telepon, telepon tetap hanya tombol telepon, selain itu teks biasa
  /// (aturannya ada di [klasifikasiNomor]).
  factory Baris.telepon(String label, String? value) {
    final NomorTelepon nomor = klasifikasiNomor(value);
    final String? wa = nomor.waUrl;
    final String? tel = nomor.telUrl;

    return Baris(
      label,
      value,
      aksi: <BarisAksi>[
        if (tel != null)
          BarisAksi(
            icon: Icons.call_outlined,
            tooltip: 'Telepon',
            label: 'Telepon',
            onTap: (BuildContext c) => bukaTautan(
              c,
              tel,
              pesanGagal: 'Aplikasi telepon tidak dapat dibuka.',
            ),
          ),
        if (wa != null)
          BarisAksi(
            icon: Icons.chat_outlined,
            tooltip: 'Chat WhatsApp',
            label: 'Kirim Pesan',
            warna: AppTheme.success,
            onTap: (BuildContext c) =>
                bukaTautan(c, wa, pesanGagal: 'WhatsApp tidak dapat dibuka.'),
          ),
      ],
    );
  }

  /// Baris berisi beberapa chip (mis. status ketidaksesuaian). Nilai teksnya
  /// gabungan koma, dipakai untuk tekan lama dan penanda "kosong".
  factory Baris.chips(String label, List<String> items) {
    return Baris(label, items.isEmpty ? null : items.join(', '), chips: items);
  }

  final String label;
  final String? value;

  /// Kalau diisi, baris ini dirender sebagai tautan yang bisa ditekan
  /// untuk membuka [url] (bukan sekadar teks biasa).
  final String? url;

  /// Tampilkan tombol salin di ujung baris (hanya kalau nilainya ada).
  /// Terlepas dari ini, tekan lama di baris mana pun menyalin nilainya.
  final bool salin;

  /// Tombol ikon di ujung baris, ditampilkan sebelum tombol salin.
  final List<BarisAksi> aksi;

  /// Kalau tidak kosong, nilai dirender sebagai chip, bukan teks.
  final List<String> chips;

  /// Nilai ditampilkan merah dan tebal (mis. hasil validasi tidak valid).
  final bool sorot;

  bool get adaIsi => _terisi(value);
  bool get bisaDibuka => adaIsi && _terisi(url);
}

/// Kartu section untuk satu kategori field, dengan header ikon + judul.
///
/// Dipakai bersama oleh halaman detail Riwayat (data server), Ajuan
/// (data lokal offline), dan Baseline OTA supaya tampilannya konsisten.
/// [footer] opsional untuk widget tambahan di bawah baris (mis. tombol).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
    this.footer,
    this.aksen = AppTheme.menuDashboard,
    this.aksenBg = AppTheme.menuDashboardBg,
  });

  final IconData icon;
  final String title;
  final List<Baris> rows;
  final Widget? footer;
  final Color aksen;
  final Color aksenBg;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      icon: icon,
      title: title,
      aksen: aksen,
      aksenBg: aksenBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                color: AppTheme.border(context).withValues(alpha: 0.7),
              ),
            BarisTile(baris: rows[i]),
          ],
          if (footer != null) ...<Widget>[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

/// Satu baris label-nilai. Publik supaya bisa dipakai di dalam
/// [DetailCard] yang isinya campuran (baris + widget lain).
class BarisTile extends StatelessWidget {
  const BarisTile({super.key, required this.baris});

  final Baris baris;

  @override
  Widget build(BuildContext context) {
    final bool adaIsi = baris.adaIsi;

    final Widget isi = switch (adaIsi ? baris.kotak : KotakBaris.tidak) {
      KotakBaris.netral || KotakBaris.peringatan => _bentukKotak(context),
      KotakBaris.peta => _bentukPeta(context),
      KotakBaris.tidak => _bentukBaris(context),
    };

    if (!adaIsi) return isi;

    // Tekan lama di baris mana pun menyalin nilainya.
    return InkWell(
      onLongPress: () => salinKeClipboard(context, baris.value!, baris.label),
      child: isi,
    );
  }

  /// Label kiri, nilai rata kanan. Aksi berlabel (Telepon, Kirim Pesan)
  /// berupa pil di bawah nilai.
  Widget _bentukBaris(BuildContext context) {
    final bool adaIsi = baris.adaIsi;
    final List<BarisAksi> aksiIkon = adaIsi
        ? baris.aksi.where((BarisAksi a) => a.label == null).toList()
        : <BarisAksi>[];
    final List<BarisAksi> aksiLabel = adaIsi
        ? baris.aksi.where((BarisAksi a) => a.label != null).toList()
        : <BarisAksi>[];
    final bool salinLuar = adaIsi && baris.salin && !baris.kode;
    final bool sebaris = aksiIkon.isNotEmpty || salinLuar;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: sebaris
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  baris.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _nilai(context),
                ),
              ),
              for (final BarisAksi a in aksiIkon)
                _TombolBaris(
                  icon: a.icon,
                  tooltip: a.tooltip,
                  onTap: () => a.onTap(context),
                ),
              if (salinLuar)
                _TombolBaris(
                  icon: Icons.copy_rounded,
                  tooltip: 'Salin ${baris.label}',
                  onTap: () =>
                      salinKeClipboard(context, baris.value!, baris.label),
                ),
            ],
          ),
          if (aksiLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  for (final BarisAksi a in aksiLabel) _PilAksi(aksi: a),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _nilai(BuildContext context) {
    if (!baris.adaIsi) {
      return Text(
        '-',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13.5,
          fontStyle: FontStyle.italic,
          color: AppTheme.textMuted,
        ),
      );
    }
    if (baris.chips.isNotEmpty) return _DaftarNilai(items: baris.chips);
    if (baris.bisaDibuka) {
      return _LinkValue(text: baris.value!, url: baris.url!);
    }
    if (baris.warnaLencana != null) {
      return _LencanaNilai(text: baris.value!, warna: baris.warnaLencana!);
    }
    if (baris.kode) {
      return _KodeNilai(
        text: baris.value!,
        tooltip: 'Salin ${baris.label}',
        onSalin: baris.salin
            ? () => salinKeClipboard(context, baris.value!, baris.label)
            : null,
      );
    }
    return Text(
      baris.value!,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: baris.sorot ? FontWeight.w800 : FontWeight.w600,
        color: baris.sorot ? AppTheme.danger : AppTheme.textColor(context),
      ),
    );
  }

  /// Teks panjang: label kapital kecil di atas, nilai di dalam kotak.
  Widget _bentukKotak(BuildContext context) {
    final bool peringatan = baris.kotak == KotakBaris.peringatan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            baris.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: peringatan
                  ? AppTheme.warningSurface(context)
                  : AppTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: peringatan
                    ? AppTheme.warning.withValues(alpha: 0.35)
                    : AppTheme.border(context),
              ),
            ),
            child: Text(
              baris.value!,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kotak koordinat: label + salin, koordinat monospace, tombol Maps.
  Widget _bentukPeta(BuildContext context) {
    final List<BarisAksi> aksi = baris.aksi
        .where((BarisAksi a) => a.label != null)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    baris.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
                if (baris.salin)
                  _TombolBaris(
                    icon: Icons.copy_rounded,
                    tooltip: 'Salin ${baris.label}',
                    onTap: () =>
                        salinKeClipboard(context, baris.value!, baris.label),
                  ),
              ],
            ),
            Text(
              baris.value!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
            ),
            for (final BarisAksi a in aksi) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => a.onTap(context),
                icon: Icon(a.icon, size: 18, color: AppTheme.danger),
                label: Text(
                  a.label!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: AppTheme.textColor(context),
                  backgroundColor: AppTheme.surface(context),
                  side: BorderSide(color: AppTheme.border(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip monospace untuk kode (KBLI, NIB, NKU). Tombol salin di dalam chip.
class _KodeNilai extends StatelessWidget {
  const _KodeNilai({required this.text, required this.tooltip, this.onSalin});

  final String text;
  final String tooltip;
  final VoidCallback? onSalin;

  @override
  Widget build(BuildContext context) {
    final bool adaSalin = onSalin != null;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: adaSalin ? 2 : 8,
        top: adaSalin ? 0 : 2,
        bottom: adaSalin ? 0 : 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          if (adaSalin)
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                tooltip: tooltip,
                color: AppTheme.textSecondary(context),
                onPressed: onSalin,
                icon: const Icon(Icons.copy_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lencana kecil untuk nilai status (mis. SELESAI).
class _LencanaNilai extends StatelessWidget {
  const _LencanaNilai({required this.text, required this.warna});

  final String text;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _teksDariWarna(context, warna),
        ),
      ),
    );
  }
}

/// Pil aksi berlabel (Telepon, Kirim Pesan).
class _PilAksi extends StatelessWidget {
  const _PilAksi({required this.aksi});

  final BarisAksi aksi;

  @override
  Widget build(BuildContext context) {
    final Color? w = aksi.warna;
    final Color fg = w == null
        ? AppTheme.textColor(context)
        : _teksDariWarna(context, w);

    return Material(
      color: w == null
          ? AppTheme.surfaceMuted(context)
          : w.withValues(alpha: 0.12),
      shape: StadiumBorder(
        side: w == null
            ? BorderSide.none
            : BorderSide(color: w.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => aksi.onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(aksi.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                aksi.label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
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

/// Daftar nilai berbentuk pil amber dengan titik (status ketidaksesuaian),
/// rata kanan. Teks boleh turun baris.
class _DaftarNilai extends StatelessWidget {
  const _DaftarNilai({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    const Color warna = AppTheme.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: warna.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: warna,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _teksDariWarna(context, warna),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Tombol ikon kecil di ujung baris. Area sentuhnya 32x32 dan
/// tidak menambah tinggi baris secara berlebihan.
class _TombolBaris extends StatelessWidget {
  const _TombolBaris({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: tooltip,
        color: AppTheme.textSecondary(context),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

// ======================================================================
// StatusHeaderCard: ringkasan di bagian atas halaman detail
// ======================================================================

/// Satu badge kecil pada header (jenis, status, dsb).
class StatusBadge {
  const StatusBadge({
    required this.text,
    required this.color,
    this.ikon,
    this.titik = false,
  });

  final String text;
  final Color color;

  /// Ikon atau titik kecil di depan teks (jangan keduanya).
  final IconData? ikon;
  final bool titik;
}

/// Satu pasangan label-nilai kecil di dasar [StatusHeaderCard].
class HeaderMeta {
  const HeaderMeta(this.label, this.value);

  final String label;
  final String? value;
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
    this.jenis,
    this.meta = const <HeaderMeta>[],
  });

  final String title;
  final List<StatusBadge> badges;
  final String? subtitle;
  final String? errorMessage;

  /// Chip jenis di atas judul (mis. OSS / NON OSS).
  final StatusBadge? jenis;

  /// Petugas, tanggal, dsb, di bawah garis pemisah.
  final List<HeaderMeta> meta;

  @override
  Widget build(BuildContext context) {
    final bool modeBaru = jenis != null || meta.isNotEmpty;
    return DetailCard(child: modeBaru ? _isiBaru(context) : _isiLama(context));
  }

  @override
  Widget _isiLama(BuildContext context) {
    return Column(
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
    );
  }

  Widget _isiBaru(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (jenis != null) ...<Widget>[
                    _JenisChip(badge: jenis!),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
                ],
              ),
            ),
            if (badges.isNotEmpty) ...<Widget>[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (int i = 0; i < badges.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 6),
                      _BadgeChip(badge: badges[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        if (_terisi(errorMessage)) ...<Widget>[
          const SizedBox(height: 10),
          _ErrorNote(message: errorMessage!),
        ],
        if (meta.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.border(context)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < meta.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        meta[i].label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _terisi(meta[i].value) ? meta[i].value!.trim() : '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (badge.titik)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: badge.color,
                shape: BoxShape.circle,
              ),
            )
          else if (badge.ikon != null)
            Icon(badge.ikon, size: 14, color: badge.color),
          if (badge.titik || badge.ikon != null) const SizedBox(width: 5),
          Flexible(
            child: Text(
              badge.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _teksDariWarna(context, badge.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JenisChip extends StatelessWidget {
  const _JenisChip({required this.badge});

  final StatusBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        badge.text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _teksDariWarna(context, badge.color),
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

/// Satu baris kecil di dasar halaman detail (mis. "Dibuat ... · Diperbarui ...").
class MetaFooter extends StatelessWidget {
  const MetaFooter({super.key, required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        teks,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
      ),
    );
  }
}

// ======================================================================
// Foto dokumentasi: grid 3 kolom + viewer layar penuh
// ======================================================================

/// Satu foto pada galeri. Sumbernya bisa URL (data server) atau file lokal
/// (ajuan offline); sisanya diperlakukan sama.
class FotoItem {
  const FotoItem({required this.id, required this.image, this.keterangan});

  FotoItem.url(String url, {String? keterangan})
    : this(id: url, image: NetworkImage(url), keterangan: keterangan);

  FotoItem.file(String path, {String? keterangan})
    : this(id: path, image: FileImage(File(path)), keterangan: keterangan);

  /// Pembeda untuk tag Hero (URL atau path file).
  final String id;
  final ImageProvider image;
  final String? keterangan;
}

String _heroTag(FotoItem foto, int index) => 'detail_foto_${index}_${foto.id}';

/// Kartu foto dokumentasi: grid 3 kolom. Tap foto membuka viewer layar
/// penuh dengan swipe antar foto dan pinch-to-zoom. Kosong = tidak tampil.
class FotoGallerySection extends StatelessWidget {
  const FotoGallerySection({super.key, required this.foto});

  final List<FotoItem> foto;

  @override
  Widget build(BuildContext context) {
    if (foto.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: Icons.photo_library_outlined,
      title: 'Foto Dokumentasi',
      count: foto.length,
      countSuffix: ' foto',
      aksen: AppTheme.menuFoto,
      aksenBg: AppTheme.menuFotoBg,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: foto.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () => _bukaViewer(context, index),
            child: Hero(
              tag: _heroTag(foto[index], index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: Colors.black12,
                  child: Image(
                    image: foto[index].image,
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? progress,
                        ) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _bukaViewer(BuildContext context, int indexAwal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FotoViewerPage(foto: foto, indexAwal: indexAwal),
        fullscreenDialog: true,
      ),
    );
  }
}

class _FotoViewerPage extends StatefulWidget {
  const _FotoViewerPage({required this.foto, required this.indexAwal});

  final List<FotoItem> foto;
  final int indexAwal;

  @override
  State<_FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<_FotoViewerPage> {
  late final PageController _pageController = PageController(
    initialPage: widget.indexAwal,
  );
  late int _indexSaatIni = widget.indexAwal;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FotoItem item = widget.foto[_indexSaatIni];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_indexSaatIni + 1} / ${widget.foto.length}'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.foto.length,
              onPageChanged: (int index) {
                setState(() => _indexSaatIni = index);
              },
              itemBuilder: (BuildContext context, int index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Hero(
                      tag: _heroTag(widget.foto[index], index),
                      child: Image(
                        image: widget.foto[index].image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_terisi(item.keterangan))
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item.keterangan!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================================
// Listing OTA: dipakai Riwayat (data server) dan Ajuan (data lokal)
// ======================================================================

/// Satu listing OTA yang ditampilkan di [OtaListSection]. Semua field
/// selain [judul] opsional, jadi data yang minim (ajuan lokal: hanya
/// nama platform + URL) dan data lengkap (riwayat) memakai tile yang sama.
class OtaListingItem {
  const OtaListingItem({
    required this.judul,
    this.platform,
    this.status,
    this.hargaTerendah,
    this.rating,
    this.jumlahUlasan,
    this.tanggalDitemukan,
    this.catatan,
    this.urls = const <String>[],
    this.mapsUrl,
  });

  /// Nama listing, atau nama platform kalau listing tidak punya nama.
  final String judul;

  /// Nama platform di bawah judul (isi hanya kalau [judul] bukan platform).
  final String? platform;
  final String? status;
  final num? hargaTerendah;
  final String? rating;
  final num? jumlahUlasan;

  /// Sudah diformat (mis. lewat formatTanggal).
  final String? tanggalDitemukan;
  final String? catatan;
  final List<String> urls;
  final String? mapsUrl;
}

/// Kartu daftar listing OTA. Kosong = tidak tampil.
class OtaListSection extends StatelessWidget {
  const OtaListSection({
    super.key,
    required this.items,
    this.title = 'Listing OTA',
  });

  final List<OtaListingItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: Icons.travel_explore_outlined,
      title: title,
      count: items.length,
      aksen: AppTheme.menuOta,
      aksenBg: AppTheme.menuOtaBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 20),
            _OtaTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _OtaTile extends StatelessWidget {
  const _OtaTile({required this.item});

  final OtaListingItem item;

  Color _warnaStatus() {
    switch ((item.status ?? '').toUpperCase()) {
      case 'AKTIF':
        return Colors.green;
      case 'TIDAK AKTIF':
      case 'NONAKTIF':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> urls = item.urls
        .where((String u) => u.trim().isNotEmpty)
        .toList();
    final bool adaPeta = _terisi(item.mapsUrl);

    final List<Widget> info = <Widget>[
      if (item.hargaTerendah != null)
        _InfoKecil(
          icon: Icons.sell_outlined,
          text: 'Rp ${item.hargaTerendah!.toStringAsFixed(0)}',
        ),
      if (item.rating != null)
        _InfoKecil(
          icon: Icons.star_outline_rounded,
          text: '${item.rating} (${item.jumlahUlasan ?? 0} ulasan)',
        ),
      if (_terisi(item.tanggalDitemukan))
        _InfoKecil(
          icon: Icons.calendar_today_outlined,
          text: 'Ditemukan ${item.tanggalDitemukan}',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                item.judul,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            if (_terisi(item.status))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _warnaStatus().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _warnaStatus(),
                  ),
                ),
              ),
          ],
        ),
        if (_terisi(item.platform)) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            item.platform!,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
        if (info.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: info),
        ],
        if (_terisi(item.catatan)) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            item.catatan!,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
        if (urls.isNotEmpty || adaPeta) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              for (int i = 0; i < urls.length; i++)
                LinkButton(
                  icon: Icons.open_in_new_rounded,
                  label: urls.length > 1
                      ? 'Buka Link ${i + 1}'
                      : 'Buka Listing',
                  onTap: () => bukaTautan(context, urls[i]),
                ),
              if (adaPeta)
                LinkButton(
                  icon: Icons.map_outlined,
                  label: 'Lihat Peta',
                  onTap: () => bukaTautan(context, item.mapsUrl),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoKecil extends StatelessWidget {
  const _InfoKecil({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: AppTheme.textSecondary(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
