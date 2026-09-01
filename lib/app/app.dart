import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../features/authentication/login_page.dart';
import '../features/home/home_page.dart';
import '../features/non_oss/offline/sync_service.dart';
import '../features/non_oss/services/non_oss_service.dart';
import '../features/splash/splash_page.dart';
import 'app_navigator.dart';
import 'app_theme.dart';

class IparApp extends StatefulWidget {
  const IparApp({super.key});

  @override
  State<IparApp> createState() => _IparAppState();
}

class _IparAppState extends State<IparApp> {
  late final NonOssSyncService _nonOssSync;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _nonOssSync = NonOssSyncService(remote: NonOssService(ApiClient()));

    // Opsi 1: coba sinkron sekali saat aplikasi baru dibuka.
    _runSyncSilently();

    // Opsi 2: coba sinkron setiap kali status jaringan berubah ke kondisi
    // tersambung. isServerAvailable() di dalam syncWaiting() akan
    // memverifikasi lebih lanjut apakah server benar-benar bisa dijangkau,
    // jadi di sini cukup deteksi perubahan status jaringan perangkat saja.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final bool hasConnection = results.any(
        (ConnectivityResult r) => r != ConnectivityResult.none,
      );

      if (hasConnection) {
        _runSyncSilently();
      }
    });
  }

  void _runSyncSilently() {
    // syncWaiting() sudah menangani error internalnya sendiri (lihat
    // NonOssSyncService.syncOne), tapi tetap dibungkus try-catch di sini
    // sebagai jaring pengaman terakhir supaya kegagalan tak terduga tidak
    // pernah menyebabkan crash di level aplikasi.
    unawaited(
      _nonOssSync.syncWaiting().catchError((Object _) {
        // Sengaja diabaikan — proses ini berjalan di latar belakang tanpa
        // UI, jadi tidak ada tempat yang tepat untuk menampilkan error.
      }),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          title: 'I-PAR Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashPage(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}