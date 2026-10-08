import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/menu_data.dart';
import 'count_badge.dart';
import 'menu_icon_box.dart';

class MenuListTile extends StatelessWidget {
  const MenuListTile({
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
    return Material(
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MenuIconBox(menu: menu, size: 46),
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
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        menu.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}