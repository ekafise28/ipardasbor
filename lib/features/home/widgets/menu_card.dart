import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/menu_data.dart';
import 'count_badge.dart';
import 'menu_icon_box.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.menu,
    required this.onTap,
    this.badgeCount = 0,
  });

  final MenuData menu;
  final VoidCallback onTap;

  /// Jumlah yang ditampilkan di pojok ikon. 0 = tidak ada badge.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: menu.description,
      triggerMode: TooltipTriggerMode.longPress,
      showDuration: const Duration(seconds: 3),
      preferBelow: true,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.textColor(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: menu.color.withValues(alpha: 0.10),
          highlightColor: menu.color.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textColor(context).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MenuIconBox(menu: menu, size: 44),
                      if (badgeCount > 0)
                        Positioned(
                          top: -5,
                          right: -7,
                          child: IgnorePointer(
                            child: CountBadge(count: badgeCount),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    menu.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}