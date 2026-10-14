import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart';

/// Tag Hero bersama antara thumbnail dan viewer. Satu sumber supaya
/// keduanya tidak bisa berbeda.
String _heroTag(String path) => 'submission_photo_$path';

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
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
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
                  tag: _heroTag(path),
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
    );
  }
}

/// Halaman full-screen untuk melihat foto dokumentasi satu per satu,
/// dengan swipe antar foto dan pinch-to-zoom.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({
    super.key,
    required this.photoPaths,
    required this.initialIndex,
  });

  final List<String> photoPaths;
  final int initialIndex;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photoPaths.length,
            onPageChanged: (int index) => setState(() => _currentIndex = index),
            itemBuilder: (BuildContext context, int index) {
              final String path = widget.photoPaths[index];
              return Center(
                child: Hero(
                  tag: _heroTag(path),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            left: 4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.photoPaths.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photoPaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}