import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Satu platform OTA beserta daftar URL yang terdaftar untuknya.
class OtaEntry {
  const OtaEntry({required this.name, required this.urls});

  final String name;
  final List<String> urls;
}

/// Menampilkan satu [OtaEntry]: nama platform dan daftar URL yang bisa
/// ditekan (dibuka lewat [onTapUrl]).
class OtaTile extends StatelessWidget {
  const OtaTile({super.key, required this.entry, required this.onTapUrl});

  final OtaEntry entry;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              entry.name,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (entry.urls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.urls.map((String url) {
                return Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '→ ',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12.5,
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => onTapUrl(url),
                          child: Text(
                            url,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}