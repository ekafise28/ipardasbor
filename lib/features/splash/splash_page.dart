import 'package:flutter/material.dart';

import '../../core/storage/secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final Future<bool> sessionFuture = SecureStorage.hasAccessToken();
    final Future<void> delayFuture = Future<void>.delayed(
      const Duration(seconds: 2),
    );

    final List<dynamic> results = await Future.wait([
      sessionFuture,
      delayFuture,
    ]);

    if (!mounted) return;

    final bool hasToken = results.first as bool;

    Navigator.pushReplacementNamed(context, hasToken ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF00A6A6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 60,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'I-PAR MOBILE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem Pengawasan Pariwisata',
                style: TextStyle(color: Color(0xFFE3F2FD), fontSize: 15),
              ),
              const SizedBox(height: 52),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
