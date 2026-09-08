import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Selector platform OTA bergaya checkbox grid + URL inline, mengikuti
/// tampilan form Laravel OSS (form blade 2) — beda gaya dari OtaSelector
/// milik Non-OSS (ListTile vertikal), tapi struktur datanya sama:
/// Map<String, List<String>> key platform -> daftar URL.
class OtaPlatformSelector extends StatelessWidget {
  const OtaPlatformSelector({
    super.key,
    required this.urls,
    required this.onChanged,
  });

  final Map<String, List<String>> urls;
  final ValueChanged<Map<String, List<String>>> onChanged;

  static const Map<String, String> platforms = {
    'booking_com': 'Booking.com',
    'tiket_com': 'Tiket.com',
    'oyo': 'OYO',
    'agoda': 'Agoda',
    'traveloka': 'Traveloka',
    'expedia': 'Expedia',
    'trip_com': 'Trip.com',
    'reddoorz': 'RedDoorz',
    'airbnb': 'Airbnb',
    'lainnya': 'Lainnya',
  };

  String? _urlValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'URL listing wajib diisi.';
    final uri = Uri.tryParse(value);
    final valid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Masukkan URL valid, contoh: https://booking.com/...';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: platforms.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (context, index) {
            final entry = platforms.entries.elementAt(index);
            final bool selected = urls.containsKey(entry.key);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final next = Map<String, List<String>>.from(urls);
                if (selected) {
                  next.remove(entry.key);
                } else {
                  next[entry.key] = [''];
                }
                onChanged(next);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.textOnBrandBadge
                      : AppTheme.scaffoldColorDynamic(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.border(context),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 17,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        for (final entry in platforms.entries)
          if (urls.containsKey(entry.key))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                key: ValueKey('ota_url_${entry.key}'),
                initialValue: urls[entry.key]!.isNotEmpty
                    ? urls[entry.key]!.first
                    : '',
                decoration: InputDecoration(
                  labelText: 'URL listing ${entry.value} *',
                  hintText: 'https://...',
                  filled: true,
                  fillColor: AppTheme.scaffoldColorDynamic(context),
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                ),
                keyboardType: TextInputType.url,
                validator: _urlValidator,
                onChanged: (v) {
                  final next = Map<String, List<String>>.from(urls);
                  next[entry.key] = [v];
                  onChanged(next);
                },
              ),
            ),
      ],
    );
  }
}