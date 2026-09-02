import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Strip thumbnail foto dokumentasi yang bisa ditekan untuk membuka
/// [PhotoViewerPage]. Navigasi ke viewer tetap jadi tanggung jawab
/// halaman pemanggil lewat [onOpenPhoto].
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
            'Foto Dokumentasi (${photoPaths.length})',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final String path = photoPaths[index];
                final File file = File(path);
                final bool exists = file.existsSync();

                return GestureDetector(
                  onTap: exists ? () => onOpenPhoto(index) : null,
                  child: Hero(
                    tag: 'submission_photo_$path',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: exists
                          ? Image.file(
                              file,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 88,
                              height: 88,
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
          ),
        ],
      ),
    );
  }
}