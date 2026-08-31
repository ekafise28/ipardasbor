import 'package:flutter/material.dart';

import '../features/authentication/login_page.dart';
import '../features/home/home_page.dart';
import '../features/splash/splash_page.dart';
import 'app_navigator.dart';
import 'app_theme.dart';

class IparApp extends StatelessWidget {
  const IparApp({super.key});

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