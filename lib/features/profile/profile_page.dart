import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../authentication/models/auth_user.dart';

import '../authentication/services/auth_service.dart';
import 'services/profile_services.dart';

import 'pages/password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  late Future<AuthUser> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getProfile();
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
  final Future<AuthUser> future = _profileService.getProfile();
  setState(() {
    _profileFuture = future;
  });
  try {
    await future;
  } catch (_) {
    // Sengaja tidak dilempar ulang. FutureBuilder tetap mendengarkan
    // `future` yang sama, jadi dia akan mendeteksi snapshot.hasError
    // dan menampilkan halaman "Tidak dapat terhubung ke server..."
    // seperti biasa. Kalau error ini dilempar ulang ke RefreshIndicator,
    // exception-nya jadi unhandled dan UI terasa "not responding".
  }
}

  Future<void> _openChangePassword(BuildContext context, AuthUser user) async {
  final bool? success = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => ChangePasswordPage(user: user)),
  );

  // Opsional: kalau berhasil ganti password, tidak wajib refresh profil
  // karena data profil (nama, dll) tidak berubah. Tapi kalau suatu saat
  // mau tampilkan notifikasi tambahan di ProfilePage, bisa manfaatkan
  // nilai `success` di sini.
  if (success == true && context.mounted) {
    // contoh: ScaffoldMessenger.of(context).showSnackBar(...);
  }
}

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(context),
          surfaceTintColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Keluar dari akun?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          content: Text(
            'Anda perlu masuk kembali untuk mengakses aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary(context)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textColor(context),
                  side: BorderSide(color: AppTheme.border(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Keluar'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Petugas',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _refresh,
          child: FutureBuilder<AuthUser>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final String message = snapshot.error is Exception
                    ? snapshot.error.toString()
                    : 'Gagal memuat data profil.';

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 60),
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 46,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                );
              }

              final AuthUser user = snapshot.data!;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'Informasi Akun',
                    items: [
                      _InfoItem(
                        icon: Icons.badge_outlined,
                        label: 'Kode Petugas',
                        value: user.kodeUser,
                      ),
                      _InfoItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'NIK',
                        value: user.nik,
                      ),
                      _InfoItem(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: user.email,
                      ),
                      _InfoItem(
                        icon: Icons.phone_outlined,
                        label: 'No. HP',
                        value: user.nohp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoSection(
                    title: 'Informasi Tugas',
                    items: [
                      _InfoItem(
                        icon: Icons.work_outline_rounded,
                        label: 'Jabatan',
                        value: user.jabatan,
                      ),
                      _InfoItem(
                        icon: Icons.apartment_rounded,
                        label: 'Unit Kerja',
                        value: user.unitkerja,
                      ),
                      _InfoItem(
                        icon: Icons.map_outlined,
                        label: 'Distrik',
                        value: user.distrik,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Tambahan: tombol ubah password
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openChangePassword(context, user),
                      icon: const Icon(Icons.lock_outline_rounded, size: 19),
                      label: const Text('Ubah Password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage:
                (user.fotoUser != null && user.fotoUser!.isNotEmpty)
                ? NetworkImage(user.fotoUser!)
                : null,
            child: (user.fotoUser == null || user.fotoUser!.isEmpty)
                ? const Icon(
                    Icons.person_rounded,
                    size: 34,
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
                  user.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.jabatan != null && user.jabatan!.isNotEmpty)
                  Text(
                    user.jabatan!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                    ),
                  ),
                if (user.role != null && user.role!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) item,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String displayValue = (value == null || value!.trim().isEmpty)
        ? '-'
        : value!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}