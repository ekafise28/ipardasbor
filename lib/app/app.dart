import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../features/authentication/login_page.dart';
import '../features/home/home_page.dart';
import '../features/non_oss/offline/sync_service.dart';
import '../features/non_oss/services/non_oss_service.dart';
import '../features/splash/splash_page.dart';
import '../features/non_oss/offline/auto_sync_controller.dart';

import 'app_navigator.dart';
import 'app_theme.dart';

class IparApp extends StatefulWidget {
  const IparApp({super.key});

  @override
  State<IparApp> createState() => _IparAppState();
}

class _IparAppState extends State<IparApp> with WidgetsBindingObserver {
  late final NonOssSyncService _nonOssSync;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _nonOssSync = NonOssSyncService(remote: NonOssService(ApiClient()));

    // Sinkronisasi otomatis (saat app dibuka & saat koneksi berubah) HANYA
    // berjalan kalau user mengaktifkannya lewat toggle di halaman Settings
    // (AutoSyncController). Default-nya manual.
    if (AutoSyncController.instance.isEnabled) {
      _runSyncSilently();
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!AutoSyncController.instance.isEnabled) {
        return;
      }

      final bool hasConnection = results.any(
        (ConnectivityResult r) => r != ConnectivityResult.none,
      );

      if (hasConnection) {
        _runSyncSilently();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        AutoSyncController.instance.isEnabled) {
      _runSyncSilently();
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
