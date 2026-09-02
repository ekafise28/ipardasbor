import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'field_tile.dart';

/// Satu pasang label-nilai yang sudah "siap tampil" (label & value
/// sudah diterjemahkan oleh halaman pemanggil, mis. dari kode wilayah
/// menjadi nama wilayah).
class DetailField {
  const DetailField({required this.label, required this.value});

  final String label;
  final String value;
}

/// Kartu berisi seluruh isian form Non-OSS, ditampilkan berurutan
/// menggunakan [FieldTile]. Logika pengurutan & pelabelan field tetap
/// berada di halaman pemanggil.
class DetailFieldsCard extends StatelessWidget {
  const DetailFieldsCard({super.key, required this.fields});

  final List<DetailField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < fields.length; i++)
            FieldTile(
              label: fields[i].label,
              value: fields[i].value,
              isLast: i == fields.length - 1,
            ),
        ],
      ),
    );
  }
}