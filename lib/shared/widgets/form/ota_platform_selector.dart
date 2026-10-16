import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/shared/utils/form_validators.dart';

/// Pemilih platform OTA: grid chip + satu field URL per platform terpilih.
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

  void _toggle(String key, bool selected) {
    final Map<String, List<String>> next = Map<String, List<String>>.from(
      widget.urls,
    );
    if (selected) {
      next.remove(key);
    } else {
      next[key] = <String>[''];
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
    final List<MapEntry<String, String>> platforms =
        OtaPlatform.labels.entries.toList(growable: false);

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
            final MapEntry<String, String> entry = platforms[index];
            final bool selected = widget.urls.containsKey(entry.key);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _toggle(entry.key, selected),
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
        for (final MapEntry<String, String> entry in platforms)
          if (widget.urls.containsKey(entry.key)) ...[
            if (entry.key == OtaPlatform.lainnya &&
                widget.onLainnyaChanged != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  key: const ValueKey<String>('ota_lainnya_nama'),
                  controller: _lainnyaCtrl,
                  decoration: _decoration(
                    'Nama OTA Lainnya *',
                    'Nama platform',
                    Icons.edit_outlined,
                  ),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                  onChanged: widget.onLainnyaChanged,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                key: ValueKey<String>('ota_url_${entry.key}'),
                initialValue: (widget.urls[entry.key] ?? const <String>[])
                        .isNotEmpty
                    ? widget.urls[entry.key]!.first
                    : '',
                decoration: _decoration(
                  'URL listing ${entry.value} *',
                  'https://...',
                  Icons.link_rounded,
                ),
                keyboardType: TextInputType.url,
                validator: (String? v) => FormValidators.url(v, wajib: true),
                onChanged: (String v) => _setUrl(entry.key, v),
              ),
            ),
          ],
      ],
    );
  }
}