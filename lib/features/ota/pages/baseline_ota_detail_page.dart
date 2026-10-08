import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/shared/widgets/detail_status_header.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../models/baseline_ota_item.dart';
import '../widgets/baseline_ota_card.dart';

/// Pilihan verifikasi yang dikembalikan halaman detail ke halaman daftar.
enum BaselineOtaAksi { adaNib, tidakAda, tidakTahu }

class BaselineOtaDetailPage extends StatelessWidget {
  const BaselineOtaDetailPage({super.key, required this.item});

  final BaselineOtaItem item;

  String _tgl(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _buka(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tautan ini.')),
        );
      }
    }
  }

  Future<void> _salin(BuildContext context, String teks, String label) async {
    await Clipboard.setData(ClipboardData(text: teks));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$label disalin.')));
    }
  }

  String? get _urlMaps {
    if ((item.urlMaps ?? '').trim().isNotEmpty) return item.urlMaps;
    if (item.latitude != null && item.longitude != null) {
      return 'https://www.google.com/maps?q=${item.latitude},${item.longitude}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool adaNama = (item.namaListing ?? '').trim().isNotEmpty;
    final bool adaAlamat = (item.alamat ?? '').trim().isNotEmpty;
    final bool adaKoordinat = item.latitude != null && item.longitude != null;
    final BaselineOtaVerifikasi? v = item.verifikasiAktif;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Listing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Header: nama + chip platform + status.
          Text(
            adaNama ? item.namaListing! : '(Tanpa nama listing)',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OtaPlatformChip(platform: item.platformOta),
              OtaStatusBadge(sudahDiverifikasi: item.sudahDiverifikasi),
            ],
          ),
          const SizedBox(height: 16),

          _Seksi(
            judul: 'Lokasi',
            anak: [
              _Baris(
                label: 'Alamat',
                nilai: adaAlamat ? item.alamat! : '-',
                onSalin: adaAlamat
                    ? () => _salin(context, item.alamat!, 'Alamat')
                    : null,
              ),
              _Baris(
                label: 'Kabupaten/Kota',
                nilai: _atauStrip(item.kabupaten),
              ),
              _Baris(label: 'Kecamatan', nilai: _atauStrip(item.kecamatan)),
              _Baris(
                label: 'Kelurahan/Desa',
                nilai: _atauStrip(item.kelurahan),
              ),
              _Baris(
                label: 'Koordinat',
                nilai: adaKoordinat
                    ? '${item.latitude}, ${item.longitude}'
                    : '-',
                onSalin: adaKoordinat
                    ? () => _salin(
                        context,
                        '${item.latitude}, ${item.longitude}',
                        'Koordinat',
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          _Seksi(
            judul: 'Sumber data',
            anak: [
              _Baris(label: 'Platform', nilai: _atauStrip(item.platformOta)),
              _Baris(
                label: 'Tanggal scraping',
                nilai: item.scrapedAt != null ? _tgl(item.scrapedAt!) : '-',
              ),
              _Baris(label: 'ID listing', nilai: '#${item.id}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (item.sourceUrl ?? '').trim().isNotEmpty
                          ? () => _buka(context, item.sourceUrl)
                          : null,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text('Listing OTA'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _urlMaps != null
                          ? () => _buka(context, _urlMaps)
                          : null,
                      icon: const Icon(Icons.map_rounded, size: 17),
                      label: const Text('Buka Maps'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (item.sudahDiverifikasi) ...[
            const SizedBox(height: 12),
            _Seksi(
              judul: 'Hasil verifikasi',
              anak: [
                OtaSudahDiverifikasiBox(verifikasi: v),
                if ((v?.idProyek ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _Baris(label: 'ID Proyek', nilai: v!.idProyek!),
                ],
              ],
            ),
          ],
        ],
      ),

      // Aksi verifikasi menempel di bawah layar, hanya kalau belum diverifikasi.
      bottomNavigationBar: item.sudahDiverifikasi
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                border: Border(
                  top: BorderSide(color: AppTheme.border(context)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: OtaVerifButton(
                          label: 'Ada NIB',
                          color: AppTheme.primaryColor,
                          filled: true,
                          onTap: () =>
                              Navigator.pop(context, BaselineOtaAksi.adaNib),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: OtaVerifButton(
                          label: 'Tidak Ada',
                          color: Colors.red.shade700,
                          onTap: () =>
                              Navigator.pop(context, BaselineOtaAksi.tidakAda),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: OtaVerifButton(
                          label: 'Tidak Tahu',
                          color: Colors.blueGrey.shade600,
                          onTap: () =>
                              Navigator.pop(context, BaselineOtaAksi.tidakTahu),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _atauStrip(String? s) => (s ?? '').trim().isEmpty ? '-' : s!;
}

/// Kotak bagian dengan judul.
class _Seksi extends StatelessWidget {
  const _Seksi({required this.judul, required this.anak});
  final String judul;
  final List<Widget> anak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...anak,
        ],
      ),
    );
  }
}

/// Satu pasang label-nilai, dengan tombol salin opsional.
class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.nilai, this.onSalin});
  final String label;
  final String nilai;
  final VoidCallback? onSalin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          if (onSalin != null)
            InkWell(
              onTap: onSalin,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
