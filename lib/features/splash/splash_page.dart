import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../../core/storage/secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Separate controller for the exit "zoom + fade" cut, Netflix-intro style.
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  // Logo: scales up + fades in first.
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Title/subtitle: fade in + slide up slightly, staggered after the logo.
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  // Loader: fades in last.
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
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

    // Stop the entrance controller so nothing keeps ticking/repainting
    // (the spinner in particular) while the exit + page transition run.
    // Running two animations at once is the usual cause of a "laggy"
    // spinner right as the page changes.
    _controller.stop();

    // Kick off the exit zoom/fade, but don't wait for it to fully finish —
    // we navigate while it's still ~70% through. That way its tail end
    // overlaps with the system's own page transition instead of running
    // one after the other, which is what was causing the blank pause.
    unawaited(_exitController.forward());
    await Future.delayed(const Duration(milliseconds: 260));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, hasToken ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fallback so there's never a white frame if anything shows through
      // before the gradient paints.
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor, Color(0xFF00A6A6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Only the logo + text zoom/fade on exit. The spinner sits
              // outside this wrapper, so it stays put and keeps spinning
              // right up until the moment the page actually changes.
              FadeTransition(
                opacity: _exitFade,
                child: ScaleTransition(
                  scale: _exitScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
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
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: const Text(
                            'I-PAR MOBILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: SlideTransition(
                          position: _subtitleSlide,
                          child: const Text(
                            'Sistem Pengawasan Pariwisata',
                            style: TextStyle(
                              color: Color(0xFFE3F2FD),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 52),
              // Not wrapped in _exitFade/_exitScale — keeps spinning
              // unaffected by the logo/text exit animation.
              FadeTransition(
                opacity: _loaderFade,
                child: const RepaintBoundary(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}