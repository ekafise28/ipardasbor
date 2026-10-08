import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ipardasbor/features/non_oss/services/wilayah_akses_service.dart';
import 'package:ipardasbor/shared/widgets/connection_error_state.dart';

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

    if (success == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Password berhasil diubah')),
              ],
            ),
          ),
        );
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
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppTheme.danger,
              size: 26,
            ),
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
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppTheme.textSecondary(context),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          actions: [
            Row(
              children: [
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
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await WilayahAksesService.instance.clear();
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil Petugas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _refresh,
        child: FutureBuilder<AuthUser>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileSkeleton();
            }

            if (snapshot.hasError) {
              final String message = snapshot.error is Exception
                  ? snapshot.error.toString()
                  : 'Gagal memuat data profil.';

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: ConnectionErrorState(
                        title: 'Profil gagal dimuat',
                        message: message,
                        onRetry: () => _refresh(),
                      ),
                    ),
                  );
                },
              );
            }

            final AuthUser user = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(user: user),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _FadeSlideIn(
                          child: _InfoSection(
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
                                masked: true,
                              ),
                              _InfoItem(
                                icon: Icons.mail_outline_rounded,
                                label: 'Email',
                                value: user.email,
                                launchUri: _uriOrNull('mailto', user.email),
                              ),
                              _InfoItem(
                                icon: Icons.phone_outlined,
                                label: 'No. HP',
                                value: user.nohp,
                                launchUri: _uriOrNull('tel', user.nohp),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: _InfoSection(
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
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 160),
                          child: _ActionTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Ubah Password',
                            subtitle: 'Perbarui kata sandi akun Anda',
                            onTap: () => _openChangePassword(context, user),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 240),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _logout(context),
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: const Text('Keluar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.danger,
                                side: BorderSide(
                                  color: AppTheme.danger.withValues(alpha: 0.6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const _VersionFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  String get _initials {
    final List<String> parts = user.nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = user.fotoUser != null && user.fotoUser!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 52),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundImage: hasPhoto ? NetworkImage(user.fotoUser!) : null,
              onForegroundImageError: hasPhoto ? (_, __) {} : null,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.nama,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (user.jabatan != null && user.jabatan!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              user.jabatan!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.role != null && user.role!.isNotEmpty)
                _HeaderChip(
                  icon: Icons.verified_user_outlined,
                  text: user.role!.toUpperCase(),
                ),
              if (user.kodeUser != null && user.kodeUser!.isNotEmpty)
                _HeaderChip(icon: Icons.badge_outlined, text: user.kodeUser!),
              if (user.distrik != null && user.distrik!.isNotEmpty)
                _HeaderChip(icon: Icons.map_outlined, text: user.distrik!),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      rows.add(items[i]);
      if (i != items.length - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 31, // sejajar dengan teks (ikon 19 + jarak 12)
            color: AppTheme.border(context).withValues(alpha: 0.6),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoItem extends StatefulWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.masked = false,
    this.launchUri,
  });

  final Uri? launchUri;

  final IconData icon;
  final String label;
  final String? value;

  /// Kalau true, nilai ditampilkan tersamar dan bisa dibuka lewat ikon mata.
  final bool masked;

  @override
  State<_InfoItem> createState() => _InfoItemState();
}

class _InfoItemState extends State<_InfoItem> {
  bool _revealed = false;

  bool get _hasValue => widget.value != null && widget.value!.trim().isNotEmpty;

  String get _displayValue {
    if (!_hasValue) return '-';
    final String v = widget.value!.trim();
    if (!widget.masked || _revealed || v.length <= 8) return v;
    return '${v.substring(0, 4)}${'•' * (v.length - 8)}${v.substring(v.length - 4)}';
  }

  Future<void> _copy() async {
    if (!_hasValue) return;
    await Clipboard.setData(ClipboardData(text: widget.value!.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text('${widget.label} disalin'),
        ),
      );
  }

  Future<void> _launch() async {
    final Uri? uri = widget.launchUri;
    if (uri == null) return;

    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }

    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Tidak dapat membuka ${widget.label}'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _hasValue ? (widget.launchUri != null ? _launch : _copy) : null,
      onLongPress: (_hasValue && widget.launchUri != null) ? _copy : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 19, color: AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayValue,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: widget.masked && !_revealed ? 0.6 : 0,
                    ),
                  ),
                ],
              ),
            ),

            // ===== Blok yang kamu tanyakan: elemen terakhir di Row =====
            if (widget.masked && _hasValue)
              IconButton(
                onPressed: () => setState(() => _revealed = !_revealed),
                tooltip: _revealed ? 'Sembunyikan' : 'Tampilkan',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
              )
            else if (_hasValue && widget.launchUri != null)
              IconButton(
                onPressed: _copy,
                tooltip: 'Salin',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: AppTheme.textMuted,
                ),
              )
            else if (_hasValue)
              Icon(
                Icons.copy_rounded,
                size: 15,
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FadeTransition(
      opacity: _opacity,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 52),
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Bone(width: 160, height: 18, color: Colors.white24),
                  const SizedBox(height: 8),
                  _Bone(width: 110, height: 12, color: Colors.white24),
                  const SizedBox(height: 14),
                  _Bone(width: 200, height: 22, color: Colors.white24),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SkeletonCard(rows: 4),
                    SizedBox(height: 14),
                    _SkeletonCard(rows: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.rows});

  final int rows;

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
          const _Bone(width: 110, height: 14),
          const SizedBox(height: 16),
          for (int i = 0; i < rows; i++) ...[
            const Row(
              children: [
                _Bone(width: 19, height: 19, radius: 6),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 70, height: 10),
                      SizedBox(height: 6),
                      _Bone(width: 150, height: 13),
                    ],
                  ),
                ),
              ],
            ),
            if (i != rows - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    this.radius = 6,
    this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

Uri? _uriOrNull(String scheme, String? value) {
  final String? v = value?.trim();
  if (v == null || v.isEmpty) return null;
  return Uri(scheme: scheme, path: v);
}

class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 28);
        final PackageInfo info = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Versi ${info.version} (${info.buildNumber})',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
          ),
        );
      },
    );
  }
}
