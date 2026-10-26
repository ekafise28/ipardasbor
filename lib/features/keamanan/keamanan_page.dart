import 'package:flutter/material.dart';
import 'package:ipardasbor/features/authentication/login_page.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/list_parts.dart';
import 'services/biometric_service.dart';
import 'services/face_login_store.dart';

class KeamananPage extends StatefulWidget {
  const KeamananPage({super.key});

  @override
  State<KeamananPage> createState() => _KeamananPageState();
}

class _KeamananPageState extends State<KeamananPage> {
  final BiometricService _bio = BiometricService.instance;

  bool _loading = true;
  bool _faceEnabled = false;
  bool _hasFace = false;
  bool _hasAnyBiometric = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Set<BiometricType> types = await _bio.types();
    final bool enabled = await _bio.isEnabled();
    debugPrint('Biometrik terdeteksi: $types'); // buat cek di terminal
    if (!mounted) return;
    setState(() {
      // Face Unlock Samsung (2D) sering dilaporkan sebagai `weak`.
      // Sidik jari lo tidak terdaftar, jadi weak/strong di sini
      // kemungkinan besar wajah.
      _hasFace =
          types.contains(BiometricType.face) ||
          types.contains(BiometricType.weak);
      _hasAnyBiometric = types.isNotEmpty;
      _faceEnabled = enabled && _hasFace;
      _loading = false;
    });
  }

  Future<void> _toggleFace(bool value) async {
    if (value) {
      final bool ok = await _bio.authenticate(
        'Verifikasi wajah untuk mengaktifkan Face Unlock',
        biometricOnly: true,
      );
      if (!ok || !mounted) return;
    }
    await _bio.setEnabled(value);
    if (!value) await FaceLoginStore.instance.clear();
    if (!mounted) return;
    setState(() => _faceEnabled = value);
  }

  String get _faceInfo {
    if (_hasFace) return 'Buka aplikasi dengan wajah.';
    if (_hasAnyBiometric) {
      return 'Wajah tidak tersedia untuk aplikasi di HP ini.';
    }
    return 'Belum ada wajah terdaftar, atau HP membatasi Face Unlock '
        'untuk aplikasi lain. Cek Pengaturan HP > Biometrik.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Keamanan',
          subtitle: 'Pilih cara membuka aplikasi',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OpsiKeamanan(
                  icon: Icons.face_unlock_rounded,
                  title: 'Face Unlock',
                  subtitle: _faceInfo,
                  value: _faceEnabled,
                  onChanged: _hasFace ? _toggleFace : null,
                ),
                const SizedBox(height: 10),
                const _OpsiKeamanan(
                  icon: Icons.fingerprint_rounded,
                  title: 'Sidik Jari',
                  subtitle: 'Segera hadir.',
                  value: false,
                  onChanged: null,
                  badge: 'SEGERA',
                ),
              ],
            ),
    );
  }
}

class _OpsiKeamanan extends StatelessWidget {
  const _OpsiKeamanan({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final bool aktif = onChanged != null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
        secondary: Icon(
          icon,
          size: 28,
          color: aktif ? AppTheme.primaryColor : AppTheme.textMuted,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: aktif
                      ? AppTheme.textColor(context)
                      : AppTheme.textSecondary(context),
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
