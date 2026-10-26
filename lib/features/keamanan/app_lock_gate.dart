import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'services/biometric_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  static const Duration _grace = Duration(seconds: 30);

  final BiometricService _bio = BiometricService.instance;

  bool _locked = false;
  bool _authenticating = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockIfEnabled(); // buka dingin
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final DateTime? t = _pausedAt;
      _pausedAt = null;
      if (_authenticating || t == null) return;
      if (DateTime.now().difference(t) >= _grace) _lockIfEnabled();
    }
  }

  Future<void> _lockIfEnabled() async {
    if (!await _bio.isEnabled()) return;
    if (!mounted) return;
    setState(() => _locked = true);
    await _unlock();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final bool ok = await _bio.authenticate('Verifikasi untuk membuka I-PAR');
    _authenticating = false;
    if (!mounted) return;
    if (ok) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Material(
              color: AppTheme.scaffoldColorDynamic(context),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 56,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aplikasi terkunci',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.face_unlock_rounded),
                      label: const Text('Buka kunci'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
