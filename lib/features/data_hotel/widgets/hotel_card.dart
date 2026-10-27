import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/hotel_item.dart';

class HotelCard extends StatelessWidget {
  const HotelCard({super.key, required this.item, required this.onTap});

  final HotelItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool adaDampak = item.totalTerdampak > 0;

    return StripCard(
      stripColor: adaDampak ? AppTheme.warning : AppTheme.primaryColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.namaHotel,
            statusLabel: item.statusHotel ?? 'Status -',
            statusColor: AppTheme.secondaryColor,
          ),
          const SizedBox(height: 8),
          ListInfoRow(
            icon: Icons.place_outlined,
            text: '${item.kabKota}, ${item.provinsi}',
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          MutedPanel(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: <Widget>[
                _Stat(icon: Icons.bed_outlined, label: 'Kamar', value: formatNumber(item.kamar)),
                _Stat(icon: Icons.meeting_room_outlined, label: 'Meeting', value: formatNumber(item.meetingMice)),
                _Stat(icon: Icons.groups_2_outlined, label: 'Karyawan', value: formatNumber(item.totalKaryawan)),
              ],
            ),
          ),
          if (adaDampak) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded, size: 15, color: AppTheme.warning),
                const SizedBox(width: 6),
                Text(
                  '${formatNumber(item.totalTerdampak)} karyawan terdampak',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}