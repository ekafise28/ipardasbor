import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../dashboard/models/dashboard_map_model.dart';

/// Section peta sebaran pengawasan, meniru tampilan web Laravel (Leaflet).
///
/// Dependensi yang perlu ditambahkan ke pubspec.yaml:
///   flutter_map: ^7.0.0
///   flutter_map_marker_cluster: ^1.4.0
///   latlong2: ^0.9.1
class DashboardMapSection extends StatefulWidget {
  final List<MapPoint> points;
  final MapConfigData config;

  const DashboardMapSection({
    super.key,
    required this.points,
    required this.config,
  });

  @override
  State<DashboardMapSection> createState() => _DashboardMapSectionState();
}

class _DashboardMapSectionState extends State<DashboardMapSection> {
  final Set<MapPointType> _visibleTypes = <MapPointType>{
    MapPointType.oss,
    MapPointType.nonOss,
    MapPointType.ota,
  };

  final MapController _mapController = MapController();

  List<MapPoint> get _filteredPoints => widget.points
      .where((point) => _visibleTypes.contains(point.type))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 420,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        widget.config.latitude,
                        widget.config.longitude,
                      ),
                      initialZoom: widget.config.zoom.toDouble(),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.yourapp.package',
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          markers: _filteredPoints.map(_buildMarker).toList(),
                          builder: (context, markers) =>
                              _ClusterBubble(count: markers.length),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _MapLegend(
                      visibleTypes: _visibleTypes,
                      onToggle: (type) {
                        setState(() {
                          if (_visibleTypes.contains(type)) {
                            _visibleTypes.remove(type);
                          } else {
                            _visibleTypes.add(type);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF9AA5B5),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Klik titik untuk melihat informasi usaha. Gunakan checklist di kanan atas untuk menampilkan atau menyembunyikan kategori.',
                  style: TextStyle(color: Color(0xFF9AA5B5), fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Color(0xFF1565C0),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peta Sebaran Pengawasan',
                    style: TextStyle(
                      color: Color(0xFF17243A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lokasi OSS, Non-OSS, dan Baseline OTA Provinsi ${widget.config.provinceName}.',
                    style: const TextStyle(
                      color: Color(0xFF7A879A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _CountChip(
              color: const Color(0xFF1565C0),
              label: 'OSS: ${widget.config.totalOss}',
            ),
            _CountChip(
              color: const Color(0xFFE53935),
              label: 'Non OSS: ${widget.config.totalNonOss}',
            ),
            _CountChip(
              color: const Color(0xFFFF9500),
              label: 'OTA: ${widget.config.totalOta}',
            ),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker(MapPoint point) {
    return Marker(
      point: LatLng(point.latitude, point.longitude),
      width: 34,
      height: 34,
      child: GestureDetector(
        onTap: () => _showPointDetail(point),
        child: Container(
          decoration: BoxDecoration(
            color: point.type.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showPointDetail(MapPoint point) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PointDetailSheet(point: point),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  final int count;
  const _ClusterBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8BC34A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF17243A),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final Color color;
  final String label;
  const _CountChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Set<MapPointType> visibleTypes;
  final ValueChanged<MapPointType> onToggle;

  const _MapLegend({required this.visibleTypes, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E4EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: MapPointType.values.map((type) {
          final bool checked = visibleTypes.contains(type);
          return InkWell(
            onTap: () => onToggle(type),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (_) => onToggle(type),
                    activeColor: type.color,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    '${type.label} — ${_dotLabel(type)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF344156),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _dotLabel(MapPointType type) {
    switch (type) {
      case MapPointType.oss:
        return 'Biru';
      case MapPointType.nonOss:
        return 'Merah';
      case MapPointType.ota:
        return 'Oranye';
    }
  }
}

class _PointDetailSheet extends StatelessWidget {
  final MapPoint point;
  const _PointDetailSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: point.type.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    point.type.label,
                    style: TextStyle(
                      color: point.type.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              point.title.isEmpty ? '(Tanpa nama)' : point.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17243A),
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.place_outlined,
              label: point.address.isEmpty ? '-' : point.address,
            ),
            _DetailRow(
              icon: Icons.location_city_outlined,
              label: point.district,
            ),
            _DetailRow(
              icon: Icons.fact_check_outlined,
              label: 'Status: ${point.status}',
            ),
            _DetailRow(icon: Icons.badge_outlined, label: 'NIB: ${point.nib}'),
            if (point.platform != null)
              _DetailRow(
                icon: Icons.travel_explore_rounded,
                label: 'Platform: ${point.platform}',
              ),
            if (point.sourceUrl != null)
              _DetailRow(icon: Icons.link_rounded, label: point.sourceUrl!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF7A879A)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF344156),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
