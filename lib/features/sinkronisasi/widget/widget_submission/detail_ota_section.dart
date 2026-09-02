import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'ota_tile.dart';

/// Kartu "Platform OTA Terdaftar". Mengembalikan [SizedBox.shrink] jika
/// [entries] kosong. Parsing payload menjadi [OtaEntry] tetap dilakukan
/// di halaman pemanggil.
class DetailOtaSection extends StatelessWidget {
  const DetailOtaSection({
    super.key,
    required this.entries,
    required this.onTapUrl,
  });

  final List<OtaEntry> entries;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform OTA Terdaftar',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            OtaTile(entry: entries[i], onTapUrl: onTapUrl),
          ],
        ],
      ),
    );
  }
}