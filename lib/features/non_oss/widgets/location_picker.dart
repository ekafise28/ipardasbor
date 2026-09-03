import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_fetch_status.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onGetLocation,
    this.status,
    this.sisaDetik,
    this.source,
  });

  final String latitude;
  final String longitude;
  final bool loading;
  final VoidCallback onGetLocation;

  /// Tahapan proses saat ini (null kalau tidak sedang loading).
  final LocationFetchStatus? status;

  /// Sisa detik hitung mundur saat mencari sinyal GPS (null kalau tidak
  /// dalam tahap menunggu sinyal).
  final int? sisaDetik;

  final LocationSource? source;

  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);
    final hasLocation = lat != null && lng != null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasLocation
                ? const Color(0xFFEAF8F1)
                : const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLocation
                  ? const Color(0xFFBCE8D1)
                  : const Color(0xFFE5EBF0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.check_circle : Icons.location_searching,
                color: hasLocation
                    ? const Color(0xFF1F9D68)
                    : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _pesanStatus(hasLocation),
                  style: const TextStyle(
                    color: Color(0xFF405366),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (loading && status == LocationFetchStatus.mencariSinyalGps)
                _CountdownBadge(sisaDetik: sisaDetik ?? 0),
            ],
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Coordinate(label: 'Latitude', value: latitude),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Coordinate(label: 'Longitude', value: longitude),
              ),
            ],
          ),
          if (source != null && source != LocationSource.gpsLangsung) ...[
            const SizedBox(height: 8),
            _SumberBadge(source: source!),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              height: 190,
              child: FlutterMap(
                key: ValueKey('$latitude,$longitude'),
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'id.go.kemenpar.ipardasbor',
                    errorTileCallback: (tile, error, stackTrace) {
                      // Sengaja diabaikan: kegagalan memuat tile peta saat
                      // offline adalah kondisi normal, bukan bug. Tanpa
                      // callback ini, exception-nya "lolos" sebagai
                      // unhandled error dan bikin debugger pause di VS Code.
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFE53935),
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: loading ? null : onGetLocation,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, color: Colors.white),
            label: Text(
              _labelTombol(hasLocation),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _pesanStatus(bool hasLocation) {
    if (!loading) {
      return hasLocation
          ? 'Koordinat lokasi berhasil diperoleh.'
          : 'Koordinat GPS belum diambil.';
    }

    switch (status) {
      case LocationFetchStatus.memintaIzin:
        return 'Memeriksa izin lokasi...';
      case LocationFetchStatus.mencariSinyalGps:
        return 'Mencari sinyal GPS...';
      case LocationFetchStatus.memakaiLokasiTersimpanTanpaInternet:
        return 'Tidak ada internet, memakai lokasi tersimpan terakhir...';
      case LocationFetchStatus.memakaiLokasiTersimpanSinyalLemah:
        return 'Sinyal GPS lemah, memakai lokasi tersimpan terakhir...';
      case LocationFetchStatus.gagalTanpaCadangan:
        return 'GPS tidak tersedia dan tidak ada lokasi tersimpan.';
      case LocationFetchStatus.berhasil:
      case null:
        return 'Mengambil lokasi...';
    }
  }

  String _labelTombol(bool hasLocation) {
    if (!loading) {
      return hasLocation ? 'Perbarui Lokasi GPS' : 'Ambil Lokasi GPS';
    }

    if (status == LocationFetchStatus.memakaiLokasiTersimpanTanpaInternet ||
        status == LocationFetchStatus.memakaiLokasiTersimpanSinyalLemah) {
      return 'Memakai lokasi tersimpan...';
    }

    return 'Sedang mengambil lokasi...';
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.sisaDetik});

  final int sisaDetik;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBCE8D1)),
      ),
      child: Text(
        '${sisaDetik}s',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F9D68),
        ),
      ),
    );
  }
}

class _Coordinate extends StatelessWidget {
  const _Coordinate({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF172B3A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SumberBadge extends StatelessWidget {
  const _SumberBadge({required this.source});

  final LocationSource source;

  @override
  Widget build(BuildContext context) {
    final bool tanpaInternet = source == LocationSource.tersimpanTanpaInternet;

    final Color warna = tanpaInternet
        ? const Color(0xFFD97706) // oranye — perlu perhatian lebih
        : const Color(0xFF64748B); // abu-abu — netral

    final String pesan = tanpaInternet
        ? 'Perangkat sedang offline — koordinat ini dari lokasi tersimpan terakhir, bukan posisi saat ini.'
        : 'Sinyal GPS lemah — koordinat ini dari lokasi tersimpan terakhir, bukan posisi saat ini.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: warna),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pesan,
              style: TextStyle(
                fontSize: 11,
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
