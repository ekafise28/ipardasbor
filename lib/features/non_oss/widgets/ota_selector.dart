import 'package:flutter/material.dart';

class OtaSelector extends StatelessWidget {
  const OtaSelector({super.key, required this.urls, required this.onChanged});
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
  @override
  Widget build(BuildContext context) => Column(
    children: platforms.entries.map((e) {
      final selected = urls.containsKey(e.key);
      return Column(
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
            TextFormField(
              initialValue: urls[e.key]!.first,
              decoration: InputDecoration(labelText: 'URL listing ${e.value}'),
              keyboardType: TextInputType.url,
              onChanged: (v) {
                final next = Map<String, List<String>>.from(urls);
                next[e.key] = [v];
                onChanged(next);
              },
            ),
        ],
      );
    }).toList(),
  );
}
