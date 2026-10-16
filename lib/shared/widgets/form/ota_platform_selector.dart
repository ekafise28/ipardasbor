import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/shared/utils/form_validators.dart';

/// Pemilih platform OTA: daftar checkbox vertikal, dan tiap platform yang
/// dicentang menampilkan satu field URL tepat di bawahnya.
///
/// Data: `Map<String, List<String>>` key platform -> daftar URL. Satu platform
/// satu URL, jadi widget hanya membaca dan menulis URL pertama.
///
/// Input "Nama OTA Lainnya" hanya muncul kalau [onLainnyaChanged] diisi dan
/// platform 'lainnya' dipilih (Tahap 1 dan Non-OSS). Akomodasi (Tahap 2)
/// tidak mengisinya, sama seperti form web.
class OtaPlatformSelector extends StatefulWidget {
  const OtaPlatformSelector({
    super.key,
    required this.urls,
    required this.onChanged,
    this.lainnyaNama,
    this.onLainnyaChanged,
  });

  final Map<String, List<String>> urls;
  final ValueChanged<Map<String, List<String>>> onChanged;

  /// Nilai awal "Nama OTA Lainnya" (dipakai sekali saat widget dibuat).
  final String? lainnyaNama;
  final ValueChanged<String>? onLainnyaChanged;

  @override
  State<OtaPlatformSelector> createState() => _OtaPlatformSelectorState();
}

class _OtaPlatformSelectorState extends State<OtaPlatformSelector> {
  late final TextEditingController _lainnyaCtrl = TextEditingController(
    text: widget.lainnyaNama ?? '',
  );

  @override
  void dispose() {
    _lainnyaCtrl.dispose();
    super.dispose();
  }

  void _toggle(String key, bool pilih) {
    final Map<String, List<String>> next = Map<String, List<String>>.from(
      widget.urls,
    );
    if (pilih) {
      next[key] = <String>[''];
    } else {
      next.remove(key);
    }
    widget.onChanged(next);
  }

  void _setUrl(String key, String value) {
    final Map<String, List<String>> next = Map<String, List<String>>.from(
      widget.urls,
    );
    next[key] = <String>[value];
    widget.onChanged(next);
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppTheme.scaffoldColorDynamic(context),
      prefixIcon: Icon(icon, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: OtaPlatform.labels.entries.map((entry) {
        final bool selected = widget.urls.containsKey(entry.key);
        final List<String> daftarUrl = widget.urls[entry.key] ?? const [];
        final String urlSaatIni = daftarUrl.isNotEmpty ? daftarUrl.first : '';

        return Column(
          key: ValueKey<String>(entry.key),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
              value: selected,
              onChanged: (bool? v) => _toggle(entry.key, v == true),
            ),
            if (selected) ...[
              if (entry.key == OtaPlatform.lainnya &&
                  widget.onLainnyaChanged != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    key: const ValueKey<String>('ota_lainnya_nama'),
                    controller: _lainnyaCtrl,
                    decoration: _decoration(
                      'Nama OTA Lainnya *',
                      'Nama platform',
                      Icons.edit_outlined,
                    ),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty)
                        ? 'Wajib diisi.'
                        : null,
                    onChanged: widget.onLainnyaChanged,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  key: ValueKey<String>('ota_url_${entry.key}'),
                  initialValue: urlSaatIni,
                  decoration: _decoration(
                    'URL listing ${entry.value} *',
                    'https://...',
                    Icons.link_rounded,
                  ),
                  keyboardType: TextInputType.url,
                  validator: (String? v) =>
                      FormValidators.url(v, wajib: true),
                  onChanged: (String v) => _setUrl(entry.key, v),
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}