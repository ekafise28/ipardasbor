import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ipardasbor/app/app_theme.dart';

class PhotoPicker extends StatefulWidget {
  const PhotoPicker({super.key, required this.photos, required this.onChanged});

  final List<XFile> photos;
  final ValueChanged<List<XFile>> onChanged;

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    if (widget.photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto dokumentasi.')),
      );
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );

    if (file != null) {
      widget.onChanged([...widget.photos, file]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PhotoButton(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                filled: true,
                onPressed: () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PhotoButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                onPressed: () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary(context)),
            const SizedBox(width: 6),
            Text(
              '${widget.photos.length}/5 foto dipilih · minimal 1 foto',
              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
            ),
          ],
        ),
        if (widget.photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (_, int index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      File(widget.photos[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Material(
                      color: const Color(0xCC172B3A),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          final next = [...widget.photos]..removeAt(index);
                          widget.onChanged(next);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );

    return SizedBox(
      height: 48,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087F8C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF087F8C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: child,
            ),
    );
  }
}
