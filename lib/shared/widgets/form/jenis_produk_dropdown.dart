import 'package:flutter/material.dart';

/// "55105 - Hotel Bintang 1". Kode KBLI selalu 5 digit. Nilai lama berupa
/// teks (mis. "Hotel") dan label API yang sudah berformat "kode - nama"
/// tampil apa adanya.
String labelJenisProduk(String key, String value) {
  if (!RegExp(r'^\d{5}$').hasMatch(key)) return value;
  return value.startsWith(key) ? value : '$key - $value';
}

/// Dropdown Jenis Produk yang dipakai form Non-OSS dan OSS.
class JenisProdukDropdown extends StatelessWidget {
  const JenisProdukDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label = 'Jenis Produk *',
  });

  final String label;
  final List<MapEntry<String, String>> options;

  /// Kode jenis produk terpilih; '' berarti belum dipilih.
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> opsi =
        List<MapEntry<String, String>>.of(options);

    // Nilai tersimpan (draft/edit) yang tidak ada di daftar tetap
    // ditampilkan, supaya dropdown tidak error dan nilainya tidak hilang.
    if (value.isNotEmpty && !opsi.any((e) => e.key == value)) {
      opsi.add(MapEntry(value, value));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        // Key ikut jumlah opsi supaya dropdown dibangun ulang saat daftar
        // dari API selesai dimuat (initialValue hanya dibaca sekali).
        key: ValueKey<String>('jp-${opsi.length}'),
        initialValue: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
  labelText: label,
  prefixIcon: const Icon(Icons.category_outlined, size: 20),
),
        items: opsi
            .map(
              (e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text(
                  labelJenisProduk(e.key, e.value),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v ?? ''),
        validator: (v) => v == null ? 'Wajib dipilih.' : null,
      ),
    );
  }
}