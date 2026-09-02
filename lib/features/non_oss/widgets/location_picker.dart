import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onGetLocation,
  });

  final String latitude;
  final String longitude;
  final bool loading;
  final VoidCallback onGetLocation;

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
                  hasLocation
                      ? 'Koordinat lokasi berhasil diperoleh.'
                      : 'Koordinat GPS belum diambil.',
                  style: const TextStyle(
                    color: Color(0xFF405366),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
              loading
                  ? 'Sedang mengambil lokasi...'
                  : hasLocation
                  ? 'Perbarui Lokasi GPS'
                  : 'Ambil Lokasi GPS',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColor(context)),
            ),
          ),
        ),
      ],
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
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 10),
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
