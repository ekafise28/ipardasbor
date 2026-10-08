import 'package:flutter/material.dart';

import '../models/menu_data.dart';

/// Kotak ikon menu: gradasi tipis dari warna latar ke warna menu, dengan
/// bayangan lembut berwarna senada. Di mode gelap memakai warna menu
/// transparan, supaya tidak ada kotak pastel terang yang mencolok.
class MenuIconBox extends StatelessWidget {
  const MenuIconBox({super.key, required this.menu, required this.size});

  final MenuData menu;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color start = isDark
        ? menu.color.withValues(alpha: 0.18)
        : menu.backgroundColor;
    final Color end = isDark
        ? menu.color.withValues(alpha: 0.30)
        : Color.lerp(menu.backgroundColor, menu.color, 0.16)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: menu.color.withValues(alpha: isDark ? 0.10 : 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(menu.icon, color: menu.color, size: 24),
    );
  }
}