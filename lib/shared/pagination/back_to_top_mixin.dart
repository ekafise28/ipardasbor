import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Perilaku gulir untuk halaman daftar: tombol "kembali ke atas" yang
/// muncul setelah digulir cukup jauh, dan pemicu muat berikutnya saat
/// mendekati ujung bawah.
///
/// Pemakaian: panggil [initBackToTop] di initState dan [disposeBackToTop]
/// di dispose, pasang [scroll] ke ListView (`controller: scroll`), isi
/// [onNearBottom], lalu pakai [buildBackToTopFab] sebagai
/// floatingActionButton.
mixin BackToTopMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scroll = ScrollController();

  bool _showBackToTop = false;

  static const double _jarakTampil = 400;
  static const double _jarakDekatBawah = 200;

  /// Dipanggil berulang saat gulir sudah dekat ujung bawah. Halaman
  /// bertanggung jawab mengabaikan panggilan yang tidak perlu (sedang
  /// memuat, sudah habis, dan sebagainya).
  void onNearBottom();

  void initBackToTop() => scroll.addListener(_onScrollInternal);

  void disposeBackToTop() => scroll.dispose();

  /// Menyembunyikan tombol tanpa setState; panggil di dalam setState
  /// halaman (mis. saat daftar diganti skeleton dan posisi kembali ke 0).
  void hideBackToTop() => _showBackToTop = false;

  void jumpKeAtas() {
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void scrollKeAtas() {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  /// Tombol "kembali ke atas", atau null kalau belum perlu tampil.
  /// [enabled] false menyembunyikannya walau sudah digulir jauh (mis. saat
  /// daftar kosong atau error).
  FloatingActionButton? buildBackToTopFab({bool enabled = true}) {
    if (!_showBackToTop || !enabled) return null;
    return FloatingActionButton.small(
      onPressed: scrollKeAtas,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      tooltip: 'Kembali ke atas',
      child: const Icon(Icons.keyboard_arrow_up_rounded),
    );
  }

  void _onScrollInternal() {
    if (!scroll.hasClients) return;
    final ScrollPosition pos = scroll.position;

    final bool perluTampil = pos.pixels > _jarakTampil;
    if (perluTampil != _showBackToTop) {
      setState(() => _showBackToTop = perluTampil);
    }

    if (pos.pixels >= pos.maxScrollExtent - _jarakDekatBawah) {
      onNearBottom();
    }
  }
}