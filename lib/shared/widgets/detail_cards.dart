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

/// Satu tombol ikon kecil di ujung [Baris] (mis. buka Maps, WhatsApp,
/// telepon). Dirender oleh [BarisTile] sebelum tombol salin.
class BarisAksi {
  const BarisAksi({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;

  /// Juga dipakai sebagai label aksesibilitas.
  final String tooltip;
  final void Function(BuildContext context) onTap;
}

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
  });

  /// Baris koordinat: nilai "lat, lng" sebagai teks biasa, dengan tombol
  /// peta (buka Google Maps) dan tombol salin. Kalau salah satu koordinat
  /// kosong, nilainya "-" dan tombol tidak tampil.
  factory Baris.koordinat(
    Object? lat,
    Object? lng, {
    String label = 'Koordinat',
  }) {
    final String? la = lat?.toString().trim();
    final String? lo = lng?.toString().trim();
    final bool ada = _terisi(la) && _terisi(lo);
    final String? tautan = ada ? mapsUrl(la, lo) : null;

    return Baris(
      label,
      ada ? '$la, $lo' : null,
      salin: ada,
      aksi: <BarisAksi>[
        if (tautan != null)
          BarisAksi(
            icon: Icons.map_outlined,
            tooltip: 'Buka di Maps',
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
        if (wa != null)
          BarisAksi(
            icon: Icons.chat_outlined,
            tooltip: 'Chat WhatsApp',
            onTap: (BuildContext c) =>
                bukaTautan(c, wa, pesanGagal: 'WhatsApp tidak dapat dibuka.'),
          ),
        if (tel != null)
          BarisAksi(
            icon: Icons.call_outlined,
            tooltip: 'Telepon',
            onTap: (BuildContext c) => bukaTautan(
              c,
              tel,
              pesanGagal: 'Aplikasi telepon tidak dapat dibuka.',
            ),
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
  });

  final IconData icon;
  final String title;
  final List<Baris> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final Baris baris in rows) BarisTile(baris: baris),
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

    final Widget isi = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        // Baris panjang (keterangan, chip) rata atas; baris dengan tombol
        // ikon tetap rata tengah supaya sejajar dengan tombolnya.
        crossAxisAlignment: (baris.aksi.isEmpty && !baris.salin)
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
            child: baris.chips.isNotEmpty
                ? _DaftarNilai(items: baris.chips)
                : baris.bisaDibuka
                ? _LinkValue(text: baris.value!, url: baris.url!)
                : Text(
                    adaIsi ? baris.value! : '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: !adaIsi
                          ? FontWeight.w400
                          : (baris.sorot ? FontWeight.w800 : FontWeight.w600),
                      color: !adaIsi
                          ? AppTheme.textMuted
                          : (baris.sorot
                                ? AppTheme.danger
                                : AppTheme.textColor(context)),
                    ),
                  ),
          ),
          if (adaIsi)
            for (final BarisAksi a in baris.aksi)
              _TombolBaris(
                icon: a.icon,
                tooltip: a.tooltip,
                onTap: () => a.onTap(context),
              ),
          if (adaIsi && baris.salin)
            _TombolBaris(
              icon: Icons.copy_rounded,
              tooltip: 'Salin ${baris.label}',
              onTap: () => salinKeClipboard(context, baris.value!, baris.label),
            ),
        ],
      ),
    );

    if (!adaIsi) return isi;

    // Tekan lama di baris mana pun menyalin nilainya.
    return InkWell(
      onLongPress: () => salinKeClipboard(context, baris.value!, baris.label),
      child: isi,
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

/// Daftar nilai vertikal: satu item per baris dengan penanda titik di kiri.
/// Teks boleh turun baris, jadi label panjang tidak overflow.
class _DaftarNilai extends StatelessWidget {
  const _DaftarNilai({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
