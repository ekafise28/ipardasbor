import 'package:flutter/material.dart';

class OtaSelector extends StatelessWidget {
  const OtaSelector({
    super.key,
    required this.urls,
    required this.onChanged,
  });

  final Map<String, List<String>> urls;
  final ValueChanged<Map<String, List<String>>> onChanged;

  static const platforms = {
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

  /// [Poin 1] Validasi format URL OTA
  /// Memastikan input bernilai valid dengan skema http/https dan memiliki host domain.
  String? _otaUrlValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'URL listing wajib diisi.';

    final uri = Uri.tryParse(value);
    final isValid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValid) {
      return 'Masukkan URL valid, contoh: https://booking.com/hotel-abc';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
        children: platforms.entries.map((e) {
          final selected = urls.containsKey(e.key);
          final currentUrl = selected && urls[e.key]!.isNotEmpty ? urls[e.key]!.first : '';

          return Column(
            key: ValueKey(e.key),
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                value: selected,
                onChanged: (v) {
                  final next = Map<String, List<String>>.from(urls);
                  if (v == true) {
                    next[e.key] = [''];
                  } else {
                    next.remove(e.key);
                  }
                  onChanged(next);
                },
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    // Gunakan controller/key atau initialValue
                    initialValue: currentUrl,
                    decoration: InputDecoration(
                      labelText: 'URL listing ${e.value} *',
                      hintText: 'https://...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    ),
                    keyboardType: TextInputType.url,
                    // [Poin 1] Tambahkan validator pada URL OTA
                    validator: _otaUrlValidator,
                    onChanged: (v) {
                      final next = Map<String, List<String>>.from(urls);
                      next[e.key] = [v];
                      onChanged(next);
                    },
                  ),
                ),
            ],
          );
        }).toList(),
      );
}