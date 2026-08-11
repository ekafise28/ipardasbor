import 'package:flutter/material.dart';

class MenuData {
  const MenuData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}
