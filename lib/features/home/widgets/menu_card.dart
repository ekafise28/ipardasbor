import 'package:flutter/material.dart';

import '../models/menu_data.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.menu, required this.onTap});

  final MenuData menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: menu.color.withValues(alpha: 0.10),
        highlightColor: menu.color.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EAF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF253858).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 8),
            child: Column(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: menu.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(menu.icon, color: menu.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  menu.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1B2940),
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    menu.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8A94A6),
                      fontSize: 8,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
