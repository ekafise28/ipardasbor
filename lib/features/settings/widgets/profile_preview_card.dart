import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../authentication/models/auth_user.dart';

// Widget untuk menampilkan preview profil pengguna di halaman pengaturan.
class ProfilePreviewCard extends StatelessWidget {
  const ProfilePreviewCard({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onTap,
  });

  final AuthUser? user;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String nama =
        user?.nama ?? (isLoading ? 'Memuat...' : 'Petugas Pengawasan');
    final String? jabatan = user?.jabatan;
    final String? foto = user?.fotoUser;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: (foto != null && foto.isNotEmpty)
                    ? NetworkImage(foto)
                    : null,
                child: (foto == null || foto.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (jabatan != null && jabatan.isNotEmpty)
                          ? jabatan
                          : 'Lihat profil selengkapnya',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textOnBrandMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}