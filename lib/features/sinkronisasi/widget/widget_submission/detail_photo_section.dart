import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Grid thumbnail foto dokumentasi yang bisa ditekan untuk membuka
/// [PhotoViewerPage]. Navigasi ke viewer tetap jadi tanggung jawab
/// halaman pemanggil lewat [onOpenPhoto].
///
/// Tampilan grid 3 kolom ini disamakan dengan section foto pada halaman
/// detail Riwayat, supaya kedua halaman detail terasa konsisten.
class DetailPhotoSection extends StatelessWidget {
  const DetailPhotoSection({
    super.key,
    required this.photoPaths,
    required this.onOpenPhoto,
  });

  final List<String> photoPaths;
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: AppTheme.menuDashboard,
                ),
                const SizedBox(width: 8),
                Text(
                  'Foto Dokumentasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${photoPaths.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photoPaths.length,
              itemBuilder: (BuildContext context, int index) {
                final String path = photoPaths[index];
                final File file = File(path);
                final bool exists = file.existsSync();

                return GestureDetector(
                  onTap: exists ? () => onOpenPhoto(index) : null,
                  child: Hero(
                    tag: 'submission_photo_$path',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: exists
                          ? Image.file(file, fit: BoxFit.cover)
                          : Container(
                              color: AppTheme.surfaceMuted(context),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.textMuted,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
